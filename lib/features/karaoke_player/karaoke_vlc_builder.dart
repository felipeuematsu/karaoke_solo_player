import 'package:dart_vlc/dart_vlc.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Image;
import 'package:flutter_karaoke_player/cdg/lib/cdg_context.dart';

class VlcBuilder extends StatelessWidget {
  const VlcBuilder({Key? key, required this.player}) : super(key: key);

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Video(
      player: player,
      height: CDGContext.kHeightDouble,
      width: CDGContext.kWidthDouble,
      showControls: false,
    );
  }
}
