/// Represents the current state of the video scanning process.
enum ScanState {
  idle,       // no scan in progress
  scanning,   // actively scanning directories
  done,       // scan completed successfully
  empty,      // scan completed but no videos found
  error,      // scan encountered an error
}
