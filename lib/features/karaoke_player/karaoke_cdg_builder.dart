import 'dart:async';
import 'dart:ui';

import 'package:bitmap/bitmap.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Image;
import 'package:flutter_karaoke_player/cdg/cdg_painter.dart';
import 'package:flutter_karaoke_player/cdg/lib/cdg_context.dart';
import 'package:flutter_karaoke_player/cdg/lib/cdg_render.dart';

class CdgBuilder extends StatefulWidget {
  const CdgBuilder({Key? key, required this.renderStream}) : super(key: key);

  final StreamController<CdgRender> renderStream;

  @override
  State<CdgBuilder> createState() => _CdgBuilderState();
}

class _CdgBuilderState extends State<CdgBuilder> {
  CustomPaint? lastPaint;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CdgRender>(
      stream: widget.renderStream.stream,
      builder: (_, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('No video loaded'));
        }
        return FutureBuilder<Image>(
          future: Bitmap.fromHeadful(data.imageData.width, data.imageData.height, data.imageData.data).buildImage(),
          builder: (context, snapshot) {
            final imageData = snapshot.data;
            if (snapshot.connectionState == ConnectionState.done && imageData != null) {
              return lastPaint = CustomPaint(
                painter: CdgPainter(imageData: imageData),
                size: const Size(CDGContext.kWidthDouble, CDGContext.kHeightDouble),
                isComplex: true,
                willChange: data.isChanged,
              );
            }
            return lastPaint ?? const SizedBox();
          },
        );
      },
    );
  }
}
