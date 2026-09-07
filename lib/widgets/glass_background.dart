import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Black background with soft white glow blobs, so frosted-glass surfaces
/// have something to diffuse. Wrap every page in this.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _Backdrop(),
        child,
      ],
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          children: [
            const ColoredBox(color: MindfulColors.black),
            Positioned(
              top: -w * 0.25,
              right: -w * 0.25,
              child: _Glow(size: w, color: MindfulColors.glassStrong),
            ),
            Positioned(
              bottom: h * 0.2,
              left: -w * 0.3,
              child: _Glow(size: w * 0.9, color: MindfulColors.glassFill),
            ),
            Positioned(
              top: h * 0.45,
              right: -w * 0.15,
              child: _Glow(size: w * 0.7, color: MindfulColors.glassFill),
            ),
          ],
        );
      },
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: color.a * 0.5),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}