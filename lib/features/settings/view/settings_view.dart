import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_karaoke_player/features/settings/controller/settings_controller.dart';
import 'package:flutter_karaoke_player/features/settings/model/repository_path_notifier.dart';
import 'package:flutter_karaoke_player/features/settings/view/repository_path_model_editor.dart';
import 'package:gap/gap.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final controller = SettingsController();

  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 800,
            height: 600,
            child: NavigationView(
              appBar: const NavigationAppBar(title: Text('Settings')),
              content: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(children: [
                  Row(children: [
                    const Spacer(),
                    const Text('Downloads path'),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Button(onPressed: () => controller.saveAll(), child: const Icon(FluentIcons.save)),
                      ),
                    ),
                  ]),
                  const Gap(8),
                  Row(children: [
                    Expanded(child: TextFormBox(controller: controller.downloadsPathController)),
                    const Gap(8),
                    Button(
                      onPressed: () async => FilePicker.platform
                          .getDirectoryPath(dialogTitle: 'Select downloads path')
                          .then((value) => value != null ? controller.setDownloadsPath(value) : null),
                      child: const Icon(FluentIcons.folder_open),
                    ),
                  ]),
                  const Gap(16),
                  const Text('Installation path'),
                  const Gap(8),
                  Row(children: [
                    Expanded(child: TextFormBox(controller: controller.installationPathController)),
                    const Gap(8),
                    Button(
                      onPressed: () async => FilePicker.platform
                          .getDirectoryPath(dialogTitle: 'Select installation path')
                          .then((value) => value != null ? controller.setInstallationPath(value) : null),
                      child: const Icon(FluentIcons.folder_open),
                    ),
                  ]),
                  const Gap(16),
                  Row(children: [
                    const Spacer(),
                    const Text('Paths'),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(FluentIcons.add),
                          onPressed: () => setState(() => controller.pathsController.value.add(RepositoryPathNotifier.fromModel(defaultRepositoryPathModel))),
                        ),
                      ),
                    ),
                  ]),
                  const Gap(8),
                  SizedBox(
                    height: 300,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse}),
                      child: ValueListenableBuilder(
                        valueListenable: controller.pathsController,
                        builder: (context, value, child) => Scrollbar(
                          thumbVisibility: true,
                          controller: scrollController,
                          child: ListView.separated(
                            separatorBuilder: (context, index) => const Gap(8),
                            controller: scrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: value.length,
                            itemBuilder: (context, index) =>
                                RepositoryPathModelEditor(notifier: value[index], onDelete: () => setState(() => value.removeAt(index))),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Gap(16),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
