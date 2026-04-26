import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/player_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/video_provider.dart';
import 'services/file_scanner.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init services
  final storage = StorageService();
  await storage.init();
  final scanner = FileScanner();

  // Build providers
  final settings = SettingsProvider(storage);
  final video = VideoProvider(scanner, storage);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: video),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ],
      child: const _AppLifecycleWrapper(child: LocalTokApp()),
    ),
  );
}

/// Listens to app lifecycle events to pause/resume playback.
class _AppLifecycleWrapper extends StatefulWidget {
  final Widget child;
  const _AppLifecycleWrapper({required this.child});

  @override
  State<_AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<_AppLifecycleWrapper>
    with WidgetsBindingObserver {
  bool _wasPlayingBeforeBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    final player = context.read<PlayerProvider>();
    if (state == AppLifecycleState.paused) {
      _wasPlayingBeforeBackground = player.isPlaying;
      player.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_wasPlayingBeforeBackground) {
        player.resume();
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
