import 'dart:async';

import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter_karaoke_player/cdg/lib/cdg_render.dart';
import 'package:flutter_karaoke_player/model/song_model.dart';

enum PlayerType { vlc, cdg, none }

abstract class KaraokeMainPlayerController {
  final renderStream = StreamController<CdgRender>.broadcast();
  final playerTypeStream = StreamController<PlayerType>.broadcast();

  Player? get vlcPlayer;

  bool get isPlaying;

  Future<void> loadSong(SongModel song);

  void play();

  void pause();

  void stop();

  void close();

  void skip();

  void restart();

  void volumeDown();

  void volumeUp();
}
