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
    final scale = MediaQuery.of(context).size.height / 1080;
    return StreamBuilder<Map<String, String>>(
      stream: widget.notificationStream.stream,
      builder: (context, snapshot) => FadeTransition(
        opacity: controller,
        child: SizedBox(
          width: MediaQuery.of(context).size.width / 2,
          child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
            if (snapshot.data?['image'] != null) ...[
              Image.network(snapshot.data?['image'] ?? '', height: 64 * scale, width: 64 * scale),
              Gap(8 * scale),
            ],
            Expanded(
              child: Text(
                snapshot.data?['message'] ?? '',
                textScaler: TextScaler.linear(widget.scale),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 48 * scale, color: Colors.white, shadows: [Shadow(blurRadius: 16 * scale)]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
