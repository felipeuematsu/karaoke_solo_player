import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_karaoke_player/features/karaoke_player/karaoke_player_window.dart';
import 'package:flutter_karaoke_player/service/client/karaoke_client.dart';
import 'package:flutter_karaoke_player/service/impl/karaoke_player_controller_impl.dart';
import 'package:flutter_karaoke_player/service/impl/queue_service_impl.dart';
import 'package:flutter_karaoke_player/service/karaoke_player_controller.dart';
import 'package:flutter_karaoke_player/service/queue_service.dart';
import 'package:get_it/get_it.dart';
import 'package:media_kit/media_kit.dart';

void main(List<String> args) async {
  MediaKit.ensureInitialized();

  WidgetsFlutterBinding.ensureInitialized();
  GetIt.I.registerSingleton<KaraokeClient>(KaraokeClient());
  GetIt.I.registerSingleton<QueueService>(QueueServiceImpl(GetIt.I()));
  GetIt.I.registerSingleton<KaraokePlayerController>(KaraokePlayerControllerImpl(GetIt.I()));
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
      home: KaraokePlayerWindow(videoPlayerService: GetIt.I()),
    );
  }
}
