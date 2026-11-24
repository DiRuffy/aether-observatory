import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'atmosphere_presets.dart';
import 'geometry_builders.dart';

class _OrbitingOrb {
  _OrbitingOrb({
    required this.node,
    required this.light,
    required this.material,
    required this.trail,
    required this.orbitRadius,
    required this.orbitHeight,
    required this.verticalAmp,
    required this.speed,
    required this.phase,
  });

  final Node node;
  final PointLight light;
  final PhysicallyBasedMaterial material;
  final TrailComponent trail;
  final double orbitRadius;
  final double orbitHeight;
  final double verticalAmp;
  final double speed;
  final double phase;
}

class _ActiveDistortion {
  _ActiveDistortion({
    required this.pulse,
    required this.age,
    required this.duration,
  });

  final DistortionPulse pulse;
  double age;
  final double duration;
}

/// Manages sky/IBL lighting, cascaded sun shadows, 3 orbiting chromatic point
/// lights with real-time ribbon trails, cosmic stardust particles, surge burst
/// particles, and screen-space refractive shockwave distortion pulses.
class LightingVfxController {
  LightingVfxController._({
    required this.scene,
    required this.physicalSky,
    required this.gradientSky,
    required this._orbs,
    required this.stardustNode,
    required this.stardustEmitter,
    required this.burstNode,
    required this.burstEmitter,
    required this.glowTexture,
  });

  final Scene scene;
  final PhysicalSkySource physicalSky;
  final GradientSkySource gradientSky;
  final List<_OrbitingOrb> _orbs;
  final Node stardustNode;
  final ParticleEmitterComponent stardustEmitter;
  final Node burstNode;
  final ParticleEmitterComponent burstEmitter;
  final Texture2D glowTexture;

  final List<_ActiveDistortion> _activeDistortions = [];
  double _orbElapsed = 0.0;
  double _burstCooldown = 0.0;

