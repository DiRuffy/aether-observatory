import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

/// Frosted obsidian glass container used across the Observatory Studio HUD.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.accentColor,
    this.blurSigma = 16.0,
    this.opacity = 0.56,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? accentColor;
  final double blurSigma;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final borderColor = accentColor != null
        ? accentColor!.withValues(alpha: 0.34)
        : Colors.white.withValues(alpha: 0.13);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: const Color(0xFF070B14).withValues(alpha: opacity),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              if (accentColor != null)
                BoxShadow(
                  color: accentColor!.withValues(alpha: 0.10),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
