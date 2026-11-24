import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Curated atmosphere and rendering presets showcasing flutter_scene's look stack.
enum ObservatoryMood {
  solarisGold(
    label: 'Solaris Gold',
    subtitle: 'Golden-Hour Physical Sky & God Rays',
    accentColor: Color(0xFFF6C46D),
  ),
  neonVoid(
    label: 'Neon Void',
    subtitle: 'Midnight Bloom, Lens Flares & Cyber Trails',
    accentColor: Color(0xFF42E8FF),
  ),
  auroraSpire(
    label: 'Aurora Spire',
    subtitle: 'Polar Twilight, Volumetric Mist & Iridescence',
    accentColor: Color(0xFF6EF5B5),
  ),
  pbrStudio(
    label: 'PBR Studio',
    subtitle: 'Neutral Studio IBL & Material Calibration',
    accentColor: Color(0xFFE2E8F5),
  );

  const ObservatoryMood({
    required this.label,
    required this.subtitle,
    required this.accentColor,
  });

  final String label;
  final String subtitle;
  final Color accentColor;
}

/// Adaptive rendering quality presets balancing visual richness and 60 FPS WebGL2 budget.
enum QualityTier {
  ultra(
    label: 'Ultra',
    renderScale: 1.0,
    planarReflectionScale: 0.65,
    shadowMapResolution: 1024,
    godRaySteps: 24,
    allowSsr: true,
    allowAo: true,
    allowGodRays: true,
  ),
  balanced(
    label: 'Balanced',
    renderScale: 0.9,
    planarReflectionScale: 0.45,
    shadowMapResolution: 512,
    godRaySteps: 16,
    allowSsr: false,
    allowAo: true,
    allowGodRays: true,
  ),
  performance(
    label: 'Performance',
    renderScale: 0.75,
    planarReflectionScale: 0.3,
    shadowMapResolution: 512,
    godRaySteps: 12,
    allowSsr: false,
    allowAo: false,
    allowGodRays: false,
  );

  const QualityTier({
    required this.label,
    required this.renderScale,
    required this.planarReflectionScale,
    required this.shadowMapResolution,
    required this.godRaySteps,
    required this.allowSsr,
    required this.allowAo,
    required this.allowGodRays,
  });

  final String label;
  final double renderScale;
  final double planarReflectionScale;
  final int shadowMapResolution;
  final int godRaySteps;
  final bool allowSsr;
  final bool allowAo;
  final bool allowGodRays;
}

/// Named camera framing bookmarks.
enum CameraPreset {
  establishing(
    label: 'Establishing',
    azimuth: 0.55,
    polar: 0.34,
    distance: 13.8,
    targetY: 2.35,
  ),
  coreCloseUp(
    label: 'Core Close-Up',
    azimuth: 1.15,
    polar: 0.16,
    distance: 5.4,
    targetY: 2.85,
  ),
  lowHero(
    label: 'Low Hero',
    azimuth: -0.45,
    polar: 0.08,
    distance: 10.6,
    targetY: 2.45,
  ),
  zenithOrbital(
    label: 'Zenith Orbital',
    azimuth: 0.85,
    polar: 1.08,
    distance: 16.5,
    targetY: 1.6,
  );

  const CameraPreset({
    required this.label,
    required this.azimuth,
    required this.polar,
    required this.distance,
    required this.targetY,
  });

  final String label;
  final double azimuth;
  final double polar;
  final double distance;
  final double targetY;
}

/// Complete visual palette and post-processing recipe for an [ObservatoryMood].
class MoodConfig {
  const MoodConfig({
    required this.mood,
    required this.usePhysicalSky,
    required this.useStudioIblOnly,
    required this.sunElevationDeg,
    required this.sunAzimuthDeg,
    required this.skyZenith,
    required this.skyHorizon,
    required this.skyGround,
    required this.skySunColor,
    required this.sunLightColor,
    required this.sunIntensity,
    required this.orbColors,
    required this.corePrimary,
    required this.coreSecondary,
    required this.coreIntensity,
    required this.obsidianTint,
    required this.runeColor,
    required this.runeIntensity,
    required this.reflectionStrength,
    required this.ringGoldTint,
    required this.ringTitaniumTint,
    required this.crystalBaseColor,
    required this.crystalEmissive,
    required this.toneMapping,
    required this.exposure,
    required this.environmentIntensity,
    required this.bloomEnabled,
    required this.bloomThreshold,
    required this.bloomIntensity,
    required this.bloomScatter,
    required this.lensFlareEnabled,
    required this.lensFlareIntensity,
    required this.godRaysEnabled,
    required this.godRaysIntensity,
    required this.godRaysColor,
    required this.fogEnabled,
    required this.fogColor,
    required this.fogDensity,
    required this.aoEnabled,
    required this.ssrEnabled,
    required this.vignetteEnabled,
    required this.vignetteIntensity,
    required this.chromaticAberrationEnabled,
    required this.chromaticAberrationIntensity,
    required this.colorGradingEnabled,
    required this.contrast,
    required this.saturation,
    required this.temperature,
  });

