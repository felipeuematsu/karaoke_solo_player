import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_karaoke_player/cdg/lib/cdg_player.dart';
import 'package:flutter_karaoke_player/model/singer_model.dart';
import 'package:flutter_karaoke_player/model/song_model.dart';
import 'package:flutter_karaoke_player/model/song_queue_item.dart';
import 'package:flutter_karaoke_player/service/karaoke_main_player_controller.dart';
import 'package:just_audio/just_audio.dart';

class KaraokeMainPlayerControllerImpl extends KaraokeMainPlayerController {
  KaraokeMainPlayerControllerImpl() {
    playerTypeStream.stream.listen((type) => currentPlayerType = type);
    timer;
    Future.delayed(const Duration(seconds: 1)).then((value) => loadSong(SongModel(0, 0, "test", 'test', 'assets/mp4/test.mp4')).then((_) => Future.delayed(const Duration(seconds: 1)).then((_) => play())));
    // Future.delayed(const Duration(seconds: 1)).then((value) => loadSong(SongModel(0, 0, "test", 'test', 'assets/cdg/test.zip')).then((_) => Future.delayed(const Duration(seconds: 1)).then((_) => play())));
  }

  @override
  late final timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
    if (isLoaded && currentPlayerType == PlayerType.cdg) {
      try {
        final render = _cdgPlayer.render(_audioPlayer.position.inMilliseconds);
        if (render.isChanged) {
          renderStream.sink.add(render);
        }
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
    }
  });

  bool isLoaded = false;

  var currentPlayerType = PlayerType.none;
  int? playerWindowId;

  @override
  final Player vlcPlayer = Player(id: 14325);
  final CDGPlayer _cdgPlayer = CDGPlayer();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _loadZip(String zipPath) async {
    final file = File(zipPath);
    final bytes = file.readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive.files) {
      final content = file.content as Uint8List;
      if (file.name.contains('.cdg')) {
        _cdgPlayer.load(content.buffer);
      }
      if (file.name.contains('.mp3')) {
        final myCustomSource = MyCustomSource(content);
        await _audioPlayer.setAudioSource(myCustomSource);
      }
    }
  }

  Future<void> _loadVideo(String path) async {
    final file = File(path);
    final source = Media.file(file);
    vlcPlayer.open(source, autoStart: false);
  }

  @override
  Future<void> play() async {
    if (!isLoaded) return;
    switch (currentPlayerType) {
      case PlayerType.vlc:
        vlcPlayer.play();
        return playerTypeStream.sink.add(PlayerType.vlc);
      case PlayerType.cdg:
        _audioPlayer.play();
        return playerTypeStream.sink.add(PlayerType.cdg);
      case PlayerType.none:
        break;
    }
  }

  @override
  Future<void> close() async {
    switch (currentPlayerType) {
      case PlayerType.vlc:
        return vlcPlayer.dispose();
      case PlayerType.cdg:
        await _audioPlayer.stop();
        return renderStream.close();
      case PlayerType.none:
        break;
    }
  }

  @override
  Future<void> stop() async {
    switch (currentPlayerType) {
      case PlayerType.vlc:
        return vlcPlayer.stop();
      case PlayerType.cdg:
        return _audioPlayer.stop();
      case PlayerType.none:
        return;
    }
  }

  @override
  Future<void> pause() async {
    if (!isLoaded) return;
    switch (currentPlayerType) {
      case PlayerType.vlc:
        return vlcPlayer.pause();
      case PlayerType.cdg:
        return _audioPlayer.pause();
      case PlayerType.none:
        return;
    }
  }

  @override
  void addToQueue(int songId, int singerId) {
    // TODO: get song and singer from server
    final song = SongModel(0, 0, '', '', '');
    final singer = SingerModel(0, '');

    queue.add(SongQueueItem(song, singer));
  }

  @override
  Future<void> restart() async {
    if (!isLoaded) return;
    switch (currentPlayerType) {
      case PlayerType.vlc:
        vlcPlayer.seek(const Duration(milliseconds: 0));
        break;
      case PlayerType.cdg:
        _audioPlayer.seek(const Duration(milliseconds: 0));
        break;
      case PlayerType.none:
        break;
    }
    return play();
  }

  @override
  void skip() {
    // TODO: implement skip when queue ready
    if (!isLoaded) return;
    _audioPlayer.seek(const Duration(milliseconds: 0));
    _audioPlayer.play();
  }

  @override
  Future<void> loadSong(SongModel song) async {
    final path = song.path;
    final extension = path.split('.').last;
    switch (extension) {
      case 'zip':
        playerTypeStream.sink.add(PlayerType.cdg);
        return await _loadZip(path).then((_) => isLoaded = true);
      default:
        playerTypeStream.sink.add(PlayerType.vlc);
        return await _loadVideo(path).then((_) => isLoaded = true);
    }
  }
}

// Feed your own stream of bytes into the player
class MyCustomSource extends StreamAudioSource {
  MyCustomSource(this.bytes);

  final List<int> bytes;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
