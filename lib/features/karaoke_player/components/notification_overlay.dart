import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';

class NotificationOverlay extends StatefulWidget {
  const NotificationOverlay({super.key, required this.notificationStream, required this.scale});

  final StreamController<Map<String, String>> notificationStream;
  final double scale;

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController controller;

  String notificationMessage = '';

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    widget.notificationStream.stream.listen((_) async {
      await controller.forward();
      await Future.delayed(const Duration(seconds: 1));
      await controller.reverse();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, String>>(
      stream: widget.notificationStream.stream,
      builder: (context, snapshot) => FadeTransition(
        opacity: controller,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (snapshot.data?['image'] != null) ...[
            Image.network(
              snapshot.data?['image'] ?? '',
              height: 64,
              width: 64,
            ),
            const Gap(8),
          ],
          Text(
            snapshot.data?['message'] ?? '',
            textScaleFactor: widget.scale,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 48,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 16, offset: Offset(0, 0), color: Colors.black)],
            ),
          ),
        ]),
      ),
    );
  }
}