  final ObservatoryMood mood;
  final bool usePhysicalSky;
  final bool useStudioIblOnly;
  final double sunElevationDeg;
  final double sunAzimuthDeg;
  final vm.Vector3 skyZenith;
  final vm.Vector3 skyHorizon;
  final vm.Vector3 skyGround;
  final vm.Vector3 skySunColor;
  final vm.Vector3 sunLightColor;
  final double sunIntensity;
  final List<vm.Vector3> orbColors;
  final vm.Vector3 corePrimary;
  final vm.Vector3 coreSecondary;
  final double coreIntensity;
  final vm.Vector3 obsidianTint;
  final vm.Vector3 runeColor;
  final double runeIntensity;
  final double reflectionStrength;
  final vm.Vector3 ringGoldTint;
  final vm.Vector3 ringTitaniumTint;
  final vm.Vector3 crystalBaseColor;
  final vm.Vector3 crystalEmissive;
  final ToneMappingMode toneMapping;
  final double exposure;
  final double environmentIntensity;
  final bool bloomEnabled;
  final double bloomThreshold;
  final double bloomIntensity;
  final double bloomScatter;
  final bool lensFlareEnabled;
  final double lensFlareIntensity;
  final bool godRaysEnabled;
  final double godRaysIntensity;
  final vm.Vector3 godRaysColor;
  final bool fogEnabled;
  final vm.Vector3 fogColor;
  final double fogDensity;
  final bool aoEnabled;
  final bool ssrEnabled;
  final bool vignetteEnabled;
  final double vignetteIntensity;
  final bool chromaticAberrationEnabled;
  final double chromaticAberrationIntensity;
  final bool colorGradingEnabled;
  final double contrast;
  final double saturation;
  final double temperature;

  /// Converts elevation & azimuth degrees into a world-space unit vector toward the sun.
  static vm.Vector3 sunDirectionFromAngles(
    double elevationDeg,
    double azimuthDeg,
  ) {
    final elev = elevationDeg * math.pi / 180.0;
    final azim = azimuthDeg * math.pi / 180.0;
    final cosE = math.cos(elev);
    return vm.Vector3(
      cosE * math.sin(azim),
      math.sin(elev),
      cosE * math.cos(azim),
    ).normalized();
  }
}

