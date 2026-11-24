import 'dart:math' as math;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'atmosphere_presets.dart';
import 'geometry_builders.dart';

class _MonolithSpec {
  const _MonolithSpec({
    required this.angle,
    required this.radius,
    required this.baseY,
    required this.scale,
    required this.phase,
    required this.tiltX,
    required this.tiltZ,
    required this.spinSpeed,
  });

  final double angle;
  final double radius;
  final double baseY;
  final double scale;
  final double phase;
  final double tiltX;
  final double tiltZ;
  final double spinSpeed;
}

/// Architectural sanctuary stage featuring:
/// - True real-time Planar Mirror obsidian pool (`.fmat` + `PlanarReflectorComponent`)
/// - Sculpted outer granite coping, gilded trim, perimeter pylons & cathedral arches
/// - 32 instanced floating hexagonal crystal monoliths in a single GPU draw call
/// - Local `ReflectionProbeComponent` for realistic metallic ring reflections
class SanctuaryStage {
  SanctuaryStage._({
    required this.rootNode,
    required this.mirrorNode,
    required this.planarReflector,
    required this.reflectionProbe,
    required this.crystalMesh,
    required this._monolithSpecs,
    required this.crystalMaterial,
    required this.trimGoldMaterial,
    required this.pylonGlowMaterial,
    this.mirrorFmat,
    this.mirrorFallbackMaterial,
  });

  final Node rootNode;
  final Node mirrorNode;
  final PlanarReflectorComponent planarReflector;
  final ReflectionProbeComponent reflectionProbe;
  final InstancedMesh crystalMesh;
  final List<_MonolithSpec> _monolithSpecs;

  final PhysicallyBasedMaterial crystalMaterial;
  final PhysicallyBasedMaterial trimGoldMaterial;
  final PhysicallyBasedMaterial pylonGlowMaterial;
  final PreprocessedMaterial? mirrorFmat;
  final PhysicallyBasedMaterial? mirrorFallbackMaterial;

  double _shockwaveRadius = -3.0;
  double _shockwaveStrength = 0.0;

  static Future<SanctuaryStage> create({
    required MoodConfig initialMood,
    required QualityTier initialQuality,
  }) async {
    final root = Node(name: 'sanctuary_stage');

    // 1. True Planar Mirror Obsidian Reflecting Pool (radius 9.0 at y = 0).
    PreprocessedMaterial? mirrorFmat;
    PhysicallyBasedMaterial? mirrorFallback;
    try {
      mirrorFmat = await loadFmatMaterial(
        'assets/shaders/obsidian_mirror.fmat',
      );
    } catch (e) {
      debugPrint('ObsidianMirror .fmat fallback active: $e');
      mirrorFallback = PhysicallyBasedMaterial()
        ..baseColorFactor = vm.Vector4(0.03, 0.04, 0.06, 1.0)
        ..metallicFactor = 0.72
        ..roughnessFactor = 0.09;
    }

    final planarReflector = PlanarReflectorComponent(
      resolutionScale: initialQuality.planarReflectionScale,
      clipBias: 0.015,
    );

    final mirrorNode = Node(
      name: 'obsidian_mirror_pool',
      mesh: Mesh(
        DiscGeometry(radius: 9.0, segments: 96),
        mirrorFmat ?? mirrorFallback!,
      ),
    )..addComponent(planarReflector);
    // Flat mirror floor receives shadows, does not need to cast into shadow map.
    mirrorNode.shadowCastingMode = ShadowCastingMode.off;
    root.add(mirrorNode);

    // 2. Sculpted outer architectural coping ring (strictly outside r = 9.05).
    final stoneMat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.09, 0.10, 0.13, 1.0)
      ..metallicFactor = 0.18
      ..roughnessFactor = 0.58;

    final trimGoldMat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(
        initialMood.ringGoldTint.x,
        initialMood.ringGoldTint.y,
        initialMood.ringGoldTint.z,
        1.0,
      )
      ..metallicFactor = 0.94
      ..roughnessFactor = 0.22;

