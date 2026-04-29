import 'package:flutter/material.dart';

/// Displayed on the home screen when no folders have been configured.
class EmptyGuide extends StatelessWidget {
  final VoidCallback onGoToSettings;

  const EmptyGuide({super.key, required this.onGoToSettings});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_library_outlined,
                size: 72, color: Colors.white30),
            const SizedBox(height: 24),
            const Text(
              '还没有视频',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 12),
            const Text(
              '添加本地文件夹来开始使用 LeoTok',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onGoToSettings,
              icon: const Icon(Icons.add),
              label: const Text('添加文件夹'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
