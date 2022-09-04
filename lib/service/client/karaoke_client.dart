import 'package:dio/dio.dart';
import 'package:flutter_karaoke_player/config/constants.dart';
import 'package:flutter_karaoke_player/service/client/abstract_client.dart';

class KaraokeClient extends AbstractClient {
  @override
  BaseOptions getBaseOptions() {
    return BaseOptions(
      baseUrl: 'http://$apiUrl:$apiPort',
      connectTimeout: 50000,
      receiveTimeout: 50000,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }
}
