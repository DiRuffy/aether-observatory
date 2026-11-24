import 'dart:math' as math;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'atmosphere_presets.dart';
import 'geometry_builders.dart';

/// Centerpiece Kinetic Armillary Astrolabe with custom GLSL Prismatic Core,
/// counter-rotating chamfered metallic rings, and cardinal emissive beacons.
class AstrolabeAssembly {
  AstrolabeAssembly._({
    required this.rootNode,
    required this.coreNode,
    required this.haloNode,
    required this.outerRingNode,
    required this.midRingNode,
    required this.innerRingNode,
    required this.stabilizerRingNode,
    required this.goldMaterial,
    required this.titaniumMaterial,
    required this.copperMaterial,
    required this.beaconMaterial,
    required this.haloMaterial,
    this.coreFmat,
    this.coreFallbackMaterial,
  });

  final Node rootNode;
  final Node coreNode;
  final Node haloNode;
  final Node outerRingNode;
  final Node midRingNode;
  final Node innerRingNode;
  final Node stabilizerRingNode;

  final PhysicallyBasedMaterial goldMaterial;
  final PhysicallyBasedMaterial titaniumMaterial;
  final PhysicallyBasedMaterial copperMaterial;
  final PhysicallyBasedMaterial beaconMaterial;
  final PhysicallyBasedMaterial haloMaterial;
  final PreprocessedMaterial? coreFmat;
  final PhysicallyBasedMaterial? coreFallbackMaterial;

  double _phaseOuter = 0.0;
  double _phaseMid = 0.0;
  double _phaseInner = 0.0;
  double _phaseStab = 0.0;
  double _phaseCore = 0.0;

  static Future<AstrolabeAssembly> create({
    required MoodConfig initialMood,
  }) async {
    final root = Node(name: 'astrolabe_root')
      ..position = vm.Vector3(0.0, 3.15, 0.0);

    // Calibrated PBR metallic materials (shared across ring assemblies).
    final goldMat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(
        initialMood.ringGoldTint.x,
        initialMood.ringGoldTint.y,
        initialMood.ringGoldTint.z,
        1.0,
      )
      ..metallicFactor = 0.96
      ..roughnessFactor = 0.18;

    final titaniumMat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(
        initialMood.ringTitaniumTint.x,
        initialMood.ringTitaniumTint.y,
        initialMood.ringTitaniumTint.z,
        1.0,
      )
      ..metallicFactor = 0.92
      ..roughnessFactor = 0.26;

    final copperMat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.88, 0.48, 0.32, 1.0)
      ..metallicFactor = 0.94
      ..roughnessFactor = 0.22;