  static LightingVfxController create({
    required Scene scene,
    required MoodConfig initialMood,
  }) {
    final physicalSky = PhysicalSkySource(
      sunDirection: MoodConfig.sunDirectionFromAngles(
        initialMood.sunElevationDeg,
        initialMood.sunAzimuthDeg,
      ),
      sunAngularRadius: 0.024,
      rayleighCoefficient: 2.2,
      mieCoefficient: 0.008,
      mieEccentricity: 0.84,
      turbidity: 9.0,
      groundColor: initialMood.skyGround,
      energy: 1.15,
    );

    final gradientSky = GradientSkySource(
      zenithColor: initialMood.skyZenith,
      horizonColor: initialMood.skyHorizon,
      groundColor: initialMood.skyGround,
      sunDirection: MoodConfig.sunDirectionFromAngles(
        initialMood.sunElevationDeg,
        initialMood.sunAzimuthDeg,
      ),
      sunColor: initialMood.skySunColor,
      sunSharpness: 320.0,
    );

    // Build 3 orbiting chromatic energy orbs with PointLight + TrailComponent.
    final orbGeo = SphereGeometry(radius: 0.14, segments: 20, rings: 12);
    final orbConfigs = [
      (radius: 4.15, height: 3.15, amp: 1.05, speed: 0.62, phase: 0.0),
      (radius: 4.85, height: 2.85, amp: 1.35, speed: -0.48, phase: 2.1),
      (radius: 3.65, height: 3.55, amp: 0.85, speed: 0.82, phase: 4.2),
    ];

    final orbs = <_OrbitingOrb>[];
    for (var i = 0; i < orbConfigs.length; i++) {
      final cfg = orbConfigs[i];
      final color = initialMood.orbColors[i % initialMood.orbColors.length];

      final orbMat = PhysicallyBasedMaterial()
        ..baseColorFactor = vm.Vector4(1.0, 1.0, 1.0, 1.0)
        ..metallicFactor = 0.0
        ..roughnessFactor = 0.1
        ..emissiveFactor = vm.Vector4(
          color.x * 5.2,
          color.y * 5.2,
          color.z * 5.2,
          1.0,
        );

      final pointLight = PointLight(
        color: color.clone(),
        intensity: 15.0,
        range: 20.0,
        falloffExponent: 1.65,
        radius: 0.24,
      );

      final trail = TrailComponent(
        width: 0.22,
        lifetime: 0.85,
        minVertexDistance: 0.07,
        maxPoints: 52,
        widthOverTrail: ParticleCurve([
          const ParticleKeyframe(0.0, 1.0),
          const ParticleKeyframe(0.35, 0.58),
          const ParticleKeyframe(1.0, 0.0),
        ]),
        colorOverTrail: _trailGradientForColor(color),
      );

      final orbNode = Node(
        name: 'chromatic_orb_$i',
        mesh: Mesh(orbGeo, orbMat),
      )
        ..shadowCastingMode = ShadowCastingMode.off
        ..addComponent(PointLightComponent(pointLight))
        ..addComponent(trail);

      scene.add(orbNode);
      orbs.add(
        _OrbitingOrb(
          node: orbNode,
          light: pointLight,
          material: orbMat,
          trail: trail,
          orbitRadius: cfg.radius,
          orbitHeight: cfg.height,
          verticalAmp: cfg.amp,
          speed: cfg.speed,
          phase: cfg.phase,
        ),
      );
    }

    // Procedural velvety glow sprite texture for both particle emitters.
    final glowTexture = GeometryBuilders.buildSoftGlowSpriteTexture(size: 64);

    // 1. Ambient Cosmic Stardust emitter surrounding the observatory.
    final stardustSystem = ParticleSystem(
      maxParticles: 240,
      shape: const SphereEmitterShape(radius: 6.5),
      spawner: Spawner(rate: 42.0),
      lifetime: const UniformFloat(2.8, 5.4),
      startSpeed: const UniformFloat(0.15, 0.45),
      startSize: const UniformFloat(0.08, 0.22),
      gravity: vm.Vector3(0.0, 0.24, 0.0),
      prewarm: 3.5,
      seed: 101,
      modules: [
        TurbulenceModule(
          strength: 0.42,
          frequency: 0.35,
          scroll: vm.Vector3(0.0, 0.4, 0.0),
        ),
        SizeOverLifeModule(
          CurveFloat(
            ParticleCurve([
              const ParticleKeyframe(0.0, 0.0),
              const ParticleKeyframe(0.22, 1.0),
              const ParticleKeyframe(0.75, 0.85),
              const ParticleKeyframe(1.0, 0.0),
            ]),
          ),
        ),
        ColorOverLifeModule(
          GradientColor(
            ColorGradient([
              ColorStop(0.0, vm.Vector4(1.4, 1.6, 2.0, 0.0)),
              ColorStop(0.25, vm.Vector4(1.4, 1.8, 2.4, 0.9)),
              ColorStop(0.75, vm.Vector4(1.8, 1.5, 1.0, 0.65)),
              ColorStop(1.0, vm.Vector4(1.2, 0.9, 0.6, 0.0)),
            ]),
          ),
        ),
      ],
    );

    final stardustMat = SpriteMaterial(colorTexture: glowTexture)
      ..blendMode = SpriteBlendMode.additive
      ..tint = vm.Vector4(
        initialMood.corePrimary.x * 0.9 + 0.35,
        initialMood.corePrimary.y * 0.9 + 0.35,
        initialMood.corePrimary.z * 0.9 + 0.35,
        0.92,
      );

    final stardustEmitter = ParticleEmitterComponent(
      system: stardustSystem,
      material: stardustMat,
    );

    final stardustNode = Node(name: 'cosmic_stardust_emitter')
      ..position = vm.Vector3(0.0, 3.0, 0.0)
      ..shadowCastingMode = ShadowCastingMode.off
      ..addComponent(stardustEmitter);
    scene.add(stardustNode);

    // 2. Aether Surge supernova spark burst emitter (centered in the core).
    final burstSystem = ParticleSystem(
      maxParticles: 260,
      shape: const SphereEmitterShape(radius: 0.72, surfaceOnly: true),
      spawner: Spawner(
        rate: 0.0,
        bursts: const [ParticleBurst(time: 0.0, count: 140)],
      ),
      lifetime: const UniformFloat(0.75, 1.65),
      startSpeed: const UniformFloat(4.8, 10.5),
      startSize: const UniformFloat(0.09, 0.24),
      gravity: vm.Vector3(0.0, -1.2, 0.0),
      looping: false,
      duration: 2.0,
      seed: 777,
      modules: [
        LinearDragModule(2.2),
        SizeOverLifeModule(
          CurveFloat(
            ParticleCurve([
              const ParticleKeyframe(0.0, 1.2),
              const ParticleKeyframe(0.55, 0.7),
              const ParticleKeyframe(1.0, 0.0),
            ]),
          ),
        ),
        ColorOverLifeModule(
          GradientColor(
            ColorGradient([
              ColorStop(0.0, vm.Vector4(3.2, 3.4, 3.8, 1.0)),
              ColorStop(0.30, vm.Vector4(0.6, 2.4, 3.2, 0.95)),
              ColorStop(0.75, vm.Vector4(2.4, 1.2, 0.4, 0.5)),
              ColorStop(1.0, vm.Vector4(1.0, 0.3, 0.1, 0.0)),
            ]),
          ),
        ),
      ],
    );
    // Start silent until the first surge fires.
    burstSystem.step(2.2);

    final burstMat = SpriteMaterial(colorTexture: glowTexture)
      ..blendMode = SpriteBlendMode.additive
      ..tint = vm.Vector4(1.2, 1.2, 1.2, 1.0);

    final burstEmitter = ParticleEmitterComponent(
      system: burstSystem,
      material: burstMat,
    )
      ..facing = BillboardFacing.velocityStretched
      ..velocityStretch = 0.085;

    final burstNode = Node(name: 'aether_surge_burst')
      ..position = vm.Vector3(0.0, 3.15, 0.0)
      ..shadowCastingMode = ShadowCastingMode.off
      ..addComponent(burstEmitter);
    scene.add(burstNode);

    return LightingVfxController._(
      scene: scene,
      physicalSky: physicalSky,
      gradientSky: gradientSky,
      orbs: orbs,
      stardustNode: stardustNode,
      stardustEmitter: stardustEmitter,
      burstNode: burstNode,
      burstEmitter: burstEmitter,
      glowTexture: glowTexture,
    );
  }

