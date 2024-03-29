import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';

class WindowScaffold extends StatelessWidget {
  const WindowScaffold({super.key, this.body, this.background});

  final Widget? body;
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: background ?? Container()),
        Positioned.fill(child: body ?? Container()),
        Positioned.fill(child: WindowTitleBarBox(child: const _CustomMoveWindow())),
      ],
    );
  }
}

class _CustomMoveWindow extends StatelessWidget {
  const _CustomMoveWindow();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: () => appWindow.maximizeOrRestore(),
      onPanStart: (details) => appWindow.startDragging(),
    );
  }
}