/// Curated presets tuned using flutter_scene's HDR look stack principles.
final Map<ObservatoryMood, MoodConfig> kMoodConfigs =
    <ObservatoryMood, MoodConfig>{
  ObservatoryMood.solarisGold: MoodConfig(
    mood: ObservatoryMood.solarisGold,
    usePhysicalSky: true,
    useStudioIblOnly: false,
    sunElevationDeg: 13.0,
    sunAzimuthDeg: -145.0,
    skyZenith: vm.Vector3(0.06, 0.14, 0.34),
    skyHorizon: vm.Vector3(0.92, 0.56, 0.28),
    skyGround: vm.Vector3(0.06, 0.05, 0.05),
    skySunColor: vm.Vector3(5.5, 3.6, 1.8),
    sunLightColor: vm.Vector3(1.0, 0.84, 0.62),
    sunIntensity: 4.2,
    orbColors: [
      vm.Vector3(0.20, 0.88, 1.0),
      vm.Vector3(1.0, 0.68, 0.22),
      vm.Vector3(0.95, 0.38, 0.62),
    ],
    corePrimary: vm.Vector3(0.18, 0.88, 1.0),
    coreSecondary: vm.Vector3(1.0, 0.64, 0.18),
    coreIntensity: 2.7,
    obsidianTint: vm.Vector3(0.035, 0.035, 0.048),
    runeColor: vm.Vector3(1.0, 0.72, 0.28),
    runeIntensity: 1.55,
    reflectionStrength: 0.78,
    ringGoldTint: vm.Vector3(0.96, 0.76, 0.34),
    ringTitaniumTint: vm.Vector3(0.24, 0.27, 0.34),
    crystalBaseColor: vm.Vector3(0.14, 0.22, 0.32),
    crystalEmissive: vm.Vector3(0.25, 0.62, 0.85),
    toneMapping: ToneMappingMode.agx,
    exposure: 1.05,
    environmentIntensity: 1.15,
    bloomEnabled: true,
    bloomThreshold: 1.05,
    bloomIntensity: 0.28,
    bloomScatter: 0.72,
    lensFlareEnabled: true,
    lensFlareIntensity: 0.42,
    godRaysEnabled: true,
    godRaysIntensity: 0.62,
    godRaysColor: vm.Vector3(1.0, 0.78, 0.45),
    fogEnabled: true,
    fogColor: vm.Vector3(0.42, 0.29, 0.22),
    fogDensity: 0.011,
    aoEnabled: true,
    ssrEnabled: false,
    vignetteEnabled: true,
    vignetteIntensity: 0.36,
    chromaticAberrationEnabled: false,
    chromaticAberrationIntensity: 0.08,
    colorGradingEnabled: true,
    contrast: 1.06,
    saturation: 1.08,
    temperature: 0.08,
  ),
  ObservatoryMood.neonVoid: MoodConfig(
    mood: ObservatoryMood.neonVoid,
    usePhysicalSky: false,
    useStudioIblOnly: false,
    sunElevationDeg: 22.0,
    sunAzimuthDeg: -120.0,
    skyZenith: vm.Vector3(0.01, 0.015, 0.05),
    skyHorizon: vm.Vector3(0.08, 0.035, 0.16),
    skyGround: vm.Vector3(0.01, 0.01, 0.025),
    skySunColor: vm.Vector3(1.6, 0.45, 2.4),
    sunLightColor: vm.Vector3(0.55, 0.72, 1.0),
    sunIntensity: 1.85,
    orbColors: [
      vm.Vector3(0.05, 0.95, 1.0),
      vm.Vector3(1.0, 0.12, 0.68),
      vm.Vector3(0.58, 0.24, 1.0),
    ],
    corePrimary: vm.Vector3(0.06, 0.96, 1.0),
    coreSecondary: vm.Vector3(1.0, 0.14, 0.68),
    coreIntensity: 3.3,
    obsidianTint: vm.Vector3(0.018, 0.022, 0.042),
    runeColor: vm.Vector3(0.10, 0.92, 1.0),
    runeIntensity: 2.1,
    reflectionStrength: 0.88,
    ringGoldTint: vm.Vector3(0.75, 0.82, 0.96),
    ringTitaniumTint: vm.Vector3(0.14, 0.16, 0.24),
    crystalBaseColor: vm.Vector3(0.12, 0.10, 0.24),
    crystalEmissive: vm.Vector3(0.55, 0.18, 0.95),
    toneMapping: ToneMappingMode.aces,
    exposure: 1.12,
    environmentIntensity: 0.95,
    bloomEnabled: true,
    bloomThreshold: 0.85,
    bloomIntensity: 0.36,
    bloomScatter: 0.78,
    lensFlareEnabled: true,
    lensFlareIntensity: 0.55,
    godRaysEnabled: false,
    godRaysIntensity: 0.35,
    godRaysColor: vm.Vector3(0.45, 0.72, 1.0),
    fogEnabled: true,
    fogColor: vm.Vector3(0.04, 0.025, 0.09),
    fogDensity: 0.015,
    aoEnabled: true,
    ssrEnabled: true,
    vignetteEnabled: true,
    vignetteIntensity: 0.48,
    chromaticAberrationEnabled: true,
    chromaticAberrationIntensity: 0.14,
    colorGradingEnabled: true,
    contrast: 1.10,
    saturation: 1.18,
    temperature: -0.10,
  ),
  ObservatoryMood.auroraSpire: MoodConfig(
    mood: ObservatoryMood.auroraSpire,
    usePhysicalSky: false,
    useStudioIblOnly: false,
    sunElevationDeg: 18.0,
    sunAzimuthDeg: 150.0,
    skyZenith: vm.Vector3(0.015, 0.06, 0.12),
    skyHorizon: vm.Vector3(0.06, 0.34, 0.32),
    skyGround: vm.Vector3(0.015, 0.03, 0.045),
    skySunColor: vm.Vector3(0.95, 2.6, 2.2),
    sunLightColor: vm.Vector3(0.68, 0.96, 0.92),
    sunIntensity: 2.6,
    orbColors: [
      vm.Vector3(0.16, 1.0, 0.68),
      vm.Vector3(0.32, 0.64, 1.0),
      vm.Vector3(0.76, 0.42, 1.0),
    ],
    corePrimary: vm.Vector3(0.16, 1.0, 0.68),
    coreSecondary: vm.Vector3(0.48, 0.36, 1.0),
    coreIntensity: 2.9,
    obsidianTint: vm.Vector3(0.02, 0.04, 0.055),
    runeColor: vm.Vector3(0.22, 0.96, 0.72),
    runeIntensity: 1.75,
    reflectionStrength: 0.82,
    ringGoldTint: vm.Vector3(0.84, 0.92, 0.90),
    ringTitaniumTint: vm.Vector3(0.16, 0.26, 0.30),
    crystalBaseColor: vm.Vector3(0.09, 0.26, 0.28),
    crystalEmissive: vm.Vector3(0.18, 0.92, 0.72),
    toneMapping: ToneMappingMode.agx,
    exposure: 1.08,
    environmentIntensity: 1.1,
    bloomEnabled: true,
    bloomThreshold: 0.95,
    bloomIntensity: 0.30,
    bloomScatter: 0.76,
    lensFlareEnabled: true,
    lensFlareIntensity: 0.35,
    godRaysEnabled: true,
    godRaysIntensity: 0.45,
    godRaysColor: vm.Vector3(0.35, 0.95, 0.80),
    fogEnabled: true,
    fogColor: vm.Vector3(0.04, 0.14, 0.16),
    fogDensity: 0.016,
    aoEnabled: true,
    ssrEnabled: false,
    vignetteEnabled: true,
    vignetteIntensity: 0.38,
    chromaticAberrationEnabled: false,
    chromaticAberrationIntensity: 0.08,
    colorGradingEnabled: true,
    contrast: 1.05,
    saturation: 1.12,
    temperature: -0.14,
  ),
  ObservatoryMood.pbrStudio: MoodConfig(
    mood: ObservatoryMood.pbrStudio,
    usePhysicalSky: false,
    useStudioIblOnly: true,
    sunElevationDeg: 42.0,
    sunAzimuthDeg: -50.0,
    skyZenith: vm.Vector3(0.09, 0.10, 0.13),
    skyHorizon: vm.Vector3(0.18, 0.20, 0.24),
    skyGround: vm.Vector3(0.06, 0.06, 0.07),
    skySunColor: vm.Vector3(2.8, 2.75, 2.65),
    sunLightColor: vm.Vector3(1.0, 0.98, 0.95),
    sunIntensity: 3.1,
    orbColors: [
      vm.Vector3(0.95, 0.82, 0.55),
      vm.Vector3(0.55, 0.80, 1.0),
      vm.Vector3(0.95, 0.95, 1.0),
    ],
    corePrimary: vm.Vector3(0.32, 0.78, 1.0),
    coreSecondary: vm.Vector3(0.96, 0.76, 0.42),
    coreIntensity: 2.1,
    obsidianTint: vm.Vector3(0.055, 0.06, 0.072),
    runeColor: vm.Vector3(0.72, 0.84, 0.98),
    runeIntensity: 0.95,
    reflectionStrength: 0.68,
    ringGoldTint: vm.Vector3(0.98, 0.79, 0.38),
    ringTitaniumTint: vm.Vector3(0.34, 0.36, 0.41),
    crystalBaseColor: vm.Vector3(0.22, 0.26, 0.34),
    crystalEmissive: vm.Vector3(0.32, 0.52, 0.76),
    toneMapping: ToneMappingMode.pbrNeutral,
    exposure: 1.0,
    environmentIntensity: 1.25,
    bloomEnabled: true,
    bloomThreshold: 1.25,
    bloomIntensity: 0.16,
    bloomScatter: 0.62,
    lensFlareEnabled: false,
    lensFlareIntensity: 0.25,
    godRaysEnabled: false,
    godRaysIntensity: 0.25,
    godRaysColor: vm.Vector3(1.0, 0.96, 0.9),
    fogEnabled: false,
    fogColor: vm.Vector3(0.12, 0.14, 0.17),
    fogDensity: 0.006,
    aoEnabled: true,
    ssrEnabled: true,
    vignetteEnabled: true,
    vignetteIntensity: 0.24,
    chromaticAberrationEnabled: false,
    chromaticAberrationIntensity: 0.0,
    colorGradingEnabled: false,
    contrast: 1.0,
    saturation: 1.0,
    temperature: 0.0,
  ),
};
