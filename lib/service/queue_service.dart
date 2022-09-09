import 'package:karaoke_request_api/karaoke_request_api.dart';

abstract class QueueService {
  const QueueService();

  Future<SongQueueItem?> getNextItem();
}
