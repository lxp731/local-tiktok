import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_item.dart';

/// Thin wrapper around SharedPreferences for LocalTok settings.
///
/// Keys managed:
/// - `folder_uris`       : comma-separated SAF tree URIs
/// - `auto_play_enabled` : bool
/// - `playback_speed`    : double (1.0, 1.5, 2.0)
/// - `video_cache`       : list of JSON strings representing VideoItems
class StorageService {
  static const _keyFolders = 'folder_uris';
  static const _keyAutoPlay = 'auto_play_enabled';
  static const _keySpeed = 'playback_speed';
  static const _keyVideoCache = 'video_cache';

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ---- folder URIs ----

  List<String> getFolderUris() {
    return _prefs.getStringList(_keyFolders) ?? [];
  }

  Future<bool> addFolderUri(String uri) async {
    final list = getFolderUris();
    if (list.contains(uri)) return false;       // already present
    list.add(uri);
    return _prefs.setStringList(_keyFolders, list);
  }

  Future<bool> removeFolderUri(String uri) async {
    final list = getFolderUris();
    list.remove(uri);
    return _prefs.setStringList(_keyFolders, list);
  }

  // ---- auto-play ----

  bool getAutoPlayEnabled() => _prefs.getBool(_keyAutoPlay) ?? false;

  Future<bool> setAutoPlayEnabled(bool value) =>
      _prefs.setBool(_keyAutoPlay, value);

  // ---- playback speed ----

  double getPlaybackSpeed() => _prefs.getDouble(_keySpeed) ?? 1.0;

  Future<bool> setPlaybackSpeed(double speed) =>
      _prefs.setDouble(_keySpeed, speed);

  // ---- video cache ----

  List<VideoItem> getCachedVideos() {
    final list = _prefs.getStringList(_keyVideoCache) ?? [];
    return list.map((s) {
      try {
        return VideoItem.fromMap(jsonDecode(s) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<VideoItem>().toList();
  }

  Future<bool> setCachedVideos(List<VideoItem> videos) {
    final list = videos.map((v) => jsonEncode(v.toMap())).toList();
    return _prefs.setStringList(_keyVideoCache, list);
  }
}

