import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_karaoke_player/cdg/lib/cdg_context.dart';
import 'package:flutter_karaoke_player/features/karaoke_player/karaoke_cdg_builder.dart';
import 'package:flutter_karaoke_player/features/karaoke_player/karaoke_vlc_builder.dart';
import 'package:flutter_karaoke_player/features/karaoke_player_window/components/window_scaffold.dart';
import 'package:flutter_karaoke_player/service/karaoke_main_player_controller.dart';

class KaraokePlayerWindow extends StatefulWidget {
  const KaraokePlayerWindow({Key? key, required this.videoPlayerService}) : super(key: key);

  final KaraokeMainPlayerController videoPlayerService;

  @override
  State<KaraokePlayerWindow> createState() => _KaraokePlayerWindowState();
}

class _KaraokePlayerWindowState extends State<KaraokePlayerWindow> {
  CustomPaint? lastPaint;

  final focusNode = FocusNode();

  Function(KeyEvent) get onKey => (KeyEvent event) {
    if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.space) {
            if (widget.videoPlayerService.isPlaying) {
              widget.videoPlayerService.pause();
            } else {
              widget.videoPlayerService.play();
            }
          } else if (key == LogicalKeyboardKey.arrowLeft) {
            widget.videoPlayerService.restart();
          } else if (key == LogicalKeyboardKey.arrowRight) {
            widget.videoPlayerService.skip();
          }
        }
      };

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      onKeyEvent: onKey,
      autofocus: true,
      focusNode: focusNode,
      child: WindowScaffold(
        body: Center(
          child: StreamBuilder<PlayerType>(
            stream: widget.videoPlayerService.playerTypeStream.stream,
            builder: (context, snapshot) {
              switch (snapshot.data) {
                case PlayerType.vlc:
                  final player = widget.videoPlayerService.vlcPlayer;
                  if (player == null) return const SizedBox();
                  return SizedBox(height: double.infinity, width: double.infinity, child: VlcBuilder(player: player));
                case PlayerType.cdg:
                  final height = MediaQuery.of(context).size.height / CDGContext.kHeightDouble;
                  final width = MediaQuery.of(context).size.width / CDGContext.kWidthDouble;
                  final minScale = min(height, width);

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(minScale, minScale, 1.0),
                    child: CdgBuilder(renderStream: widget.videoPlayerService.renderStream),
                  );
                default:
                  return const SizedBox(child: Center(child: ProgressRing()));
              }
            },
          ),
        ),
      ),
    );
  }
}
