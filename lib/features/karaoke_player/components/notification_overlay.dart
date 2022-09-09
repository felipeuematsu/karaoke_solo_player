import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';

class NotificationOverlay extends StatefulWidget {
  const NotificationOverlay({Key? key, required this.notificationStream, required this.scale}) : super(key: key);

  final StreamController<String> notificationStream;
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
    widget.notificationStream.stream.listen((event) {
      controller.forward().then((value) => Future.delayed(const Duration(seconds: 1)).then((value) => controller.reverse()));
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: widget.notificationStream.stream,
      builder: (context, snapshot) {
        return FadeTransition(
          opacity: controller,
          child: Text(
            snapshot.data ?? '',
            textScaleFactor: widget.scale,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 48, color: Colors.white, shadows: [
              Shadow(
                blurRadius: 16,
                offset: Offset(0, 0),
                color: Colors.black,
              )
            ]),
          ),
        );
      },
    );
  }
}
