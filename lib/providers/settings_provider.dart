import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';

/// Manages persistent app settings and provides them reactively.
class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;

  List<String> _folderUris = [];
  bool _autoPlayEnabled = false;
  double _playbackSpeed = 1.0;

  SettingsProvider(this._storage) {
    _load();
  }

  void _load() {
    _folderUris = _storage.getFolderUris();
    _autoPlayEnabled = _storage.getAutoPlayEnabled();
    _playbackSpeed = _storage.getPlaybackSpeed();
    notifyListeners();
  }

  // ---- getters ----

  List<String> get folderUris => List.unmodifiable(_folderUris);
  bool get autoPlayEnabled => _autoPlayEnabled;
  double get playbackSpeed => _playbackSpeed;
  bool get hasFolders => _folderUris.isNotEmpty;

  // ---- folder management ----

  Future<bool> addFolder(String uri) async {
    final ok = await _storage.addFolderUri(uri);
    if (ok) {
      _folderUris = _storage.getFolderUris();
      notifyListeners();
    }
    return ok;
  }

  Future<void> removeFolder(String uri) async {
    await _storage.removeFolderUri(uri);
    _folderUris = _storage.getFolderUris();
    notifyListeners();
  }

  // ---- auto-play ----

  Future<void> setAutoPlayEnabled(bool value) async {
    _autoPlayEnabled = value;
    await _storage.setAutoPlayEnabled(value);
    notifyListeners();
  }

  // ---- playback speed ----

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _storage.setPlaybackSpeed(speed);
    notifyListeners();
  }
}
