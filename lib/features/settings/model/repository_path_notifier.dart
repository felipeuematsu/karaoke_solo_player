import 'package:flutter/foundation.dart';
import 'package:karaoke_request_api/karaoke_request_api.dart';

class RepositoryPathNotifier extends ChangeNotifier implements ValueListenable<RepositoryPathModel> {
  RepositoryPathNotifier.fromModel(RepositoryPathModel model)
      : _path = model.path,
        _regex = model.regex,
        _titlePos = model.titlePos,
        _artistPos = model.artistPos;

  String _path;
  String _regex;
  int _titlePos;
  int _artistPos;

  String get path => _path;

  set path(String value) {
    if (value == path) return;
    _path = value;
    notifyListeners();
  }

  String get regex => _regex;

  set regex(String value) {
    if (value == regex) return;
    _regex = value;
    notifyListeners();
  }

  int get titlePos => _titlePos;

  set titlePos(int value) {
    if (value == titlePos) return;
    _titlePos = value;
    notifyListeners();
  }

  int get artistPos => _artistPos;

  set artistPos(int value) {
    if (value == artistPos) return;
    _artistPos = value;
    notifyListeners();
  }

  RepositoryPathModel toModel() {
    return RepositoryPathModel(
      path: path,
      regex: regex,
      titlePos: titlePos,
      artistPos: artistPos,
    );
  }

  @override
  RepositoryPathModel get value => toModel();
}
