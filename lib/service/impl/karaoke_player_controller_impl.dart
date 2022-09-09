import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_karaoke_player/cdg/lib/cdg_player.dart';
import 'package:flutter_karaoke_player/config/constants.dart';
import 'package:flutter_karaoke_player/service/karaoke_player_controller.dart';
import 'package:flutter_karaoke_player/service/queue_service.dart';
import 'package:karaoke_request_api/karaoke_request_api.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class KaraokePlayerControllerImpl extends KaraokePlayerController {
  KaraokePlayerControllerImpl(this._queueService) {
    vlcPlayer.positionStream.listen((event) async {
      final data = jsonEncode({
        'position': currentSongId == 0 ? 0 : event.position?.inSeconds ?? 0,
        'songId': currentSongId,
        'currentSinger': currentSinger,
      });
      if (kDebugMode) {
        print('Sending position: $data');
      }
      webSocketChannel?.sink.add(data);
    });
    vlcPlayer.playbackStream.listen((event) async {
      if (event.isCompleted && isSearching == false) {
        currentSinger = null;
        currentSongId = 0;

        isSearching = true;
        await skip();
        isSearching = false;
      }
    });
    playerTypeStream.stream.listen((type) => currentPlayerType = type);
    Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (_isLoaded && currentPlayerType == PlayerType.cdg && isPlaying) {
        try {
          final render = _cdgPlayer.render(_cdgPlayer.currentMillis);
          if (render.isChanged) {
            renderStream.sink.add(render);
          }
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
        } finally {
          _cdgPlayer.currentMillis += 33;
        }
      }
    });
    Timer.periodic(const Duration(seconds: 2), (_) async {
      if (webSocketChannel == null) {
        try {
          final webSocket = webSocketChannel = WebSocketChannel.connect(Uri.parse('ws://$apiUrl:$apiPort'));
          webSocket.stream.listen((data) {
            if (kDebugMode) print('Received: $data');
            if (data is String) {
              switch (data) {
                case 'play':
                  return play();
                case 'pause':
                  return pause();
                case 'stop':
                  return stop();
                case 'restart':
                  return restart();
                case 'skip':
                  skip();
                  return;
                case 'volumeDown':
                  return volumeDown();
                case 'volumeUp':
                  return volumeUp();
                default:
                  try {
                    loadSong(SongModel.fromMap(json.decode(data)));
                  } catch (_) {
                    // ignore
                  }
              }
            }
          });
          if (kDebugMode) {
            print('Connected to WebSocket');
          }
        } on Exception {
          webSocketChannel?.sink.close();
          webSocketChannel = null;
        }
      }
    });
  }

  @override
  final Player vlcPlayer = Player(id: 14325);
  final _cdgPlayer = CDGPlayer();
  final _zipDecoder = ZipDecoder();
  final QueueService _queueService;

  PlayerType currentPlayerType = PlayerType.none;
  WebSocketChannel? webSocketChannel;

  String? currentSinger;
  int currentSongId = 0;
  bool isSearching = false;

  bool get _isLoaded => _cdgPlayer.parser != null;

  Future<void> _loadZip(String zipPath) async {
    final file = File(zipPath);
    final bytes = file.readAsBytesSync();
    final archive = _zipDecoder.decodeBytes(bytes);
    for (final file in archive.files) {
      final content = file.content as Uint8List;
      if (file.name.contains('.cdg')) {
        _cdgPlayer.load(content.buffer);
      }
      if (file.name.contains('.mp3')) {
        final tempFile = File('temp');
        await tempFile.writeAsBytes(content);
        vlcPlayer.open(Media.file(tempFile));
      }
    }
  }

  Future<void> _loadMp3(String mp3Path) async {
    final basePath = mp3Path.split('.').first;
    final cdgPath = '$basePath.cdg';
    final mp3 = File(mp3Path);
    final cdg = File(cdgPath);
    cdg.exists().then((value) => cdg.readAsBytes().then((value) => _cdgPlayer.load(value.buffer)));
    mp3.exists().then((value) => vlcPlayer.open(Media.file(mp3)));
  }

  Future<void> _loadVideo(String path) async {
    final file = File(path);
    final source = Media.file(file);
    vlcPlayer.open(source, autoStart: false);
  }

  @override
  void play() {
    switch (currentPlayerType) {
      case PlayerType.vlc:
        if (!_isLoaded) return;
        vlcPlayer.play();
        return playerTypeStream.sink.add(PlayerType.vlc);
      case PlayerType.cdg:
        vlcPlayer.play();
        return playerTypeStream.sink.add(PlayerType.cdg);
      case PlayerType.none:
        break;
    }
  }

  @override
  Future<void> close() async {
    vlcPlayer.dispose();
    await renderStream.close();
  }

  @override
  void stop() {
    playerTypeStream.sink.add(PlayerType.none);
    switch (currentPlayerType) {
      case PlayerType.cdg:
        _cdgPlayer.currentMillis = 0;
        return vlcPlayer.stop();
      case PlayerType.vlc:
        return vlcPlayer.stop();
      case PlayerType.none:
        return;
    }
  }

  @override
  void pause() {
    switch (currentPlayerType) {
      case PlayerType.cdg:
      case PlayerType.vlc:
        return vlcPlayer.pause();
      case PlayerType.none:
        return;
    }
  }

  @override
  void restart() {
    switch (currentPlayerType) {
      case PlayerType.cdg:
      case PlayerType.vlc:
        _cdgPlayer.currentMillis = 0;
        vlcPlayer.seek(const Duration(milliseconds: 0));
        return play();
      case PlayerType.none:
        break;
    }
  }

  @override
  Future<void> skip() async {
    await _queueService.getNextItem().then((value) async {
      if (value != null) {
        currentSinger = value.singer.name;
        currentSongId = value.song.songId ?? 0;
        await loadSong(value.song);
        play();
        notificationStream.sink.add('Now playing: ${value.song.artist} - ${value.song.title}\n by ${value.singer.name}');
      } else {
        stop();
      }
    });
  }

  @override
  Future<void> loadSong(SongModel song) async {
    final path = song.path ?? '';
    switch (path.split('.').last) {
      case 'zip':
        vlcPlayer.stop();
        playerTypeStream.sink.add(PlayerType.cdg);
        return await _loadZip(path);
      case 'mp3':
        vlcPlayer.stop();
        playerTypeStream.sink.add(PlayerType.vlc);
        return await _loadMp3(path);
      default:
        vlcPlayer.stop();
        playerTypeStream.sink.add(PlayerType.vlc);
        return await _loadVideo(path);
    }
  }

  @override
  bool get isPlaying {
    switch (currentPlayerType) {
      case PlayerType.vlc:
      case PlayerType.cdg:
        return vlcPlayer.playback.isPlaying;
      case PlayerType.none:
        return false;
    }
  }

  @override
  void volumeDown() {
    switch (currentPlayerType) {
      case PlayerType.cdg:
      case PlayerType.vlc:
      case PlayerType.none:
        vlcPlayer.setVolume(max(vlcPlayer.general.volume - 0.05, 0.0));
        return notificationStream.sink.add('Volume: ${(vlcPlayer.general.volume * 100).round()}');
    }
  }

  @override
  void volumeUp() {
    switch (currentPlayerType) {
      case PlayerType.cdg:
      case PlayerType.vlc:
      case PlayerType.none:
        vlcPlayer.setVolume(min(vlcPlayer.general.volume + 0.05, 1.0));
        return notificationStream.sink.add('Volume: ${(vlcPlayer.general.volume * 100).round()}');
    }
  }
}
