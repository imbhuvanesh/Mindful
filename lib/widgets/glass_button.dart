import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// A frosted-glass tappable button (full-width by default).
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 54,
    this.borderRadius = 18,
    this.active = true,
  });

  final VoidCallback onPressed;
  final Widget child;
  final double height;
  final double borderRadius;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: MindfulColors.glassStrong,
          child: InkWell(
            onTap: active ? onPressed : null,
            child: SizedBox(
              width: double.infinity,
              height: height,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}