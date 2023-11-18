import 'package:fluent_ui/fluent_ui.dart' hide Image;
import 'package:flutter_karaoke_player/cdg/lib/cdg_context.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VlcBuilder extends StatefulWidget {
  const VlcBuilder({super.key, required this.player});

  final Player player;

  @override
  State<VlcBuilder> createState() => _VlcBuilderState();
}

class _VlcBuilderState extends State<VlcBuilder> {
  late final controller = VideoController(widget.player);

  @override
  Widget build(BuildContext context) {
    return Video(
      controller: controller,
      height: CDGContext.kHeightDouble,
      width: CDGContext.kWidthDouble,
    );
  }
}