  static ColorGradient _trailGradientForColor(vm.Vector3 c) {
    return ColorGradient([
      ColorStop(0.0, vm.Vector4(c.x * 2.8, c.y * 2.8, c.z * 2.8, 0.95)),
      ColorStop(0.35, vm.Vector4(c.x * 1.4, c.y * 1.4, c.z * 1.4, 0.55)),
      ColorStop(1.0, vm.Vector4(c.x * 0.4, c.y * 0.4, c.z * 0.4, 0.0)),
    ]);
  }

  /// Applies sky source, synchronized IBL `SkyEnvironment`, directional sun
  /// shadows, orb/trail colors, and particle tints.
  void applyAtmosphere({
    required MoodConfig config,
    required double sunElevationDeg,
    required double sunAzimuthDeg,
    required QualityTier quality,
    required bool shadowsEnabled,
  }) {
    final sunDir = MoodConfig.sunDirectionFromAngles(
      sunElevationDeg,
      sunAzimuthDeg,
    );

    physicalSky
      ..sunDirection = sunDir
      ..groundColor = config.skyGround.clone();

    gradientSky
      ..zenithColor = config.skyZenith.clone()
      ..horizonColor = config.skyHorizon.clone()
      ..groundColor = config.skyGround.clone()
      ..sunDirection = sunDir
      ..sunColor = config.skySunColor.clone();

    if (config.useStudioIblOnly) {
      // Studio mode keeps the built-in procedural studio IBL for honest PBR calibration.
      scene.skyEnvironment = null;
      scene.environment = null;
      scene.skybox = Skybox(gradientSky);
      scene.sunLight = null;
      scene.directionalLight = DirectionalLight(
        direction: (-sunDir).normalized(),
        color: config.sunLightColor.clone(),
        intensity: config.sunIntensity,
        castsShadow: shadowsEnabled,
        shadowMapResolution: quality.shadowMapResolution,
        shadowCascadeCount: 2,
        shadowMaxDistance: 36.0,
        shadowSoftness: 0.12,
        shadowAmbientStrength: 0.35,
      );
    } else {
      final activeSky = config.usePhysicalSky
          ? physicalSky as ShaderSkySource
          : gradientSky as ShaderSkySource;
      final activeSunSky = activeSky as SunSky;

      scene.skybox = Skybox(activeSky);
      scene.skyEnvironment = SkyEnvironment(
        activeSky,
        refresh: SkyEnvironmentRefresh.manual,
        faceResolution: 64,
        equirectWidth: 256,
      );
      scene.sunLight = SunLight(
        activeSunSky,
        castsShadow: shadowsEnabled,
        color: config.sunLightColor.clone(),
        intensity: config.sunIntensity,
        shadowMapResolution: quality.shadowMapResolution,
        shadowCascadeCount: 2,
        shadowMaxDistance: 36.0,
        shadowSoftness: 0.12,
        shadowAmbientStrength: 0.45,
        cacheStaticShadows: false,
      );
    }

    // Update chromatic orbiting orbs, point lights, and ribbon trails.
    for (var i = 0; i < _orbs.length; i++) {
      final orb = _orbs[i];
      final color = config.orbColors[i % config.orbColors.length];
      orb.light.color = color.clone();
      orb.material.emissiveFactor = vm.Vector4(
        color.x * 5.2,
        color.y * 5.2,
        color.z * 5.2,
        1.0,
      );
      orb.trail.colorOverTrail = _trailGradientForColor(color);
    }

    // Tint ambient stardust & burst sprites to harmonize with the mood.
    stardustEmitter.material.tint = vm.Vector4(
      config.corePrimary.x * 0.75 + 0.35,
      config.corePrimary.y * 0.75 + 0.35,
      config.corePrimary.z * 0.75 + 0.35,
      0.92,
    );
    burstEmitter.material.tint = vm.Vector4(
      config.corePrimary.x * 0.65 + 0.6,
      config.corePrimary.y * 0.65 + 0.6,
      config.corePrimary.z * 0.65 + 0.6,
      1.0,
    );
  }

