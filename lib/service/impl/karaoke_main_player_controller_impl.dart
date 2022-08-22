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
    vlcPlayer.positionStream.listen((event) {
      if (isLoaded && currentPlayerType == PlayerType.cdg) {
        try {
          final time = event.position?.inMilliseconds;
          final render = _cdgPlayer.render(time ?? 0);
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
    Future.delayed(const Duration(seconds: 1))
        .then((value) => loadSong(SongModel(0, 0, "test", 'test', 'assets/mp4/test.mp4')).then((_) => Future.delayed(const Duration(seconds: 1)).then((_) => play())));
    queue.add(SongQueueItem(SongModel(0, 0, 'title', 'artist', 'assets/cdg/test.zip'), SingerModel(0, 'singer')));
    // Future.delayed(const Duration(seconds: 1)).then((value) => loadSong(SongModel(0, 0, "test", 'test', 'assets/cdg/test.zip')).then((_) => Future.delayed(const Duration(seconds: 1)).then((_) => play())));
  }

  @override
  final Player vlcPlayer = Player(id: 14325, commandlineArguments: ['--sout-ts-pcr 20']);
  final CDGPlayer _cdgPlayer = CDGPlayer();
  final AudioPlayer _audioPlayer = AudioPlayer();

  var currentPlayerType = PlayerType.none;
  bool isLoaded = false;
  int? playerWindowId;

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
        final tempFile = File('temp');
        await tempFile.writeAsBytes(content);
        vlcPlayer.open(Media.file(tempFile));
        // await _audioPlayer.setAudioSource(myCustomSource);
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
        // if (_audioPlayer.playing) {
        //   _audioPlayer.stop();
        //   print('audio player stopped');
        // }
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
    await _audioPlayer.stop();
    await renderStream.close();
  }

  @override
  Future<void> stop() async {
    switch (currentPlayerType) {
      case PlayerType.vlc:
      case PlayerType.cdg:
        return vlcPlayer.stop();
      case PlayerType.none:
        return;
    }
  }

  @override
  Future<void> pause() async {
    if (!isLoaded) return;
    switch (currentPlayerType) {
      case PlayerType.vlc:
      case PlayerType.cdg:
        return vlcPlayer.pause();
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
      case PlayerType.cdg:
        vlcPlayer.seek(const Duration(milliseconds: 0));
        break;
      case PlayerType.none:
        break;
    }
    return play();
  }

  @override
  void skip() {
    if (queue.isNotEmpty) {
      final item = queue.removeFirst();
      loadSong(item.song).then((value) => play());
    } else {
      stop();
    }
  }

  @override
  Future<void> loadSong(SongModel song) async {
    final path = song.path;
    final extension = path.split('.').last;
    switch (extension) {
      case 'zip':
        vlcPlayer.stop();
        playerTypeStream.sink.add(PlayerType.cdg);
        return await _loadZip(path).then((_) => isLoaded = true);
      default:
        _audioPlayer.stop();
        playerTypeStream.sink.add(PlayerType.vlc);
        return await _loadVideo(path).then((_) => isLoaded = true);
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
}
