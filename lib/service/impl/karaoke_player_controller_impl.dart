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
  late Timer timer;

  KaraokePlayerControllerImpl(this._queueService) {
    timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final data = jsonEncode({
        'position': currentSongId == null ? 0 : mediaPlayer.state.position.inSeconds,
        'songId': currentSongId,
        'singer': currentSinger,
        'isPlaying': currentSongId == null ? false : isPlaying,
      });
      webSocketChannel?.sink.add(jsonEncode({'volume': mediaPlayer.state.volume.round()}));
      webSocketChannel?.sink.add(data);
    });
    mediaPlayer.stream.completed.listen((isCompleted) async {
      if (isCompleted && isSearching == false) {
        currentSinger = null;
        currentSongId = null;

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
          final webSocket = webSocketChannel = WebSocketChannel.connect(Uri.parse('ws://$apiUrl'));
          webSocket.sink.add(jsonEncode({'volume': mediaPlayer.state.volume.round()}));
          decodeWebSocketJson(String data) async {
            try {
              final decoded = json.decode(data);
              if (decoded['volume'] != null) {
                return setVolume(decoded['volume'] as int);
              }

              return loadSong(SongModel.fromJson(decoded));
            } catch (_) {
              // ignore
            }
          }

          webSocket.stream.listen((data) async {
            if (data is String) {
              return switch (data) {
                'play' => play(),
                'pause' => pause(),
                'stop' => stop(),
                'restart' => restart(),
                'skip' => skip(),
                'volumeDown' => volumeDown(),
                'volumeUp' => volumeUp(),
                'volume' => webSocket.sink.add(jsonEncode({'volume': mediaPlayer.state.volume.round()})),
                _ => decodeWebSocketJson(data)
              };
            }
          });
          print('Connected to WebSocket');
        } on Exception {
          webSocketChannel?.sink.close();
          webSocketChannel = null;
        }
      }
    });
  }

  @override
  final Player mediaPlayer = Player()..setVolume(70);
  final _cdgPlayer = CDGPlayer();
  final _zipDecoder = ZipDecoder();
  final QueueService _queueService;

  PlayerType currentPlayerType = PlayerType.none;
  WebSocketChannel? webSocketChannel;

  String? currentSinger;
  int? currentSongId;
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
        mediaPlayer.open(await Media.memory(content), play: false);
      }
    }
  }

  Future<void> _loadMp3(String mp3Path) async {
    final basePath = mp3Path.split('.').first;
    final cdgPath = '$basePath.cdg';
    final mp3 = File(mp3Path);
    final cdg = File(cdgPath);
    cdg.exists().then((value) => cdg.readAsBytes().then((value) => _cdgPlayer.load(value.buffer)));
    mp3.exists().then((value) => mediaPlayer.open(Media(mp3Path), play: false));
  }

  Future<void> _loadVideo(String path) async {
    mediaPlayer.open(Media(path), play: false);
  }

  @override
  Future<void> play() async {
    switch (currentPlayerType) {
      case PlayerType.vlc:
        await mediaPlayer.play();
        return playerTypeStream.sink.add(PlayerType.vlc);
      case PlayerType.cdg:
        await mediaPlayer.play();
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
  Future<void> stop() async {
    playerTypeStream.sink.add(PlayerType.none);
    switch (currentPlayerType) {
      case PlayerType.cdg:
        _cdgPlayer.currentMillis = 0;
        return mediaPlayer.stop();
      case PlayerType.vlc:
        return mediaPlayer.stop();
      case PlayerType.none:
    }
  }

  @override
  Future<void> pause() async {
    switch (currentPlayerType) {
      case PlayerType.cdg:
      case PlayerType.vlc:
        return mediaPlayer.pause();
      case PlayerType.none:
    }
  }

  @override
  Future<void> restart() async {
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
        _cdgPlayer.currentMillis = 0;
        mediaPlayer.seek(const Duration(milliseconds: 0));
        await play();
        notificationStream.sink.add({
          'message': 'Now playing: ${value.song.artist} - ${value.song.title}\n by ${value.singer.name}',
        });
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
        playerTypeStream.sink.add(PlayerType.cdg);
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
  Future<void> volumeDown() async {
    var newVolume = max(mediaPlayer.state.volume - 5, 0.0);
    await mediaPlayer.setVolume(newVolume);
    return notificationStream.sink.add({'message': 'Volume: ${(newVolume).round()}'});
  }

  @override
  Future<void> volumeUp() async {
    var newVolume = min(mediaPlayer.state.volume + 5, 100.0);
    await mediaPlayer.setVolume(newVolume);
    return notificationStream.sink.add({'message': 'Volume: ${(newVolume).round()}'});
  }

  @override
  Future<void> setVolume(int volume) async {
    var newVolume = max(min(volume, 100.0), 0.0).toDouble();
    await mediaPlayer.setVolume(newVolume);
    return notificationStream.sink.add({'message': 'Volume: ${(newVolume).round()}'});
  }
}
