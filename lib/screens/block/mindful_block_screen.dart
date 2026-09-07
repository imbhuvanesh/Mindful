import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zo_app_blocker/zo_app_blocker.dart';

import '../../theme/colors.dart';
import '../../screens/splash_screen.dart';
import '../../widgets/glass_background.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_card.dart';

@pragma('vm:entry-point')
void onBlockScreenRequested() {
  ZoBlockScreenRunner.run(builder: (ctx) => _BlockScreen(body: ctx));
}

class _BlockScreen extends StatefulWidget {
  const _BlockScreen({required this.body});
  final BlockScreenContext body;

  @override
  State<_BlockScreen> createState() => _BlockScreenState();
}

class _BlockScreenState extends State<_BlockScreen> {
  Timer? _revealTimer;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    // Truly full screen: hide status + navigation bars.
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));

    // Fallback so the preloader is never stuck if the icon never arrives.
    _revealTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _revealed = true);
    });
  }

  @override
  void didUpdateWidget(covariant _BlockScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Icon/name arrived via the two-phase update — reveal immediately.
    if (_hasData && !_revealed && mounted) {
      setState(() => _revealed = true);
    }
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  bool get _hasData =>
      widget.body.appName != null || widget.body.appIcon != null;

  @override
  Widget build(BuildContext context) {
    if (!_revealed && !_hasData) {
      return const MindfulSplashScreen();
    }

    final app = widget.body.appName ?? 'this app';
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: MindfulColors.black,
        colorScheme: const ColorScheme.dark(
          primary: MindfulColors.white,
          onPrimary: MindfulColors.black,
          surface: MindfulColors.black,
          onSurface: MindfulColors.white,
        ),
      ),
      home: Scaffold(
        backgroundColor: MindfulColors.black,
        body: GlassBackground(
          child: Padding(
            padding:
                EdgeInsets.fromLTRB(32, topInset + 16, 32, bottomInset + 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'MINDFUL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: MindfulColors.mist,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                  ),
                ),
                const Spacer(flex: 2),
                Center(
                  child: GlassCard(
                    borderRadius: 28,
                    padding: const EdgeInsets.all(0),
                    child: appIcon(),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '$app is locked for now',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    color: MindfulColors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This app is taking a one-hour pause. Mindful unlocks it '
                  'automatically when the time is up — this little break is '
                  'yours. Take a breath, look up, come back to your day.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: MindfulColors.gray,
                  ),
                ),
                const Spacer(flex: 3),
                GlassButton(
                  onPressed: widget.body.onDismiss,
                  child: const Text(
                    'Back to my day',
                    style: TextStyle(
                      color: MindfulColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget appIcon() {
    if (widget.body.appIcon != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.memory(widget.body.appIcon!, width: 96, height: 96),
      );
    }
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: MindfulColors.glassFill,
      ),
      child: const Icon(
        Icons.lock_outline,
        size: 46,
        color: MindfulColors.white,
      ),
    );
  }
}