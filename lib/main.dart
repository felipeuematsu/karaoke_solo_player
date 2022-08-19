import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_karaoke_player/features/karaoke_player_window/karaoke_player_window.dart';
import 'package:flutter_karaoke_player/service/client/karaoke_client.dart';
import 'package:flutter_karaoke_player/service/impl/karaoke_main_player_controller_impl.dart';
import 'package:flutter_karaoke_player/service/impl/queue_controller_impl.dart';
import 'package:flutter_karaoke_player/service/impl/queue_service_impl.dart';
import 'package:flutter_karaoke_player/service/karaoke_main_player_controller.dart';
import 'package:flutter_karaoke_player/service/queue_controller.dart';
import 'package:flutter_karaoke_player/service/queue_service.dart';
import 'package:get_it/get_it.dart';

void main(List<String> args) async {
  await DartVLC.initialize();

  WidgetsFlutterBinding.ensureInitialized();
  GetIt.I.registerSingleton<KaraokeMainPlayerController>(KaraokeMainPlayerControllerImpl());
  GetIt.I.registerSingleton<KaraokeClient>(KaraokeClient());
  GetIt.I.registerSingleton<QueueService>(QueueServiceImpl(GetIt.I.get()));
  GetIt.I.registerSingleton<QueueController>(QueueControllerImpl(GetIt.I.get()));
  runApp(const MainApp());
  doWhenWindowReady(() async {
    appWindow.alignment = Alignment.topLeft;
    appWindow.title = 'Karaoke';
    appWindow.show();
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'Karaoke Player',
      home: KaraokePlayerWindow(videoPlayerService: GetIt.I.get()),
    );
  }
}
