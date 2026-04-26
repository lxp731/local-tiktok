/// A video item scanned from the local filesystem via SAF.
class VideoItem {
  final String uri;      // content:// URI from SAF
  final String name;     // display file name
  final String folder;   // parent folder tree URI (for reference)
  final int? sizeBytes;  // file size, may be unknown from SAF
  final int? lastModified; // unix timestamp in ms
  Duration? duration;    // populated after player initializes

  VideoItem({
    required this.uri,
    required this.name,
    required this.folder,
    this.sizeBytes,
    this.lastModified,
    this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'uri': uri,
      'name': name,
      'folder': folder,
      'sizeBytes': sizeBytes,
      'lastModified': lastModified,
      'durationMs': duration?.inMilliseconds,
    };
  }

  factory VideoItem.fromMap(Map<String, dynamic> map) {
    return VideoItem(
      uri: map['uri'] as String,
      name: map['name'] as String,
      folder: map['folder'] as String,
      sizeBytes: map['sizeBytes'] as int?,
      lastModified: map['lastModified'] as int?,
      duration: map['durationMs'] != null
          ? Duration(milliseconds: map['durationMs'] as int)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VideoItem && other.uri == uri;

  @override
  int get hashCode => uri.hashCode;

  @override
  String toString() => 'VideoItem($name, $uri)';
}
