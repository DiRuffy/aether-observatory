import 'package:material_ui/material_ui.dart';

import '../scene/atmosphere_presets.dart';
import '../scene/observatory_world.dart';
import 'glass_surface.dart';

/// Top-left title badge & live performance/quality telemetry strip.
class TelemetryBadge extends StatelessWidget {
  const TelemetryBadge({super.key, required this.world});

  final ObservatoryWorld world;

  @override
  Widget build(BuildContext context) {
    final accent = world.mood.accentColor;
    final fpsColor = world.fps >= 50
        ? const Color(0xFF6EF5B5)
        : world.fps >= 30
            ? const Color(0xFFF6C46D)
            : const Color(0xFFFF6E7F);
    final isCompact = MediaQuery.sizeOf(context).width < 680;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassSurface(
          accentColor: accent,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16,
            vertical: isCompact ? 10 : 12,
          ),
          borderRadius: BorderRadius.circular(18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.85),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'AETHER OBSERVATORY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCompact ? world.mood.label : world.mood.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GlassSurface(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          borderRadius: BorderRadius.circular(14),
          opacity: 0.48,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: fpsColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${world.fps.round()} FPS',
                    style: TextStyle(
                      color: fpsColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${world.frameMs.toStringAsFixed(1)} ms',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 10.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              if (!isCompact)
                Container(
                  width: 1,
                  height: 12,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              if (!isCompact)
                Text(
                  world.backendLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 10.5,
                    letterSpacing: 0.4,
                  ),
                ),
              Container(
                width: 1,
                height: 12,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: QualityTier.values.map((tier) {
                  final active = world.quality == tier;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () => world.setQuality(tier),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: active
                              ? accent.withValues(alpha: 0.24)
                              : Colors.transparent,
                          border: Border.all(
                            color: active
                                ? accent.withValues(alpha: 0.65)
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          tier == QualityTier.performance ? 'Perf' : tier.label,
                          style: TextStyle(
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.55),
                            fontSize: 10.5,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
