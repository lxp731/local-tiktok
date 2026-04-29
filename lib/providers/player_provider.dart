import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Manages the active VideoPlayerController pool.
///
/// Maintains up to 3 controllers (prev / current / next) to avoid
/// black frames during swipe transitions.
class PlayerProvider extends ChangeNotifier {
  VideoPlayerController? _currentController;
  VideoPlayerController? _prevController;
  VideoPlayerController? _nextController;

  bool _isPlaying = false;
  bool _isInitialized = false;

  // ---- getters ----

  VideoPlayerController? get current => _currentController;
  VideoPlayerController? get prev => _prevController;
  VideoPlayerController? get next => _nextController;
  bool get isPlaying => _isPlaying;
  bool get isInitialized => _isInitialized;

  // ---- lifecycle ----

  /// Set a new current video.
  Future<void> loadCurrent(String uri, {double speed = 1.0}) async {
    final oldController = _currentController;
    _isFinished = false; // Reset finished state for new video
    
    // 1. Get/Create new controller
    final newController = _getOrCreate(uri);
    
    // 2. If switching to a DIFFERENT controller, cleanup the old one
    if (oldController != null && oldController != newController) {
      oldController.removeListener(_onListener);
      await oldController.pause();
    }

    _currentController = newController;
    
    // 3. Ensure we don't have duplicate listeners on the current controller
    _currentController!.removeListener(_onListener);
    _currentController!.addListener(_onListener);
    
    _isInitialized = _currentController!.value.isInitialized;
    _isPlaying = _currentController!.value.isPlaying;
    notifyListeners();

    if (!_isInitialized) {
      try {
        await _currentController!.initialize();
        _isInitialized = true;
        await _currentController!.play();
        _currentController!.setLooping(true); // Loop by default
        await _currentController!.setPlaybackSpeed(speed);
        notifyListeners();
      } catch (e) {
        debugPrint('Failed to initialize video: $uri — $e');
        rethrow;
      }
    } else {
      // Already initialized (from cache)
      await _currentController!.setPlaybackSpeed(speed);
      await _currentController!.play();
      notifyListeners();
    }
  }

  void _onListener() {
    if (_currentController == null) return;
    
    final value = _currentController!.value;
    
    // Update playing state
    final wasPlaying = _isPlaying;
    _isPlaying = value.isPlaying;
    
    // Check if finished with 50ms buffer
    final isAtEnd = _isInitialized && 
                   !value.isLooping && 
                   value.position >= (value.duration - const Duration(milliseconds: 50)) && 
                   value.duration > Duration.zero;

    if (isAtEnd && !value.isPlaying) {
      _isFinished = true;
    } else {
      _isFinished = false;
    }

    if (wasPlaying != _isPlaying || _isFinished) {
      notifyListeners();
    }
  }

  bool _isFinished = false;
  bool get isFinished => _isFinished;

  // ---- playback controls ----

  Future<void> togglePlayPause() async {
    if (_currentController == null || !_isInitialized) return;
    if (_currentController!.value.isPlaying) {
      await _currentController!.pause();
    } else {
      await _currentController!.play();
    }
    // _isPlaying will be updated by _onListener
  }

  Future<void> pause() async {
    if (_currentController == null) return;
    await _currentController!.pause();
  }

  Future<void> resume() async {
    if (_currentController == null) return;
    await _currentController!.play();
  }

  Future<void> setSpeed(double speed) async {
    await _currentController?.setPlaybackSpeed(speed);
    notifyListeners();
  }

  Future<void> seekTo(Duration position) async {
    await _currentController?.seekTo(position);
  }

  Future<void> stopAndClear() async {
    _currentController?.removeListener(_onListener);
    await _currentController?.pause();
    
    for (final c in _controllerCache.values) {
      await c.pause();
      await c.dispose();
    }
    _controllerCache.clear();
    _currentController = null;
    _prevController = null;
    _nextController = null;
    _isPlaying = false;
    _isInitialized = false;
    _isFinished = false;
    notifyListeners();
  }

  // ---- internal pool ----

  final Map<String, VideoPlayerController> _controllerCache = {};

  VideoPlayerController _getOrCreate(String uri) {
    if (_controllerCache.containsKey(uri)) {
      return _controllerCache[uri]!;
    }
    // Removed mixWithOthers: true to maintain primary audio focus
    final c = VideoPlayerController.contentUri(Uri.parse(uri));
    _controllerCache[uri] = c;
    // Keep cache size bounded
    while (_controllerCache.length > 3) {
      final oldest = _controllerCache.keys.first;
      _controllerCache.remove(oldest)?.dispose();
    }
    return c;
  }

  // ---- cleanup ----

  @override
  void dispose() {
    _currentController?.removeListener(_onListener);
    for (final c in _controllerCache.values) {
      c.dispose();
    }
    _controllerCache.clear();
    super.dispose();
  }
}
