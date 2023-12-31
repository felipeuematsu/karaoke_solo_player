import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_karaoke_player/cdg/lib/cdg_context.dart';
import 'package:flutter_karaoke_player/features/karaoke_player/components/notification_overlay.dart';
import 'package:flutter_karaoke_player/features/karaoke_player/components/qr_code_overlay.dart';
import 'package:flutter_karaoke_player/features/karaoke_player/components/window_scaffold.dart';
import 'package:flutter_karaoke_player/features/karaoke_player/idle_view.dart';
import 'package:flutter_karaoke_player/features/karaoke_player/karaoke_cdg_builder.dart';
import 'package:flutter_karaoke_player/features/karaoke_player/media_kit_builder.dart';
import 'package:flutter_karaoke_player/features/settings/view/settings_view.dart';
import 'package:flutter_karaoke_player/service/karaoke_player_controller.dart';

class KaraokePlayerWindow extends StatefulWidget {
  const KaraokePlayerWindow({super.key, required this.videoPlayerService});

  final KaraokePlayerController videoPlayerService;

  @override
  State<KaraokePlayerWindow> createState() => _KaraokePlayerWindowState();
}

class _KaraokePlayerWindowState extends State<KaraokePlayerWindow> {
  CustomPaint? lastPaint;

  final focusNode = FocusNode();

  Function(KeyEvent) get onKey => (KeyEvent event) async {
        switch (event) {
          case KeyDownEvent():
            return switch (event.logicalKey) {
              LogicalKeyboardKey.space => widget.videoPlayerService.isPlaying ? widget.videoPlayerService.pause() : widget.videoPlayerService.play(),
              LogicalKeyboardKey.arrowLeft => widget.videoPlayerService.restart(),
              LogicalKeyboardKey.arrowRight => widget.videoPlayerService.skip(),
              LogicalKeyboardKey.arrowDown => widget.videoPlayerService.volumeDown(),
              LogicalKeyboardKey.arrowUp => widget.videoPlayerService.volumeUp(),
              LogicalKeyboardKey.escape => Navigator.of(context).push(
                  FluentDialogRoute(
                    context: context,
                    builder: (context) => const SettingsView(),
                    settings: const RouteSettings(name: 'Settings'),
                  ),
                ),
              _ => Future.value(),
            };
        }
      };

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height / CDGContext.kHeightDouble;
    final width = MediaQuery.of(context).size.width / CDGContext.kWidthDouble;
    final scale = MediaQuery.of(context).size.height / 1080;
    final minScale = min(height, width);
    print('scale: $scale, minScale: $minScale');
    return KeyboardListener(
      onKeyEvent: onKey,
      autofocus: true,
      focusNode: focusNode,
      child: WindowScaffold(
        body: Center(
          child: Stack(children: [
            Positioned.fill(
              child: Center(
                child: StreamBuilder<PlayerType>(
                  stream: widget.videoPlayerService.playerTypeStream.stream,
                  builder: (context, snapshot) {
                    return switch (snapshot.data) {
                      PlayerType.vlc => MediaKitBuilder(player: widget.videoPlayerService.mediaPlayer),
                      PlayerType.cdg => Transform.scale(
                          scale: minScale,
                          alignment: Alignment.center,
                          child: CdgBuilder(renderStream: widget.videoPlayerService.renderStream),
                        ),
                      _ => const IdleView(),
                    };
                  },
                ),
              ),
            ),
            Positioned.fill(
              top: 100 * scale,
              right: 48 * scale,
              child: NotificationOverlay(notificationStream: widget.videoPlayerService.notificationStream, scale: scale),
            ),
            Positioned(
              bottom: 50 * scale,
              left: 60 * scale,
              height: 120 * scale,
              width: 120 * scale,
              child: FutureBuilder<String?>(
                future: getWebUrl(),
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  if (data == null) return const ProgressRing();
                  return QrCodeOverlay(data: data);
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