    final pylonGlowMat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.9, 0.96, 1.0, 1.0)
      ..metallicFactor = 0.1
      ..roughnessFactor = 0.2
      ..emissiveFactor = vm.Vector4(
        initialMood.runeColor.x * 2.6,
        initialMood.runeColor.y * 2.6,
        initialMood.runeColor.z * 2.6,
        1.0,
      );

    final outerCoping = Node(
      name: 'terrace_coping_ring',
      mesh: Mesh(
        GeometryBuilders.buildBeveledArmillaryRing(
          radius: 9.68,
          radialWidth: 1.24,
          verticalHeight: 0.42,
          segments: 96,
        ),
        stoneMat,
      ),
    )
      ..position = vm.Vector3(0.0, 0.06, 0.0)
      ..shadowStatic = true;
    root.add(outerCoping);

    // Raised gilded rim bezel framing the obsidian pool.
    final poolBezel = Node(
      name: 'pool_gold_bezel',
      mesh: Mesh(
        TorusGeometry(
          radius: 9.06,
          tubeRadius: 0.072,
          radialSegments: 96,
          tubularSegments: 16,
        ),
        trimGoldMat,
      ),
    )
      ..position = vm.Vector3(0.0, 0.26, 0.0)
      ..shadowStatic = true;
    root.add(poolBezel);

    // 3. Central submerged pedestal plinth under the floating astrolabe.
    final centerPlinthBase = Node(
      name: 'center_plinth_base',
      mesh: Mesh(
        CylinderGeometry(
          bottomRadius: 1.68,
          topRadius: 1.42,
          height: 0.28,
          radialSegments: 48,
        ),
        stoneMat,
      ),
    )
      ..position = vm.Vector3(0.0, 0.145, 0.0)
      ..shadowStatic = true;

    final centerPlinthTrim = Node(
      name: 'center_plinth_trim',
      mesh: Mesh(
        TorusGeometry(
          radius: 1.44,
          tubeRadius: 0.048,
          radialSegments: 64,
          tubularSegments: 14,
        ),
        trimGoldMat,
      ),
    )
      ..position = vm.Vector3(0.0, 0.30, 0.0)
      ..shadowStatic = true;

    final centerEmitterDisc = Node(
      name: 'center_emitter_ring',
      mesh: Mesh(
        TorusGeometry(
          radius: 0.92,
          tubeRadius: 0.032,
          radialSegments: 48,
          tubularSegments: 12,
        ),
        pylonGlowMat,
      ),
    )
      ..position = vm.Vector3(0.0, 0.31, 0.0)
      ..shadowCastingMode = ShadowCastingMode.off;

    root
      ..add(centerPlinthBase)
      ..add(centerPlinthTrim)
      ..add(centerEmitterDisc);

    // 4. Eight perimeter architectural pylons + 4 sweeping cathedral arches.
    final pylonShaftGeo = CylinderGeometry(
      bottomRadius: 0.32,
      topRadius: 0.19,
      height: 1.75,
      radialSegments: 6,
    );
    final pylonCrownGeo = GeometryBuilders.buildOctahedron(radius: 0.16);

    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2.0;
      const r = 9.68;
      final px = math.cos(angle) * r;
      final pz = math.sin(angle) * r;

      final pylon = Node(
        name: 'perimeter_pylon_$i',
        mesh: Mesh(pylonShaftGeo, stoneMat),
      )
        ..position = vm.Vector3(px, 1.14, pz)
        ..shadowStatic = true;

      final crown = Node(
        name: 'perimeter_crown_$i',
        mesh: Mesh(pylonCrownGeo, pylonGlowMat),
      )
        ..position = vm.Vector3(px, 2.32, pz)
        ..shadowCastingMode = ShadowCastingMode.off;

      root
        ..add(pylon)
        ..add(crown);
    }

    // 4 sculpted swept TubeGeometry cathedral arches framing the skyline.
    for (var i = 0; i < 4; i++) {
      final startAngle = (i * math.pi * 0.5) + 0.12;
      final archGeo = GeometryBuilders.buildSanctuaryArch(
        startAngle: startAngle,
        spanAngle: math.pi * 0.5 - 0.24,
        radius: 9.68,
        peakHeight: 5.85,
        tubeRadius: 0.105,
      );
      final archNode = Node(
        name: 'sanctuary_arch_$i',
        mesh: Mesh(archGeo, i.isEven ? trimGoldMat : stoneMat),
      )..shadowStatic = true;
      root.add(archNode);
    }

    // 5. Instanced Floating Crystal Monolith Sanctuary (32 shards, 1 draw call!).
    final crystalMat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(
        initialMood.crystalBaseColor.x,
        initialMood.crystalBaseColor.y,
        initialMood.crystalBaseColor.z,
        1.0,
      )
      ..metallicFactor = 0.65
      ..roughnessFactor = 0.14
      ..emissiveFactor = vm.Vector4(
        initialMood.crystalEmissive.x * 0.45,
        initialMood.crystalEmissive.y * 0.45,
        initialMood.crystalEmissive.z * 0.45,
        1.0,
      );

    final crystalGeo = GeometryBuilders.buildFacetedCrystal(
      radius: 0.38,
      totalHeight: 2.55,
      sides: 6,
    );
    final crystalMesh = InstancedMesh(
      geometry: crystalGeo,
      material: crystalMat,
    );

    final specs = <_MonolithSpec>[];
    final rng = math.Random(42);

    // Inner ring: 12 tall sentinel crystals.
    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * math.pi * 2.0 + 0.14;
      final radius = 5.45 + (i.isEven ? 0.35 : -0.25);
      final scale = 0.78 + rng.nextDouble() * 0.42;
      final baseY = 2.15 + rng.nextDouble() * 1.45;
      specs.add(
        _MonolithSpec(
          angle: angle,
          radius: radius,
          baseY: baseY,
          scale: scale,
          phase: i * 0.65,
          tiltX: (rng.nextDouble() - 0.5) * 0.22,
          tiltZ: (rng.nextDouble() - 0.5) * 0.22,
          spinSpeed: (i.isEven ? 1 : -1) * (0.22 + rng.nextDouble() * 0.25),
        ),
      );
    }

    // Outer ring: 20 smaller floating crystal shards forming a celestial halo.
    for (var i = 0; i < 20; i++) {
      final angle = (i / 20) * math.pi * 2.0;
      final radius = 7.45 + (i % 3) * 0.32;
      final scale = 0.42 + rng.nextDouble() * 0.36;
      final baseY = 1.45 + rng.nextDouble() * 3.1;
      specs.add(
        _MonolithSpec(
          angle: angle,
          radius: radius,
          baseY: baseY,
          scale: scale,
          phase: i * 0.91 + 1.2,
          tiltX: (rng.nextDouble() - 0.5) * 0.36,
          tiltZ: (rng.nextDouble() - 0.5) * 0.36,
          spinSpeed: (i.isEven ? -1 : 1) * (0.30 + rng.nextDouble() * 0.35),
        ),
      );
    }

    for (var i = 0; i < specs.length; i++) {
      final tintShade = 0.78 + (i % 5) * 0.08;
      crystalMesh.addInstance(
        vm.Matrix4.identity(),
        color: vm.Vector4(tintShade, tintShade * 1.04, tintShade * 1.12, 1.0),
      );
    }

    final instancedNode = Node(name: 'instanced_crystal_monoliths')
      ..addComponent(InstancedMeshComponent(crystalMesh));
    root.add(instancedNode);

    // 6. Local reflection probe centered at the astrolabe for rich metallic IBL.
    final probe = ReflectionProbeComponent(
      extents: vm.Vector3(11.0, 9.0, 11.0),
      blendDistance: 2.0,
      faceResolution: 64,
    );
    final probeNode = Node(name: 'sanctuary_reflection_probe')
      ..position = vm.Vector3(0.0, 3.15, 0.0)
      ..addComponent(probe);
    root.add(probeNode);

    final stage = SanctuaryStage._(
      rootNode: root,
      mirrorNode: mirrorNode,
      planarReflector: planarReflector,
      reflectionProbe: probe,
      crystalMesh: crystalMesh,
      monolithSpecs: specs,
      crystalMaterial: crystalMat,
      trimGoldMaterial: trimGoldMat,
      pylonGlowMaterial: pylonGlowMat,
      mirrorFmat: mirrorFmat,
      mirrorFallbackMaterial: mirrorFallback,
    );
    stage.applyMood(initialMood);
    stage.update(dt: 0.0, elapsed: 0.0, surgeEnergy: 0.0);
    return stage;
  }

  /// Launches a glowing shockwave ring expanding across the obsidian mirror floor.
  void triggerFloorShockwave() {
    _shockwaveRadius = 0.35;
    _shockwaveStrength = 1.65;
  }

  void applyMood(MoodConfig config) {
    trimGoldMaterial.baseColorFactor = vm.Vector4(
      config.ringGoldTint.x,
      config.ringGoldTint.y,
      config.ringGoldTint.z,
      1.0,
    );
    pylonGlowMaterial.emissiveFactor = vm.Vector4(
      config.runeColor.x * 2.8,
      config.runeColor.y * 2.8,
      config.runeColor.z * 2.8,
      1.0,
    );
    crystalMaterial
      ..baseColorFactor = vm.Vector4(
        config.crystalBaseColor.x,
        config.crystalBaseColor.y,
        config.crystalBaseColor.z,
        1.0,
      )
      ..emissiveFactor = vm.Vector4(
        config.crystalEmissive.x * 0.42,
        config.crystalEmissive.y * 0.42,
        config.crystalEmissive.z * 0.42,
        1.0,
      );

    if (mirrorFmat != null) {
      mirrorFmat!.parameters
        ..setVec3('obsidian_tint', config.obsidianTint)
        ..setVec3('rune_color', config.runeColor)
        ..setFloat('rune_intensity', config.runeIntensity)
        ..setFloat('reflection_strength', config.reflectionStrength);
    }
  }

  void setPlanarReflectionEnabled(bool enabled, double resolutionScale) {
    planarReflector.resolutionScale = resolutionScale;
    if (mirrorFmat != null) {
      mirrorFmat!.parameters.setFloat(
        'reflection_strength',
        enabled ? 0.80 : 0.0,
      );
    }
  }

  /// Animates the 32 instanced monoliths in one batched update and advances the
  /// floor shockwave ring.
  void update({
    required double dt,
    required double elapsed,
    required double surgeEnergy,
  }) {
    if (_shockwaveStrength > 0.005) {
      _shockwaveRadius += dt * 7.8;
      _shockwaveStrength = math.max(0.0, _shockwaveStrength - dt * 1.15);
    } else {
      _shockwaveStrength = 0.0;
    }

    if (mirrorFmat != null) {
      mirrorFmat!.parameters
        ..setFloat('shockwave_radius', _shockwaveRadius)
        ..setFloat('shockwave_strength', _shockwaveStrength);
    }

    final rot = vm.Quaternion.identity();
    final pos = vm.Vector3.zero();
    final scl = vm.Vector3.zero();

    crystalMesh.updateInstanceTransforms((transforms) {
      for (var i = 0; i < _monolithSpecs.length; i++) {
        final s = _monolithSpecs[i];
        final bob = math.sin(elapsed * 0.95 + s.phase) * 0.34;
        final radialPush = surgeEnergy * 0.55;
        final orbitAngle = s.angle + elapsed * 0.035;
        final r = s.radius + radialPush;

        pos.setValues(
          math.cos(orbitAngle) * r,
          s.baseY + bob + surgeEnergy * 0.35,
          math.sin(orbitAngle) * r,
        );
        rot.setEuler(
          s.tiltX + math.sin(elapsed * 0.6 + s.phase) * 0.06,
          elapsed * s.spinSpeed + s.phase,
          s.tiltZ,
        );
        // Uniform scale keeps normals and specular reflections physically exact.
        scl.setValues(s.scale, s.scale, s.scale);
        transforms[i].setFromTranslationRotationScale(pos, rot, scl);
      }
    }, recomputeWinding: false);
  }
}
