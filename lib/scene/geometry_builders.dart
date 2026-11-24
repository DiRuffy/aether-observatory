import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Procedural 3D mesh and texture builders for Aether Observatory.
///
/// Every custom mesh winds triangles counter-clockwise (CCW) around outward
/// normals and leaves normals to `GeometryBuilder` so shading and shadows stay
/// physically accurate without non-uniform scale distortion.
class GeometryBuilders {
  const GeometryBuilders._();

  /// Builds a crisp, double-terminated hexagonal crystal monolith with flat
  /// faceted faces (`deduplicate: false`) so specular glints sparkle sharply
  /// as lights orbit.
  static MeshGeometry buildFacetedCrystal({
    double radius = 0.42,
    double totalHeight = 2.8,
    int sides = 6,
  }) {
    final b = GeometryBuilder(deduplicate: false);
    final halfH = totalHeight * 0.5;
    final bodyHalfH = halfH * 0.62;
    final topApex = vm.Vector3(0, halfH, 0);
    final bottomApex = vm.Vector3(0, -halfH, 0);

    final topRing = <vm.Vector3>[];
    final botRing = <vm.Vector3>[];
    for (var i = 0; i < sides; i++) {
      final a = (i / sides) * math.pi * 2.0;
      final c = math.cos(a);
      final s = math.sin(a);
      // Slight taper toward the upper crown for a natural obelisk silhouette.
      topRing.add(vm.Vector3(c * radius * 0.84, bodyHalfH, s * radius * 0.84));
      botRing.add(vm.Vector3(c * radius, -bodyHalfH, s * radius));
    }

    void addTri(vm.Vector3 p0, vm.Vector3 p1, vm.Vector3 p2) {
      final i0 = b.addVertex(p0);
      final i1 = b.addVertex(p1);
      final i2 = b.addVertex(p2);
      b.addTriangle(i0, i1, i2);
    }

    for (var i = 0; i < sides; i++) {
      final next = (i + 1) % sides;
      final t0 = topRing[i];
      final t1 = topRing[next];
      final b0 = botRing[i];
      final b1 = botRing[next];

      // Upper spire pyramid facet (CCW looking from outside).
      addTri(t0, topApex, t1);
      // Main prismatic shaft quad (two CCW triangles).
      addTri(b0, t0, t1);
      addTri(b0, t1, b1);
      // Lower tapered keel facet.
      addTri(b0, b1, bottomApex);
    }

    return b.build();
  }

  /// Builds a chamfered astronomical armillary ring lying in the XZ plane with
  /// an octagonal beveled cross-section so reflections catch crisp edges.
  static MeshGeometry buildBeveledArmillaryRing({
    required double radius,
    required double radialWidth,
    required double verticalHeight,
    int segments = 96,
  }) {
    final b = GeometryBuilder(deduplicate: false);
    final hw = radialWidth * 0.5;
    final hh = verticalHeight * 0.5;
    final cw = radialWidth * 0.22;
    final ch = verticalHeight * 0.22;

    // 8-point chamfered rectangular cross-section in (dr, dy), ordered CCW
    // around the cross-section center when marching along +angle.
    final profile = <vm.Vector2>[
      vm.Vector2(hw - cw, hh),
      vm.Vector2(hw, hh - ch),
      vm.Vector2(hw, -(hh - ch)),
      vm.Vector2(hw - cw, -hh),
      vm.Vector2(-(hw - cw), -hh),
      vm.Vector2(-hw, -(hh - ch)),
      vm.Vector2(-hw, hh - ch),
      vm.Vector2(-(hw - cw), hh),
    ];

    vm.Vector3 ringPoint(double angle, vm.Vector2 p) {
      final r = radius + p.x;
      return vm.Vector3(math.cos(angle) * r, p.y, math.sin(angle) * r);
    }

    final pCount = profile.length;
    for (var s = 0; s < segments; s++) {
      final a0 = (s / segments) * math.pi * 2.0;
      final a1 = ((s + 1) / segments) * math.pi * 2.0;
      for (var k = 0; k < pCount; k++) {
        final kNext = (k + 1) % pCount;
        final v00 = ringPoint(a0, profile[k]);
        final v01 = ringPoint(a0, profile[kNext]);
        final v10 = ringPoint(a1, profile[k]);
        final v11 = ringPoint(a1, profile[kNext]);

        final i00 = b.addVertex(v00);
        final i01 = b.addVertex(v01);
        final i10 = b.addVertex(v10);
        final i11 = b.addVertex(v11);

        // Outward-facing CCW winding around the chamfered ring.
        b.addTriangle(i00, i11, i01);
        b.addTriangle(i00, i10, i11);
      }
    }

    return b.build();
  }