  /// Fires a burst of velocity-stretched sparks + a screen-space refractive
  /// chromatic shockwave distortion pulse!
  void triggerSurge({Offset? normalizedScreenCenter}) {
    if (_burstCooldown <= 0.0) {
      burstEmitter.system.reset();
      _burstCooldown = 0.25;
    }

    final center = normalizedScreenCenter == null
        ? vm.Vector2(0.5, 0.48)
        : vm.Vector2(
            normalizedScreenCenter.dx.clamp(0.05, 0.95),
            normalizedScreenCenter.dy.clamp(0.05, 0.95),
          );

    final pulse = DistortionPulse(
      center: center,
      radius: 0.01,
      thickness: 0.11,
      strength: 0.028,
      chromaticAberration: 0.65,
    );
    _activeDistortions.add(
      _ActiveDistortion(pulse: pulse, age: 0.0, duration: 0.95),
    );
    if (_activeDistortions.length > ScreenDistortionSettings.maxPulses) {
      _activeDistortions.removeAt(0);
    }
    _syncScreenDistortion();
  }

  /// Advances orbiting chromatic lights, point light surge flares, and active
  /// screen-space distortion shockwaves.
  void update({
    required double dt,
    required double speedScale,
    required double surgeEnergy,
  }) {
    if (_burstCooldown > 0.0) {
      _burstCooldown = math.max(0.0, _burstCooldown - dt);
    }

    final boost = 1.0 + surgeEnergy * 2.8;
    _orbElapsed += dt * speedScale * boost;

    for (var i = 0; i < _orbs.length; i++) {
      final orb = _orbs[i];
      final theta = _orbElapsed * orb.speed + orb.phase;
      final r = orb.orbitRadius + math.sin(theta * 2.0) * 0.35 + surgeEnergy * 0.55;
      final x = math.cos(theta) * r;
      final z = math.sin(theta) * r;
      final y = orb.orbitHeight + math.sin(theta * 1.5 + i) * orb.verticalAmp;
      orb.node.position = vm.Vector3(x, y, z);
      orb.light.intensity = 15.0 + surgeEnergy * 28.0;
    }

    if (_activeDistortions.isNotEmpty) {
      for (final d in _activeDistortions) {
        d.age += dt;
        final t = (d.age / d.duration).clamp(0.0, 1.0);
        // Ease-out expansion with smooth strength fade.
        final eased = 1.0 - math.pow(1.0 - t, 2.2).toDouble();
        d.pulse
          ..radius = 0.02 + eased * 1.15
          ..strength = 0.028 * (1.0 - t) * (1.0 - t)
          ..thickness = 0.08 + eased * 0.08;
      }
      _activeDistortions.removeWhere((d) => d.age >= d.duration);
      _syncScreenDistortion();
    }
  }

  void _syncScreenDistortion() {
    scene.screenDistortion.pulses
      ..clear()
      ..addAll(_activeDistortions.map((d) => d.pulse));
    scene.screenDistortion.enabled = _activeDistortions.isNotEmpty;
  }
}
