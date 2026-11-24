# Aether Observatory — Flutter Scene 3D Showcase

An interactive, real-time 3D celestial observatory and kinetic forge built with [**`flutter_scene`**](https://pub.dev/packages/flutter_scene) (`^0.24.4`), running on a single Dart codebase across **Web (WebGL2)** and all native Flutter platforms (**iOS, Android, macOS, Windows, Linux** via **Impeller & Flutter GPU**).

🌐 **Live Web Demo (Firebase Hosting):** [https://aether-observatory-3d.web.app](https://aether-observatory-3d.web.app)

---

## What It Showcases (`flutter_scene` Capabilities)

- **Kinetic Armillary Astrolabe:** Four counter-rotating chamfered metallic rings (gilded bronze, brushed titanium, rose copper, cardinal emissive finials) hovering with harmonic motion.
- **Custom GLSL `.fmat` Shaders (compiled via `hook/build.dart`):**
  - [`assets/shaders/aether_core.fmat`](assets/shaders/aether_core.fmat) — Animated 3D domain-warped plasma core with Fresnel spectral iridescence and HDR surge overdrive.
  - [`assets/shaders/obsidian_mirror.fmat`](assets/shaders/obsidian_mirror.fmat) — True real-time **Planar Reflection** mirror pool (`PlanarReflectorComponent` + `GetPlanarReflection()`) with concentric animated sacred-geometry rune inlays and expanding floor shockwaves.
- **Dynamic Lighting, Sky & Shadows:** Synchronized `PhysicalSkySource` / `GradientSkySource`, `SkyEnvironment` IBL baking, `SunLight` cascaded shadow maps, local `ReflectionProbeComponent`, and 3 orbiting chromatic `PointLightComponent` orbs streaming real-time **`TrailComponent`** ribbons.
- **Hardware Geometry Instancing:** 32 faceted hexagonal floating crystal monoliths rendered in a single `InstancedMesh` draw call (`InstancedMeshComponent`).
- **Swept Architectural Geometry:** 4 cathedral sanctuary arches generated with `CatmullRomPath` + `TubeGeometry`.
- **Real-Time Particle Systems & Screen-Space Distortion:**
  - Ambient cosmic stardust (`ParticleEmitterComponent` + `TurbulenceModule` + procedural Gaussian bokeh sprite texture).
  - Interactive **⚡ Aether Surge** supernova burst (`BillboardFacing.velocityStretched` sparks + expanding refractive chromatic **`DistortionPulse`** via `scene.screenDistortion`).
- **Full Post-Processing Stack:** Live-controllable HDR Tone Mapping (`AgX`, `ACES`, `PBR Neutral`), Bloom, Lens Flares, God Rays, Ambient Occlusion, Screen-Space Reflections, Volumetric Exponential Fog, Depth of Field, Chromatic Aberration, and Vignette.
- **Glassmorphic Flutter Studio HUD:** Native translucent Flutter UI composited seamlessly over the live 3D canvas with 4 curated mood presets (**Solaris Gold**, **Neon Void**, **Aurora Spire**, **PBR Studio**), adaptive Quality Tiers (`Ultra` / `Balanced` / `Perf`), live FPS telemetry, and a collapsible Studio Inspector.

---

## Controls & Shortcuts

| Input | Action |
| :--- | :--- |
| **Drag** | Orbit camera smoothly around the sanctuary |
| **Scroll / Pinch** | Zoom (dolly) in and out |
| **Tap / Click** or `Space` | Trigger **⚡ Aether Surge** (core flare, floor shockwave, spark supernova & refractive screen pulse) |
| `1` – `4` | Switch Mood Presets (*Solaris Gold*, *Neon Void*, *Aurora Spire*, *PBR Studio*) |
| `T` | Toggle Cinematic Auto-Tour |
| `I` | Toggle Studio Inspector drawer |
| `H` | Hide / Show HUD for pure full-screen 3D |

---

## Running Across All 6 Platforms

Requires **Flutter 3.47+** (built & verified on **Flutter 3.50.0 / Dart 3.14.0**). Flutter GPU is pre-enabled in all native platform configurations (`Info.plist`, `AndroidManifest.xml`, `main.cpp`, `my_application.cc`).

```bash
# 1. Install dependencies
flutter pub get

# 2. Run on Web (uses flutter_scene's built-in WebGL2 backend — no flags required)
flutter run -d chrome

# 3. Run on Native Platforms (macOS, iOS, Android, Windows, Linux)
flutter run -d macos --enable-flutter-gpu
flutter run -d ios --enable-flutter-gpu
flutter run -d android --enable-flutter-gpu
flutter run -d windows --enable-flutter-gpu
flutter run -d linux --enable-flutter-gpu
```

### Production Web Build & Firebase Hosting Deploy

```bash
flutter build web --release
firebase deploy --only hosting
```

---

## Project Structure

```text
aether_observatory/
├── assets/shaders/
│   ├── aether_core.fmat          # Custom GLSL plasma + Fresnel iridescence core shader
│   └── obsidian_mirror.fmat      # Custom GLSL planar mirror + animated rune shockwave floor
├── hook/build.dart               # flutter_scene build hook compiling .fmat bundles per platform
├── lib/
│   ├── main.dart
│   ├── app/observatory_screen.dart
│   ├── scene/
│   │   ├── observatory_world.dart
│   │   ├── astrolabe_assembly.dart
│   │   ├── sanctuary_stage.dart
│   │   ├── lighting_vfx_controller.dart
│   │   ├── geometry_builders.dart
│   │   └── atmosphere_presets.dart
│   └── ui/
│       ├── glass_surface.dart
│       ├── telemetry_badge.dart
│       ├── mood_switcher_bar.dart
│       └── studio_inspector_panel.dart
├── firebase.json                 # Firebase Hosting SPA & asset caching config
└── pubspec.yaml
```
