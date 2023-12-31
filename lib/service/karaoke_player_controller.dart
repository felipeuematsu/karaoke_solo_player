import 'dart:async';

import 'package:flutter_karaoke_player/cdg/lib/cdg_render.dart';
import 'package:karaoke_request_api/karaoke_request_api.dart';
import 'package:media_kit/media_kit.dart';

enum PlayerType { vlc, cdg, none }

abstract class KaraokePlayerController {
  final renderStream = StreamController<CdgRender>.broadcast();
  final playerTypeStream = StreamController<PlayerType>.broadcast();
  final notificationStream = StreamController<Map<String, String>>.broadcast();

  Player get mediaPlayer;

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

  void setVolume(int volume);
}