    final beaconMat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.95, 0.98, 1.0, 1.0)
      ..metallicFactor = 0.1
      ..roughnessFactor = 0.2
      ..emissiveFactor = vm.Vector4(
        initialMood.corePrimary.x * 3.6,
        initialMood.corePrimary.y * 3.6,
        initialMood.corePrimary.z * 3.6,
        1.0,
      );

    final haloMat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.9, 0.95, 1.0, 1.0)
      ..metallicFactor = 0.2
      ..roughnessFactor = 0.15
      ..emissiveFactor = vm.Vector4(
        initialMood.coreSecondary.x * 2.8,
        initialMood.coreSecondary.y * 2.8,
        initialMood.coreSecondary.z * 2.8,
        1.0,
      );

    // Load custom .fmat Prismatic Energy Core shader with safe fallback.
    PreprocessedMaterial? coreFmat;
    PhysicallyBasedMaterial? coreFallback;
    try {
      coreFmat = await loadFmatMaterial('assets/shaders/aether_core.fmat');
    } catch (e) {
      debugPrint('AetherCore .fmat fallback active: $e');
      coreFallback = PhysicallyBasedMaterial()
        ..baseColorFactor = vm.Vector4(0.12, 0.35, 0.55, 1.0)
        ..metallicFactor = 0.85
        ..roughnessFactor = 0.12
        ..emissiveFactor = vm.Vector4(
          initialMood.corePrimary.x * 3.2,
          initialMood.corePrimary.y * 3.2,
          initialMood.corePrimary.z * 3.2,
          1.0,
        );
    }

    final coreMaterial = coreFmat ?? coreFallback!;
    final coreNode = Node(
      name: 'aether_core',
      mesh: Mesh(
        IcosphereGeometry(radius: 0.74, subdivisions: 3),
        coreMaterial,
      ),
    );
    root.add(coreNode);

    // Equatorial glowing energy ring hugging the core.
    final haloNode = Node(
      name: 'core_halo',
      mesh: Mesh(
        TorusGeometry(
          radius: 1.08,
          tubeRadius: 0.028,
          radialSegments: 64,
          tubularSegments: 14,
        ),
        haloMat,
      ),
    );
    root.add(haloNode);

    // Reusable jewel finial geometry for cardinal ring studs.
    final jewelGeo = GeometryBuilders.buildOctahedron(radius: 0.13);
    final studGeo = SphereGeometry(radius: 0.075, segments: 16, rings: 10);

    Node buildRingAssembly({
      required String name,
      required double radius,
      required double width,
      required double height,
      required PhysicallyBasedMaterial ringMaterial,
      required int markerCount,
      required bool useJewels,
    }) {
      final ringNode = Node(
        name: name,
        mesh: Mesh(
          GeometryBuilders.buildBeveledArmillaryRing(
            radius: radius,
            radialWidth: width,
            verticalHeight: height,
            segments: 88,
          ),
          ringMaterial,
        ),
      );
      for (var i = 0; i < markerCount; i++) {
        final angle = (i / markerCount) * math.pi * 2.0;
        final markerRadius = radius + width * 0.52;
        final marker = Node(
          name: '${name}_marker_$i',
          mesh: Mesh(useJewels ? jewelGeo : studGeo, beaconMat),
        )..position = vm.Vector3(
          math.cos(angle) * markerRadius,
          0.0,
          math.sin(angle) * markerRadius,
        );
        ringNode.add(marker);
      }
      return ringNode;
    }

    // 4 concentric gyroscopic armillary rings (zero coplanar intersections).
    final outerRing = buildRingAssembly(
      name: 'outer_meridian_ring',
      radius: 3.05,
      width: 0.22,
      height: 0.14,
      ringMaterial: goldMat,
      markerCount: 8,
      useJewels: true,
    );
    final midRing = buildRingAssembly(
      name: 'mid_ecliptic_ring',
      radius: 2.48,
      width: 0.18,
      height: 0.12,
      ringMaterial: titaniumMat,
      markerCount: 6,
      useJewels: false,
    );
    final innerRing = buildRingAssembly(
      name: 'inner_gyro_ring',
      radius: 1.92,
      width: 0.16,
      height: 0.10,
      ringMaterial: copperMat,
      markerCount: 4,
      useJewels: true,
    );
    final stabRing = buildRingAssembly(
      name: 'stabilizer_ring',
      radius: 1.42,
      width: 0.11,
      height: 0.08,
      ringMaterial: goldMat,
      markerCount: 4,
      useJewels: false,
    );

    // Subtle vertical celestial compass spire above & below the core.
    final upperSpire = Node(
      name: 'polar_spire_top',
      mesh: Mesh(
        CylinderGeometry(
          bottomRadius: 0.055,
          topRadius: 0.008,
          height: 1.35,
          radialSegments: 12,
        ),
        goldMat,
      ),
    )..position = vm.Vector3(0.0, 1.95, 0.0);

    final lowerSpire = Node(
      name: 'polar_spire_bottom',
      mesh: Mesh(
        CylinderGeometry(
          bottomRadius: 0.008,
          topRadius: 0.055,
          height: 1.35,
          radialSegments: 12,
        ),
        goldMat,
      ),
    )..position = vm.Vector3(0.0, -1.95, 0.0);

    outerRing.add(upperSpire);
    outerRing.add(lowerSpire);

    root
      ..add(outerRing)
      ..add(midRing)
      ..add(innerRing)
      ..add(stabRing);

    final assembly = AstrolabeAssembly._(
      rootNode: root,
      coreNode: coreNode,
      haloNode: haloNode,
      outerRingNode: outerRing,
      midRingNode: midRing,
      innerRingNode: innerRing,
      stabilizerRingNode: stabRing,
      goldMaterial: goldMat,
      titaniumMaterial: titaniumMat,
      copperMaterial: copperMat,
      beaconMaterial: beaconMat,
      haloMaterial: haloMat,
      coreFmat: coreFmat,
      coreFallbackMaterial: coreFallback,
    );
    assembly.applyMood(initialMood);
    return assembly;
  }

  /// Applies palette and shader parameters for the active mood.
  void applyMood(MoodConfig config) {
    goldMaterial.baseColorFactor = vm.Vector4(
      config.ringGoldTint.x,
      config.ringGoldTint.y,
      config.ringGoldTint.z,
      1.0,
    );
    titaniumMaterial.baseColorFactor = vm.Vector4(
      config.ringTitaniumTint.x,
      config.ringTitaniumTint.y,
      config.ringTitaniumTint.z,
      1.0,
    );
    beaconMaterial.emissiveFactor = vm.Vector4(
      config.corePrimary.x * 3.8,
      config.corePrimary.y * 3.8,
      config.corePrimary.z * 3.8,
      1.0,
    );
    haloMaterial.emissiveFactor = vm.Vector4(
      config.coreSecondary.x * 3.0,
      config.coreSecondary.y * 3.0,
      config.coreSecondary.z * 3.0,
      1.0,
    );
    if (coreFmat != null) {
      coreFmat!.parameters
        ..setVec3('primary_color', config.corePrimary)
        ..setVec3('secondary_color', config.coreSecondary)
        ..setFloat('energy_intensity', config.coreIntensity);
    } else if (coreFallbackMaterial != null) {
      coreFallbackMaterial!.emissiveFactor = vm.Vector4(
        config.corePrimary.x * config.coreIntensity,
        config.corePrimary.y * config.coreIntensity,
        config.corePrimary.z * config.coreIntensity,
        1.0,
      );
    }
  }

  /// Updates live inspector material controls.
  void applyMaterialOverrides({
    required double metallic,
    required double roughness,
    required double coreGlow,
    required double iridescence,
    required double flowSpeed,
  }) {
    goldMaterial
      ..metallicFactor = metallic
      ..roughnessFactor = roughness;
    titaniumMaterial
      ..metallicFactor = (metallic * 0.96).clamp(0.0, 1.0)
      ..roughnessFactor = (roughness + 0.08).clamp(0.04, 1.0);
    copperMaterial
      ..metallicFactor = (metallic * 0.98).clamp(0.0, 1.0)
      ..roughnessFactor = (roughness + 0.04).clamp(0.04, 1.0);

    if (coreFmat != null) {
      coreFmat!.parameters
        ..setFloat('energy_intensity', coreGlow)
        ..setFloat('iridescence_amount', iridescence)
        ..setFloat('flow_speed', flowSpeed);
    }
  }

  /// Advances gyroscopic kinematics, harmonic floating, and surge overdrive.
  void update({
    required double dt,
    required double elapsed,
    required double speedScale,
    required double surgeEnergy,
  }) {
    final boost = 1.0 + surgeEnergy * 3.8;
    final step = dt * speedScale * boost;

    _phaseOuter += step * 0.24;
    _phaseMid += step * 0.42;
    _phaseInner += step * 0.68;
    _phaseStab += step * 1.05;
    _phaseCore += step * 0.55;

    // Gentle levitation of the entire astrolabe assembly.
    final hoverY = 3.15 + math.sin(elapsed * 0.95) * 0.14 + surgeEnergy * 0.18;
    rootNode.position = vm.Vector3(0.0, hoverY, 0.0);

    // Core slow counter-rotation + harmonic scale pulse (uniform scale only!).
    final coreScale = 1.0 + math.sin(elapsed * 2.4) * 0.03 + surgeEnergy * 0.14;
    coreNode
      ..rotation = vm.Quaternion.euler(_phaseCore * 0.4, _phaseCore, 0.25)
      ..scale = vm.Vector3.all(coreScale);

    // Tilted equatorial halo.
    haloNode.rotation = vm.Quaternion.euler(
      0.55 + math.sin(elapsed * 0.8) * 0.25,
      -_phaseInner * 1.35,
      0.35,
    );

    // Multi-axis counter-rotating gyroscopic rings.
    outerRingNode.rotation = vm.Quaternion.euler(
      0.22 * math.sin(_phaseOuter * 0.7),
      _phaseOuter,
      0.16 * math.cos(_phaseOuter * 0.5),
    );
    midRingNode.rotation = vm.Quaternion.euler(
      0.72 + _phaseMid * 0.55,
      -_phaseMid * 0.82,
      0.38,
    );
    innerRingNode.rotation = vm.Quaternion.euler(
      -_phaseInner * 0.75,
      _phaseInner * 0.45,
      1.05 + _phaseInner * 0.35,
    );
    stabilizerRingNode.rotation = vm.Quaternion.euler(
      _phaseStab * 0.9,
      -_phaseStab * 1.15,
      -_phaseStab * 0.4,
    );

    if (coreFmat != null) {
      coreFmat!.parameters.setFloat('surge_energy', surgeEnergy);
    }
  }
}
