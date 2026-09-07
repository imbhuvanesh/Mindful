import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../widgets/glass_background.dart';

/// Branded preloader: reveals "MINDFUL" one letter at a time, then fills a
/// progress bar before handing off to the app ([onDone]).
///
/// Runs full-screen (system bars hidden while visible) every time the app is
/// opened.
class MindfulSplashScreen extends StatefulWidget {
  const MindfulSplashScreen({
    super.key,
    this.onDone,
    this.manageSystemUi = true,
  });

  final VoidCallback? onDone;

  /// Whether this splash manages the system bars (hides them while visible,
  /// restores them when gone). Pass `false` when embedding the splash inside
  /// another full-screen view (e.g. the block alert) that owns its own bars.
  final bool manageSystemUi;

  @override
  State<MindfulSplashScreen> createState() => _MindfulSplashScreenState();
}

class _MindfulSplashScreenState extends State<MindfulSplashScreen>
    with SingleTickerProviderStateMixin {
  static const _word = 'MINDFUL';
  // Each letter animates over 0.17 of the timeline, staggered by 0.085,
  // so the last letter settles at exactly 0.68.
  static const _step = 0.085;
  static const _len = 0.17;
  static const _revealEnd = _step * (_word.length - 1) + _len;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Future<void>.delayed(
            const Duration(milliseconds: 150),
            widget.onDone,
          );
        }
      });
    _controller.forward();

    // Full screen: hide the status + navigation bars while the splash is up.
    if (widget.manageSystemUi) {
      unawaited(
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    // Restore the system bars for the main app.
    if (widget.manageSystemUi) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MindfulColors.black,
      body: GlassBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 72,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < _word.length; i++) _letter(i),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 160,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final v = _controller.value;
                    final progress =
                        ((v - _revealEnd) / (1.0 - _revealEnd)).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: v >= _revealEnd ? 1.0 : 0.0,
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        color: MindfulColors.white,
                        backgroundColor: MindfulColors.glassFill,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _letter(int index) {
    final anim = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        index * _step,
        index * _step + _len,
        curve: Curves.easeOutCubic,
      ),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) => Transform.translate(
        offset: Offset(0, (1.0 - anim.value) * 26),
        child: Opacity(
          opacity: anim.value,
          child: Text(
            _word[index],
            style: const TextStyle(
              color: MindfulColors.white,
              fontSize: 46,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
            ),
          ),
        ),
      ),
    );
  }
}