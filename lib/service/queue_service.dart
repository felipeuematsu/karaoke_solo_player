import 'package:flutter_karaoke_player/model/song_queue_item.dart';

abstract class QueueService {
  const QueueService();

  Future<SongQueueItem?> getNextItem();
}
