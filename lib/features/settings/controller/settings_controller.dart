import 'dart:convert';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_karaoke_player/features/settings/model/repository_path_notifier.dart';
import 'package:flutter_karaoke_player/features/settings/model/settings_model.dart';
import 'package:get_it/get_it.dart';
import 'package:karaoke_request_api/karaoke_request_api.dart';
import 'package:path_provider/path_provider.dart';

final platformSeparator = Platform.isWindows ? '\\' : '/';

final defaultRepositoryPathModel = RepositoryPathModel(
  path: '${Directory.current.path}${platformSeparator}karaoke',
  regex: '(?<artist>.*) - (?<title>.*)',
  artistPos: 0,
  titlePos: 1,
);
final defaultRepositoryDownloadsPathModel = RepositoryPathModel(
  path: '${Directory.current.path}${platformSeparator}karaoke${platformSeparator}downloads',
  regex: '(?<artist>.*) - (?<title>.*)',
  artistPos: 0,
  titlePos: 1,
);

class SettingsController {
  SettingsController() {
    readSettings().then((value) async {
      downloadsPathController.text = value.downloadsPath ?? (await getDownloadsDirectory())?.path ?? (await getApplicationDocumentsDirectory()).path;
      final savedPaths = value.paths?.map(RepositoryPathNotifier.fromModel).toList();
      pathsController.value = savedPaths == null || (savedPaths.isEmpty) ? [RepositoryPathNotifier.fromModel(defaultRepositoryPathModel)] : savedPaths;
      installationPathController.text = value.installationPath ?? Directory.current.path;
      settings = value;
    });
  }

  final service = GetIt.I<KaraokeApiService>();

  var settings = const SettingsModel();

  final TextEditingController downloadsPathController = TextEditingController();
  final ValueNotifier<List<RepositoryPathNotifier>> pathsController = ValueNotifier([]);
  final TextEditingController installationPathController = TextEditingController();

  Future<SettingsModel> readSettings() async {
    final settingsFile = File('settings.json');
    if (await settingsFile.exists()) {
      final settingsJson = await settingsFile.readAsString();
      final settings = SettingsModel.fromJson(jsonDecode(settingsJson));
      return settings;
    } else {
      return const SettingsModel();
    }
  }

  Future<void> saveSettings(SettingsModel settings) async {
    final settingsFile = File('settings.json');
    await settingsFile.writeAsString(jsonEncode(settings.toJson()));
  }

  Future<void> setDownloadsPath(String path) async {
    downloadsPathController.text = path;
    await service.setDownloadsPath(path);
    var settingsModel = settings.copyWith(downloadsPath: path);
    await saveSettings(settings);
    settings = settingsModel;
  }

  Future<void> setInstallationPath(String path) async {
    installationPathController.text = path;
    var settingsModel = settings.copyWith(installationPath: path);
    await saveSettings(settings);
    settings = settingsModel;
  }

  Future<void> setPaths() async {
    final paths = pathsController.value.map((e) => e.toModel()).toList();

    await service.setPaths(paths);
    var settingsModel = settings.copyWith(paths: paths);
    await saveSettings(settings);
    settings = settingsModel;
  }

  Future<void> saveAll() async {
    print('Saving settings');
    print('Service configs = ${service.configuration.baseUrl}:${service.configuration.port}');
    final downloadsPath = settings.downloadsPath;
    if (downloadsPath != null) await service.setDownloadsPath(downloadsPath);
    final paths = settings.paths;
    if (paths != null) await service.setPaths(paths);
    final settingsFile = File('settings.json');
    await settingsFile.writeAsString(jsonEncode(settings.toJson()));
  }
}
