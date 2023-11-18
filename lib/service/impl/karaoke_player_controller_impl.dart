import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_karaoke_player/cdg/lib/cdg_player.dart';
import 'package:flutter_karaoke_player/config/constants.dart';
import 'package:flutter_karaoke_player/service/karaoke_player_controller.dart';
import 'package:flutter_karaoke_player/service/queue_service.dart';
import 'package:karaoke_request_api/karaoke_request_api.dart';
import 'package:media_kit/media_kit.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class KaraokePlayerControllerImpl extends KaraokePlayerController {
  KaraokePlayerControllerImpl(this._queueService) {
    mediaPlayer.stream.position.listen((position) async {
      final data = jsonEncode({
        'position': currentSongId == 0 ? 0 : position.inSeconds,
        'songId': currentSongId,
        'singer': currentSinger,
      });
      webSocketChannel?.sink.add(data);
    });
    mediaPlayer.stream.completed.listen((isCompleted) async {
      if (isCompleted && isSearching == false) {
        currentSinger = null;
        currentSongId = 0;

        isSearching = true;
        await skip();
        isSearching = false;
      }
    });
    playerTypeStream.stream.listen((type) => currentPlayerType = type);
    Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (currentPlayerType == PlayerType.cdg && isPlaying) {
        try {
          final render = _cdgPlayer.render(_cdgPlayer.currentMillis);
          if (render.isChanged) {
            renderStream.sink.add(render);
          }
        } catch (e) {
          // ignore
        } finally {
          _cdgPlayer.currentMillis += 33;
        }
      }
    });
    Timer.periodic(const Duration(seconds: 2), (_) async {
      if (webSocketChannel == null) {
        try {
          final webSocket = webSocketChannel = WebSocketChannel.connect(Uri.parse('ws://$apiUrl:$apiPort'));
          webSocket.stream.listen((data) async {
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
                    loadSong(SongModel.fromJson(json.decode(data)));
                  } catch (_) {
                    // ignore
                  }
              }
            }
          });
        } on Exception {
          webSocketChannel?.sink.close();
          webSocketChannel = null;
        }
      }
    });
  }

  @override
  final Player mediaPlayer = Player();
  final _cdgPlayer = CDGPlayer();
  final _zipDecoder = ZipDecoder();
  final QueueService _queueService;

  PlayerType currentPlayerType = PlayerType.none;
  WebSocketChannel? webSocketChannel;

  String? currentSinger;
  int currentSongId = 0;
  bool isSearching = false;

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
        mediaPlayer.open(Media(tempFile.path));
      }
    }
  }

  Future<void> _loadMp3(String mp3Path) async {
    final basePath = mp3Path.split('.').first;
    final cdgPath = '$basePath.cdg';
    final mp3 = File(mp3Path);
    final cdg = File(cdgPath);
    cdg.exists().then((value) => cdg.readAsBytes().then((value) => _cdgPlayer.load(value.buffer)));
    mp3.exists().then((value) => mediaPlayer.open(Media(mp3Path)));
  }

  Future<void> _loadVideo(String path) async {
    mediaPlayer.open(Media(path), play: false);
  }

  @override
  void play() {
    switch (currentPlayerType) {
      case PlayerType.vlc:
        mediaPlayer.play();
        return playerTypeStream.sink.add(PlayerType.vlc);
      case PlayerType.cdg:
        mediaPlayer.play();
        return playerTypeStream.sink.add(PlayerType.cdg);
      case PlayerType.none:
        break;
    }
  }

  @override
  Future<void> close() async {
    mediaPlayer.dispose();
    await renderStream.close();
  }

  @override
  Future<void> stop() {
    playerTypeStream.sink.add(PlayerType.none);
    switch (currentPlayerType) {
      case PlayerType.cdg:
        _cdgPlayer.currentMillis = 0;
        return mediaPlayer.stop();
      case PlayerType.vlc:
        return mediaPlayer.stop();
      case PlayerType.none:
        return Future.value();
    }
  }

  @override
  Future<void> pause() {
    switch (currentPlayerType) {
      case PlayerType.cdg:
      case PlayerType.vlc:
        return mediaPlayer.pause();
      case PlayerType.none:
        return Future.value();
    }
  }

  @override
  void restart() {
    switch (currentPlayerType) {
      case PlayerType.cdg:
      case PlayerType.vlc:
        _cdgPlayer.currentMillis = 0;
        mediaPlayer.seek(const Duration(milliseconds: 0));
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
        mediaPlayer.stop();
        playerTypeStream.sink.add(PlayerType.cdg);
        return await _loadZip(path);
      case 'mp3':
        mediaPlayer.stop();
        playerTypeStream.sink.add(PlayerType.vlc);
        return await _loadMp3(path);
      default:
        mediaPlayer.stop();
        playerTypeStream.sink.add(PlayerType.vlc);
        return await _loadVideo(path);
    }
  }

  @override
  bool get isPlaying {
    switch (currentPlayerType) {
      case PlayerType.vlc:
      case PlayerType.cdg:
        return mediaPlayer.state.playing;
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
        mediaPlayer.setVolume(max(mediaPlayer.state.volume - 0.05, 0.0));
        return notificationStream.sink.add('Volume: ${(mediaPlayer.state.volume * 100).round()}');
    }
  }

  @override
  void volumeUp() {
    switch (currentPlayerType) {
      case PlayerType.cdg:
      case PlayerType.vlc:
      case PlayerType.none:
        mediaPlayer.setVolume(min(mediaPlayer.state.volume + 0.05, 1.0));
        return notificationStream.sink.add('Volume: ${(mediaPlayer.state.volume * 100).round()}');
    }
  }
}
