import 'package:flutter/foundation.dart';

import '../models/video_item.dart';
import '../models/scan_state.dart';
import '../services/file_scanner.dart';
import '../services/storage_service.dart';
import '../utils/random_utils.dart';

/// Manages the video library: scanning, lazy loading, playback history.
class VideoProvider extends ChangeNotifier {
  final FileScanner _scanner;
  final StorageService _storage;
  final RandomPicker _picker = RandomPicker(windowSize: 20);

  List<VideoItem> _allVideos = [];
  final List<VideoItem> _history = []; // stack: most recent = last
  VideoItem? _current;
  ScanState _scanState = ScanState.idle;
  String? _scanError;
  int _scanningCount = 0;
  String? _currentScanningFolder;
  double _scanPercent = 0.0;

  VideoProvider(this._scanner, this._storage) {
    _loadFromCache();
    _setupProgress();
  }

  void _loadFromCache() {
    final cached = _storage.getCachedVideos();
    if (cached.isNotEmpty) {
      _allVideos = cached;
      _scanState = ScanState.done;
    }
  }

  void _setupProgress() {
    _scanner.onProgress = (count, folder) {
      _scanningCount = count;
      if (folder != null) _currentScanningFolder = folder;
      notifyListeners();
    };
  }

  // ---- getters ----

  List<VideoItem> get allVideos => List.unmodifiable(_allVideos);
  VideoItem? get current => _current;
  bool get hasHistory => _history.isNotEmpty;
  int get totalCount => _allVideos.length;
  ScanState get scanState => _scanState;
  String? get scanError => _scanError;
  bool get isEmpty => _allVideos.isEmpty;
  int get scanningCount => _scanningCount;
  String? get currentScanningFolder => _currentScanningFolder;
  double get scanPercent => _scanPercent;

  // ---- scanning ----

  /// Directly insert already-scanned files (from pickAndScan).
  void addScannedFiles(List<VideoItem> files) {
    _allVideos.addAll(files);
    _allVideos.shuffle(); // Shuffle to ensure global random even on first add
    _scanState = _allVideos.isEmpty ? ScanState.empty : ScanState.done;
    _storage.setCachedVideos(_allVideos);
    _picker.clear();
    notifyListeners();
  }

  /// Scans all configured folders. Call this manually (refresh).
  Future<void> scan(List<String> folderUris) async {
    // If we have videos, don't show "scanning" state to avoid blocking UI with a loader
    if (_allVideos.isEmpty) {
      _scanState = ScanState.scanning;
    }
    _scanError = null;
    _scanningCount = 0;
    _scanPercent = 0.0;
    _currentScanningFolder = '准备中...';
    notifyListeners();

    try {
      final oldMap = {for (var v in _allVideos) v.uri: v};
      final results = <VideoItem>[];
      bool somePermissionsLost = false;

      for (int i = 0; i < folderUris.length; i++) {
        _scanPercent = i / folderUris.length;
        notifyListeners();
        
        try {
          final videos = await _scanner.scan(folderUris[i]);
          for (var v in videos) {
            // Incremental sync: reuse duration if file hasn't changed
            final old = oldMap[v.uri];
            if (old != null && old.lastModified == v.lastModified) {
              v.duration = old.duration;
            }
          }
          results.addAll(videos);
        } catch (e) {
          if (e.toString().contains('PERMISSION_LOST')) {
            somePermissionsLost = true;
          } else {
            rethrow;
          }
        }
      }

      _allVideos = results;
      _allVideos.shuffle(); // Shuffle globally to break directory-based ordering
      
      _scanState = results.isEmpty ? ScanState.empty : ScanState.done;
      _scanPercent = 1.0;
      _currentScanningFolder = null;
      _scanningCount = 0;
      _storage.setCachedVideos(_allVideos);

      // Reset picker and history since the library has changed significantly
      _picker.clear();
      _history.clear();

      if (somePermissionsLost) {
        _scanError = '部分文件夹权限已失效，请重新添加。';
        // We don't set ScanState.error here because we might still have other videos to show
      }
    } catch (e) {
      if (_allVideos.isEmpty) {
        _scanError = e.toString();
        _scanState = ScanState.error;
      }
    }
    notifyListeners();
  }

  // ---- playback navigation ----

  /// Pick a random video and set it as current.
  /// Returns `true` if a video was picked, `false` if library is empty.
  bool playRandom() {
    if (_allVideos.isEmpty) return false;
    final next = _picker.pick(_allVideos);
    if (_current != null) {
      _history.add(_current!);
    }
    _current = next;
    notifyListeners();
    return true;
  }

  /// Move to the next video.
  /// If [autoPick] is true, picks randomly; otherwise picks sequential.
  bool playNext({bool autoPick = false}) {
    if (_allVideos.isEmpty) return false;
    VideoItem next;
    if (autoPick) {
      next = _picker.pick(_allVideos);
    } else {
      final idx = _allVideos.indexOf(_current!);
      final nextIdx = (idx + 1) % _allVideos.length;
      next = _allVideos[nextIdx];
    }
    if (_current != null) {
      _history.add(_current!);
    }
    _current = next;
    notifyListeners();
    return true;
  }

  /// Go back to the previous video from history.
  /// Returns `null` if history is empty.
  VideoItem? playPrevious() {
    if (_history.isEmpty) return null;
    _current = _history.removeLast();
    notifyListeners();
    return _current;
  }

  /// Reset state: clear history, current, picker; play a random new video.
  bool resetAndPlayRandom() {
    _history.clear();
    _picker.clear();
    _current = null;
    return playRandom();
  }

  /// Remove a video from the library (if its folder was removed).
  void removeByFolder(String folderUri) {
    _allVideos.removeWhere((v) => v.folder == folderUri);
    _history.removeWhere((v) => v.folder == folderUri);
    _picker.forget(folderUri);
    if (_current != null && _current!.folder == folderUri) {
      _current = null;
    }
    _scanState = _allVideos.isEmpty ? ScanState.empty : ScanState.done;
    notifyListeners();
  }

  /// Permanently delete a video from disk and the library.
  Future<bool> deleteVideo(VideoItem video) async {
    try {
      final bool? success = await _scanner.deleteFile(video.uri);
      if (success == true) {
        _allVideos.removeWhere((v) => v.uri == video.uri);
        _history.removeWhere((v) => v.uri == video.uri);
        _picker.forget(video.uri);
        _storage.setCachedVideos(_allVideos);
        if (_current?.uri == video.uri) {
          _current = null;
        }
        _scanState = _allVideos.isEmpty ? ScanState.empty : ScanState.done;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Delete failed: $e');
      return false;
    }
  }
}
