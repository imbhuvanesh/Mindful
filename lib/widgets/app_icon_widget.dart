import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Shows an app icon from raw bytes, or a fallback letter circle.
class AppIconWidget extends StatelessWidget {
  const AppIconWidget({
    super.key,
    this.iconBytes,
    this.appName,
    this.size = 44,
    this.radius,
  });

  final Uint8List? iconBytes;
  final String? appName;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? size * 0.22;
    final hasIcon = iconBytes != null && iconBytes!.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: Container(
        width: size,
        height: size,
        color: MindfulColors.glassFill,
        child: hasIcon
            ? Image.memory(
                iconBytes!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder,
              )
            : _placeholder,
      ),
    );
  }

  Widget get _placeholder => Center(
        child: Text(
          _initials(appName),
          style: const TextStyle(
            color: MindfulColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      );

  static String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    return name.characters.first.toUpperCase();
  }
}