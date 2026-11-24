import 'package:material_ui/material_ui.dart';

import '../scene/atmosphere_presets.dart';
import '../scene/observatory_world.dart';
import 'glass_surface.dart';

/// Floating bottom glassmorphic dock for Mood switching, Aether Surge, camera
/// presets, auto-tour, and toggling the Studio Inspector.
class MoodSwitcherBar extends StatelessWidget {
  const MoodSwitcherBar({
    super.key,
    required this.world,
    required this.inspectorOpen,
    required this.onToggleInspector,
    required this.onToggleHud,
  });

  final ObservatoryWorld world;
  final bool inspectorOpen;
  final VoidCallback onToggleInspector;
  final VoidCallback onToggleHud;

  @override
  Widget build(BuildContext context) {
    final accent = world.mood.accentColor;
    final isCompact = MediaQuery.sizeOf(context).width < 760;

    return GlassSurface(
      accentColor: accent,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 8 : 9,
      ),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.62,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 4 Mood Presets.
            for (final mood in ObservatoryMood.values) ...[
              _MoodPill(
                mood: mood,
                selected: world.mood == mood,
                compact: isCompact,
                onTap: () => world.selectMood(mood),
              ),
              const SizedBox(width: 6),
            ],

            _VerticalDivider(),
            const SizedBox(width: 8),

            // Signature Aether Surge button.
            _SurgeButton(
              accent: accent,
              surging: world.surgeEnergy > 0.15,
              compact: isCompact,
              onPressed: () => world.triggerSurge(),
            ),
            const SizedBox(width: 8),

            _VerticalDivider(),
            const SizedBox(width: 6),

            // Auto-Tour toggle.
            _IconActionChip(
              icon: world.autoTour
                  ? Icons.pause_circle_outline_rounded
                  : Icons.play_circle_outline_rounded,
              tooltip: world.autoTour ? 'Pause Auto-Tour (T)' : 'Auto-Tour (T)',
              active: world.autoTour,
              accent: accent,
              onTap: () => world.setAutoTour(!world.autoTour),
            ),
            const SizedBox(width: 4),

            // Camera angle bookmarks popup.
            PopupMenuButton<CameraPreset>(
              tooltip: 'Camera Angles',
              color: const Color(0xFF0C1220),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              onSelected: world.selectCameraPreset,
              itemBuilder: (context) => [
                for (final preset in CameraPreset.values)
                  PopupMenuItem<CameraPreset>(
                    value: preset,
                    child: Row(
                      children: [
                        Icon(
                          Icons.videocam_outlined,
                          size: 16,
                          color: world.activeCameraPreset == preset
                              ? accent
                              : Colors.white70,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          preset.label,
                          style: TextStyle(
                            color: world.activeCameraPreset == preset
                                ? Colors.white
                                : Colors.white70,
                            fontSize: 13,
                            fontWeight: world.activeCameraPreset == preset
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.videocam_outlined,
                  size: 19,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Studio Inspector drawer toggle.
            _IconActionChip(
              icon: Icons.tune_rounded,
              tooltip: 'Studio Inspector (I)',
              active: inspectorOpen,
              accent: accent,
              onTap: onToggleInspector,
            ),
            const SizedBox(width: 4),

            // Hide HUD for pure full-screen 3D eye candy.
            _IconActionChip(
              icon: Icons.visibility_off_outlined,
              tooltip: 'Hide HUD (H)',
              active: false,
              accent: accent,
              onTap: onToggleHud,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodPill extends StatelessWidget {
  const _MoodPill({
    required this.mood,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final ObservatoryMood mood;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = mood.accentColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 13,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? accent.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.82)
                  : Colors.white.withValues(alpha: 0.08),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.8),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                compact ? mood.label.split(' ').first : mood.label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurgeButton extends StatelessWidget {
  const _SurgeButton({
    required this.accent,
    required this.surging,
    required this.compact,
    required this.onPressed,
  });

  final Color accent;
  final bool surging;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: surging ? 0.95 : 0.78),
                const Color(0xFF42E8FF).withValues(alpha: surging ? 0.95 : 0.72),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: surging ? 0.7 : 0.35),
                blurRadius: surging ? 22 : 12,
                spreadRadius: surging ? 1 : -2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bolt_rounded,
                size: 16,
                color: Color(0xFF060911),
              ),
              const SizedBox(width: 5),
              Text(
                compact ? 'SURGE' : 'AETHER SURGE',
                style: const TextStyle(
                  color: Color(0xFF060911),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconActionChip extends StatelessWidget {
  const _IconActionChip({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: active
                ? accent.withValues(alpha: 0.24)
                : Colors.transparent,
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: 0.65)
                  : Colors.transparent,
            ),
          ),
          child: Icon(
            icon,
            size: 19,
            color: active
                ? Colors.white
                : Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      color: Colors.white.withValues(alpha: 0.14),
    );
  }
}
