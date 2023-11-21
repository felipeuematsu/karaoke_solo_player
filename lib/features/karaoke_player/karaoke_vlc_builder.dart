import 'package:fluent_ui/fluent_ui.dart' hide Image;
import 'package:flutter_karaoke_player/cdg/lib/cdg_context.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class MediaKitBuilder extends StatefulWidget {
  const MediaKitBuilder({super.key, required this.player});

  final Player player;

  @override
  State<MediaKitBuilder> createState() => _MediaKitBuilderState();
}

class _MediaKitBuilderState extends State<MediaKitBuilder> {
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
