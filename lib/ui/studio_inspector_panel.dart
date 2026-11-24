import 'package:material_ui/material_ui.dart';
import 'package:flutter_scene/scene.dart';

import '../scene/observatory_world.dart';
import 'glass_surface.dart';

/// Collapsible Studio Inspector panel exposing flutter_scene's live lighting,
/// post-processing stack, custom `.fmat` shader uniforms, and PBR parameters.
class StudioInspectorPanel extends StatelessWidget {
  const StudioInspectorPanel({
    super.key,
    required this.world,
    required this.onClose,
  });

  final ObservatoryWorld world;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final accent = world.mood.accentColor;

    return GlassSurface(
      accentColor: accent,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(20),
      opacity: 0.72,
      child: SizedBox(
        width: 316,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 17, color: accent),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'STUDIO INSPECTOR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.10)),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(label: 'ATMOSPHERE & KINETICS', accent: accent),
                    _LabeledSlider(
                      label: 'Sun Elevation',
                      valueLabel: '${world.sunElevationDeg.round()}°',
                      value: world.sunElevationDeg,
                      min: 3.0,
                      max: 78.0,
                      accent: accent,
                      onChanged: (v) => world.setSunAngles(elevationDeg: v),
                    ),
                    _LabeledSlider(
                      label: 'Sun Azimuth',
                      valueLabel: '${world.sunAzimuthDeg.round()}°',
                      value: world.sunAzimuthDeg,
                      min: -180.0,
                      max: 180.0,
                      accent: accent,
                      onChanged: (v) => world.setSunAngles(azimuthDeg: v),
                    ),
                    _LabeledSlider(
                      label: 'Kinetic Speed',
                      valueLabel: '${world.kineticSpeed.toStringAsFixed(1)}×',
                      value: world.kineticSpeed,
                      min: 0.0,
                      max: 2.5,
                      accent: accent,
                      onChanged: world.setKineticSpeed,
                    ),
                    _ToggleGrid(
                      accent: accent,
                      items: [
                        (
                          'Shadows',
                          world.shadowsEnabled,
                          world.setShadowsEnabled,
                        ),
                        (
                          'Planar Mirror',
                          world.planarReflectionsEnabled,
                          world.setPlanarReflectionsEnabled,
                        ),
                        (
                          'Volumetric Fog',
                          world.fogEnabled,
                          world.setFogEnabled,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _SectionHeader(label: 'POST-PROCESSING STACK', accent: accent),
                    const SizedBox(height: 4),
                    _ToneMapperSelector(
                      selected: world.toneMapping,
                      accent: accent,
                      onChanged: world.setToneMapping,
                    ),
                    const SizedBox(height: 8),
                    _LabeledSlider(
                      label: 'Exposure',
                      valueLabel: world.exposure.toStringAsFixed(2),
                      value: world.exposure,
                      min: 0.55,
                      max: 1.75,
                      accent: accent,
                      onChanged: world.setExposure,
                    ),
                    _LabeledSlider(
                      label: 'Bloom Strength',
                      valueLabel: world.bloomIntensity.toStringAsFixed(2),
                      value: world.bloomIntensity,
                      min: 0.0,
                      max: 0.75,
                      accent: accent,
                      onChanged: (v) => world.setBloom(enabled: v > 0.01, intensity: v),
                    ),
                    _ToggleGrid(
                      accent: accent,
                      items: [
                        (
                          'Bloom',
                          world.bloomEnabled,
                          (v) => world.setBloom(enabled: v),
                        ),
                        (
                          'Lens Flares',
                          world.lensFlareEnabled,
                          world.setLensFlareEnabled,
                        ),
                        (
                          'God Rays',
                          world.godRaysEnabled,
                          world.setGodRaysEnabled,
                        ),
                        (
                          'Ambient Occl.',
                          world.aoEnabled,
                          world.setAoEnabled,
                        ),
                        (
                          'SSR',
                          world.ssrEnabled,
                          world.setSsrEnabled,
                        ),
                        (
                          'Depth of Field',
                          world.depthOfFieldEnabled,
                          world.setDepthOfFieldEnabled,
                        ),
                        (
                          'Chromatic Ab.',
                          world.chromaticAberrationEnabled,
                          world.setChromaticAberrationEnabled,
                        ),
                        (
                          'Vignette',
                          world.vignetteEnabled,
                          world.setVignetteEnabled,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _SectionHeader(label: 'PBR & .FMAT SHADER CORE', accent: accent),
                    _LabeledSlider(
                      label: 'Ring Metallic',
                      valueLabel: world.metallic.toStringAsFixed(2),
                      value: world.metallic,
                      min: 0.0,
                      max: 1.0,
                      accent: accent,
                      onChanged: (v) => world.setMaterialOverrides(metallic: v),
                    ),
                    _LabeledSlider(
                      label: 'Ring Roughness',
                      valueLabel: world.roughness.toStringAsFixed(2),
                      value: world.roughness,
                      min: 0.05,
                      max: 0.85,
                      accent: accent,
                      onChanged: (v) => world.setMaterialOverrides(roughness: v),
                    ),
                    _LabeledSlider(
                      label: 'Core Plasma HDR',
                      valueLabel: world.coreGlow.toStringAsFixed(1),
                      value: world.coreGlow,
                      min: 0.6,
                      max: 5.0,
                      accent: accent,
                      onChanged: (v) => world.setMaterialOverrides(coreGlow: v),
                    ),
                    _LabeledSlider(
                      label: 'Iridescence',
                      valueLabel: '${(world.iridescence * 100).round()}%',
                      value: world.iridescence,
                      min: 0.0,
                      max: 1.0,
                      accent: accent,
                      onChanged: (v) =>
                          world.setMaterialOverrides(iridescence: v),
                    ),
                    const SizedBox(height: 12),

                    // Compact keyboard & interaction legend.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withValues(alpha: 0.04),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        'Drag to orbit · Scroll/pinch to zoom · Tap or [Space] for Aether Surge · [1-4] Moods · [T] Tour · [H] Hide HUD',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.58),
                          fontSize: 10.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          color: accent.withValues(alpha: 0.9),
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.accent,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final Color accent;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 11.5,
                  ),
                ),
              ),
              Text(
                valueLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 11,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: accent,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.14),
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleGrid extends StatelessWidget {
  const _ToggleGrid({required this.accent, required this.items});

  final Color accent;
  final List<(String, bool, ValueChanged<bool>)> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((item) {
        final (label, value, onChanged) = item;
        return InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: value
                  ? accent.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: value
                    ? accent.withValues(alpha: 0.72)
                    : Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: value
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.58),
                fontSize: 11,
                fontWeight: value ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ToneMapperSelector extends StatelessWidget {
  const _ToneMapperSelector({
    required this.selected,
    required this.accent,
    required this.onChanged,
  });

  final ToneMappingMode selected;
  final Color accent;
  final ValueChanged<ToneMappingMode> onChanged;

  static const _modes = [
    (ToneMappingMode.agx, 'AgX'),
    (ToneMappingMode.aces, 'ACES'),
    (ToneMappingMode.pbrNeutral, 'PBR Neutral'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _modes.map((entry) {
        final (mode, label) = entry;
        final active = selected == mode;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => onChanged(mode),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: active
                      ? accent.withValues(alpha: 0.24)
                      : Colors.white.withValues(alpha: 0.04),
                  border: Border.all(
                    color: active
                        ? accent.withValues(alpha: 0.75)
                        : Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.62),
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
