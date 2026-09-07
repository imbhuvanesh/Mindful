import 'package:flutter/material.dart';

import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'services/lock_service.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MindfulApp());
  // Don't await here: the splash screen is shown until init finishes and the
  // service notifies listeners.
  LockService.instance.init();
}

class MindfulApp extends StatelessWidget {
  const MindfulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mindful',
      debugShowCheckedModeBanner: false,
      theme: MindfulTheme.dark(),
      home: const _Root(),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> with WidgetsBindingObserver {
  bool _splashDone = false;

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
    // Replay the full-screen splash every time the app comes back to the
    // foreground (home press → return, app switch, etc.).
    if (state == AppLifecycleState.resumed && _splashDone) {
      setState(() => _splashDone = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LockService.instance,
      builder: (context, _) {
        final ready = _splashDone && LockService.instance.ready;
        return ready
            ? const MainShell()
            : MindfulSplashScreen(
                onDone: () {
                  if (mounted) setState(() => _splashDone = true);
                },
              );
      },
    );
  }
}