import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_karaoke_player/model/song_queue_item.dart';
import 'package:flutter_karaoke_player/service/client/karaoke_client.dart';
import 'package:flutter_karaoke_player/service/queue_service.dart';

class QueueServiceImpl extends QueueService {
  const QueueServiceImpl(this.client);

  final KaraokeClient client;

  @override
  Future<SongQueueItem?> getNextItem() async {
    try {
      final response = await client.get('/queue/next');
      return SongQueueItem.fromMap(response.data);
    } on DioError catch (e) {
      if (e.response?.statusCode == HttpStatus.notFound) {
        return null;
      } else {
        rethrow;
      }
    } on Exception {
      return null;
    }
  }
}
