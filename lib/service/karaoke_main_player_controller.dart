import 'dart:async';
import 'dart:collection';

import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter_karaoke_player/cdg/lib/cdg_render.dart';
import 'package:flutter_karaoke_player/model/song_model.dart';
import 'package:flutter_karaoke_player/model/song_queue_item.dart';

abstract class KaraokeMainPlayerController {
  abstract final Timer timer;

  final renderStream = StreamController<CdgRender>.broadcast();
  final playerTypeStream = StreamController<PlayerType>.broadcast();
  Player? get vlcPlayer;

  Queue<SongQueueItem> queue = Queue<SongQueueItem>();

  Future<void> loadSong(SongModel song);

  void play();

  void pause();

  void stop();

  void close();

  void addToQueue(int songId, int singerId);

  void skip();

  void restart();
}
enum PlayerType {
  vlc,
  cdg,
  none,
}