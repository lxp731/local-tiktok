import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'progress_bar.dart';

/// Displays a single video full-screen, with file name and progress bar.
class VideoPlayerWidget extends StatelessWidget {
  final VideoPlayerController controller;
  final String fileName;
  final bool showControls;
  final VoidCallback? onTap;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  const VideoPlayerWidget({
    super.key,
    required this.controller,
    required this.fileName,
    this.showControls = true,
    this.onTap,
    this.onDragStart,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final isLandscapeVideo = controller.value.aspectRatio > 1.0;
    final isDeviceLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),

          // Tap zone overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Colors.transparent),
            ),
          ),

          // Landscape Button (Center-Bottom)
          if (isLandscapeVideo && !isDeviceLandscape)
            Positioned(
              left: 0,
              right: 0,
              bottom: 120, // Positioned above the file name/progress bar
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.landscapeLeft,
                      DeviceOrientation.landscapeRight,
                    ]);
                    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.fullscreen, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '横屏播放',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // Exit Landscape Button (Top-Left)
          if (isDeviceLandscape)
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 30),
                onPressed: () {
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitUp,
                  ]);
                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                },
              ),
            ),

          // File name (bottom-left)
          if (showControls)
            Positioned(
              left: 16,
              bottom: 68,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  fileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          // Progress bar (bottom)
          if (showControls)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: VideoProgressBar(
                controller: controller,
                onDragStart: onDragStart,
                onDragEnd: onDragEnd,
              ),
            ),

          // Play/pause indicator (center, transient)
          if (!controller.value.isPlaying && showControls)
            const Center(
              child: Icon(
                Icons.play_arrow,
                size: 72,
                color: Colors.white54,
              ),
            ),
        ],
      ),
    );
  }
}
