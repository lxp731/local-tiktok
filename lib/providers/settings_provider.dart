import 'package:flutter/foundation.dart';

import 'package:package_info_plus/package_info_plus.dart';
import '../services/audio_background_service.dart';
import '../services/storage_service.dart';

/// Manages persistent app settings and provides them reactively.
class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;

  List<String> _folderUris = [];
  bool _autoPlayEnabled = false;
  bool _screenOffListeningEnabled = false;
  int _screenOffTimerMinutes = 15;
  double _playbackSpeed = 1.0;
  String _appVersion = '1.0.0';

  SettingsProvider(this._storage) {
    _load();
  }

  Future<void> _load() async {
    _folderUris = _storage.getFolderUris();
    _autoPlayEnabled = _storage.getAutoPlayEnabled();
    _screenOffListeningEnabled = _storage.getScreenOffListeningEnabled();
    _screenOffTimerMinutes = _storage.getScreenOffTimerMinutes();
    _playbackSpeed = _storage.getPlaybackSpeed();
    
    final packageInfo = await PackageInfo.fromPlatform();
    _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    
    notifyListeners();
  }

  // ---- getters ----

  List<String> get folderUris => List.unmodifiable(_folderUris);
  bool get autoPlayEnabled => _autoPlayEnabled;
  bool get screenOffListeningEnabled => _screenOffListeningEnabled;
  int get screenOffTimerMinutes => _screenOffTimerMinutes;
  double get playbackSpeed => _playbackSpeed;
  bool get hasFolders => _folderUris.isNotEmpty;
  String get appVersion => _appVersion;

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

  /// Enable auto-play. Returns error message if blocked by screen-off listening.
  /// Caller should handle the returned message (null = success).
  Future<String?> setAutoPlayEnabled(bool value) async {
    if (value && _screenOffListeningEnabled) {
      return '请先关闭「熄屏听剧」，再开启「自动播放」';
    }
    _autoPlayEnabled = value;
    await _storage.setAutoPlayEnabled(value);
    notifyListeners();
    return null; // success
  }

  // ---- screen-off listening ----

  /// Enable screen-off listening. Returns error message if blocked by auto-play.
  /// Caller should handle the returned message (null = success).
  Future<String?> setScreenOffListeningEnabled(bool value) async {
    if (value && _autoPlayEnabled) {
      return '请先关闭「自动播放」，再开启「熄屏听剧」';
    }
    _screenOffListeningEnabled = value;
    await _storage.setScreenOffListeningEnabled(value);

    // Start/stop foreground service for background audio
    if (value) {
      AudioBackgroundService.start();
    } else {
      AudioBackgroundService.stop();
    }

    notifyListeners();
    return null; // success
  }

  Future<void> setScreenOffTimerMinutes(int minutes) async {
    final clamped = minutes.clamp(1, 30);
    _screenOffTimerMinutes = clamped;
    await _storage.setScreenOffTimerMinutes(clamped);
    notifyListeners();
  }

  // ---- playback speed ----

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _storage.setPlaybackSpeed(speed);
    notifyListeners();
  }
}
