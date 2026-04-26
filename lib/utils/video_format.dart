/// Supported video extensions for scanning.
const supportedExtensions = {'.mp4', '.mkv', '.webm'};

bool isSupportedVideo(String fileName) {
  final lower = fileName.toLowerCase();
  return supportedExtensions.any((ext) => lower.endsWith(ext));
}
