import 'package:flutter/services.dart';

import '../models/video_item.dart';

/// SAF-based file scanner using Android's DocumentFile API via MethodChannel.
///
/// On Android 10+ with scoped storage, direct filesystem access via [Directory]
/// does NOT work. This service goes through the platform's DocumentFile API
/// which respects SAF (Storage Access Framework) permissions.
class FileScanner {
  static const _channel = MethodChannel('com.localtok.local_tok/saf');

  Function(int count, String? currentFolder)? onProgress;

  FileScanner() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onProgress') {
        final count = call.arguments['count'] as int;
        final folder = call.arguments['currentFolder'] as String?;
        onProgress?.call(count, folder);
      }
    });
  }

  /// Open the system folder picker and scan the selected tree.
  ///
  /// Returns `PickResult` with the tree URI and all discovered video files,
  /// or `null` if the user cancelled the picker.
  Future<PickResult?> pickAndScan() async {
    final raw = await _channel.invokeMethod('pickAndScan');
    if (raw == null) return null;

    final map = Map<String, dynamic>.from(raw as Map);
    final treeUri = map['treeUri'] as String;
    final files = _parseFiles(map['files'] as List, treeUri);

    return PickResult(treeUri: treeUri, files: files);
  }

  /// Re-scan an already-known folder tree URI.
  Future<List<VideoItem>> scan(String treeUri) async {
    final raw = await _channel.invokeMethod('scan', {'treeUri': treeUri});
    return _parseFiles(raw as List, treeUri);
  }

  List<VideoItem> _parseFiles(List raw, String treeUri) {
    return raw.map((item) {
      final map = Map<String, dynamic>.from(item);
      return VideoItem(
        uri: map['uri'] as String,
        name: map['name'] as String,
        folder: map['folderTreeUri'] as String? ?? treeUri,
        lastModified: map['lastModified'] as int?,
        sizeBytes: map['size'] as int?,
      );
    }).toList();
  }
}

/// Result of a single pick-and-scan operation.
class PickResult {
  final String treeUri;
  final List<VideoItem> files;

  PickResult({required this.treeUri, required this.files});
}