  /// Builds a faceted octahedron jewel / cardinal marker stud.
  static MeshGeometry buildOctahedron({double radius = 0.22}) {
    final b = GeometryBuilder(deduplicate: false);
    final top = vm.Vector3(0, radius * 1.35, 0);
    final bot = vm.Vector3(0, -radius * 1.35, 0);
    final ring = <vm.Vector3>[
      vm.Vector3(radius, 0, 0),
      vm.Vector3(0, 0, radius),
      vm.Vector3(-radius, 0, 0),
      vm.Vector3(0, 0, -radius),
    ];

    void addTri(vm.Vector3 p0, vm.Vector3 p1, vm.Vector3 p2) {
      final i0 = b.addVertex(p0);
      final i1 = b.addVertex(p1);
      final i2 = b.addVertex(p2);
      b.addTriangle(i0, i1, i2);
    }

    for (var i = 0; i < 4; i++) {
      final next = (i + 1) % 4;
      addTri(ring[i], top, ring[next]);
      addTri(ring[i], ring[next], bot);
    }

    return b.build();
  }

  /// Builds a graceful architectural sweeping arch tube curving over the
  /// sanctuary terrace using `CatmullRomPath` + `TubeGeometry`.
  static TubeGeometry buildSanctuaryArch({
    required double startAngle,
    required double spanAngle,
    required double radius,
    required double peakHeight,
    double tubeRadius = 0.095,
  }) {
    const sampleCount = 13;
    final pts = <vm.Vector3>[];
    for (var i = 0; i < sampleCount; i++) {
      final t = i / (sampleCount - 1);
      final angle = startAngle + spanAngle * t;
      final arch = math.sin(t * math.pi);
      // Slight inward lean toward the crown for dramatic cathedral silhouette.
      final r = radius - arch * 1.15;
      final y = 0.12 + math.pow(arch, 0.82).toDouble() * peakHeight;
      pts.add(vm.Vector3(math.cos(angle) * r, y, math.sin(angle) * r));
    }
    final path = CatmullRomPath(pts);
    return TubeGeometry(
      path,
      radius: tubeRadius,
      radialSegments: 10,
      stations: 48,
      caps: true,
    );
  }

  /// Procedurally generates a velvety radial glow bokeh texture (64x64 RGBA8)
  /// for luminous additive particle sprites without external image files.
  static Texture2D buildSoftGlowSpriteTexture({int size = 64}) {
    final pixels = Uint8List(size * size * 4);
    final half = (size - 1) * 0.5;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final dx = (x - half) / half;
        final dy = (y - half) / half;
        final d = math.sqrt(dx * dx + dy * dy);
        // Smooth core hotspot + soft Gaussian halo fading cleanly to 0 at edges.
        final halo = math.max(0.0, 1.0 - d);
        final soft = math.pow(halo, 2.4).toDouble();
        final core = math.pow(halo, 7.0).toDouble();
        final alpha = ((soft * 0.78 + core * 0.45).clamp(0.0, 1.0) * 255)
            .round();
        final idx = (y * size + x) * 4;
        pixels[idx] = 255;
        pixels[idx + 1] = 255;
        pixels[idx + 2] = 255;
        pixels[idx + 3] = alpha;
      }
    }
    return Texture2D.fromPixels(
      pixels,
      size,
      size,
      sampling: const TextureSampling(mipmaps: false),
    );
  }
}
