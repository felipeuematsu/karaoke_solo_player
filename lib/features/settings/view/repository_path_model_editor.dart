import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_karaoke_player/features/settings/model/repository_path_notifier.dart';
import 'package:gap/gap.dart';

class RepositoryPathModelEditor extends StatefulWidget {
  const RepositoryPathModelEditor({super.key, required this.notifier, required this.onDelete});

  final RepositoryPathNotifier notifier;
  final VoidCallback onDelete;

  @override
  State<RepositoryPathModelEditor> createState() => _RepositoryPathModelEditorState();
}

class _RepositoryPathModelEditorState extends State<RepositoryPathModelEditor> {
  final regexTestController = TextEditingController();

  late final TextEditingController regexController = TextEditingController(text: widget.notifier.regex);
  late final TextEditingController pathController = TextEditingController(text: widget.notifier.path);
  late final TextEditingController titlePosController = TextEditingController(text: widget.notifier.titlePos.toString());
  late final TextEditingController artistPosController = TextEditingController(text: widget.notifier.artistPos.toString());

  @override
  void initState() {
    super.initState();
    pathController.addListener(() => widget.notifier.path = pathController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Acrylic(
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(8),
        width: 460,
        child: Column(children: [
          const Gap(8),
          Row(children: [const Spacer(), IconButton(icon: const Icon(FluentIcons.delete), onPressed: widget.onDelete)]),
          Row(children: [
            Expanded(child: TextFormBox(controller: pathController)),
            const Gap(8),
            Button(
              onPressed: () async =>
                  FilePicker.platform.getDirectoryPath(dialogTitle: 'Select path').then((value) => value != null ? pathController.text = value : null),
              child: const Icon(FluentIcons.folder_open),
            ),
          ]),
          const Gap(8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(children: [
                const Text('Regex'),
                const Gap(4),
                TextFormBox(controller: regexController, onChanged: (value) => widget.notifier.regex = value),
              ]),
            ),
            const Gap(8),
            Expanded(
              child: Column(children: [
                const Text('Regex test'),
                const Gap(4),
                TextFormBox(controller: regexTestController),
              ]),
            ),
          ]),
          const Gap(8),
          Row(children: [
            Expanded(
              child: Column(children: [
                const Text('Artist position'),
                const Gap(4),
                TextFormBox(
                  controller: artistPosController,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) => widget.notifier.artistPos = int.parse(value),
                ),
              ]),
            ),
            const Gap(8),
            Expanded(
              child: Column(children: [
                const Text('Title position'),
                const Gap(4),
                TextFormBox(
                  controller: titlePosController,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) => widget.notifier.titlePos = int.parse(value),
                ),
              ]),
            ),
          ]),
          const Gap(8),
          ValueListenableBuilder(
            valueListenable: regexTestController,
            builder: (context, test, child) => ValueListenableBuilder(
              valueListenable: widget.notifier,
              builder: (context, value, child) {
                final match = RegExp(value.regex).firstMatch(test.text);
                if (match == null || match.groupCount < value.artistPos + 1 || match.groupCount < value.titlePos + 1) {
                  return const Text('Invalid regex configuration');
                }
                final artist = match.group(value.artistPos + 1);
                final title = match.group(value.titlePos + 1);
                if (artist == null || title == null) return const Text('Invalid test');

                return RichText(
                  text: TextSpan(style: const TextStyle(color: Colors.black), children: [
                    const TextSpan(text: 'Artist: '),
                    TextSpan(text: artist, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: '\n'),
                    const TextSpan(text: 'Title: '),
                    TextSpan(text: title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
