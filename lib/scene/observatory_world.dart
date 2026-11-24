import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'astrolabe_assembly.dart';
import 'atmosphere_presets.dart';
import 'lighting_vfx_controller.dart';
import 'sanctuary_stage.dart';

/// Master orchestrator and state controller for Aether Observatory.
///
/// Owns the `flutter_scene` [Scene], camera rig (`OrbitCameraController`),
/// kinetic centerpiece, architectural sanctuary, lighting/VFX, post-processing
/// settings, and live telemetry.
class ObservatoryWorld extends ChangeNotifier {
  ObservatoryWorld({QualityTier? initialQuality})
      : _quality = initialQuality ?? (kIsWeb ? QualityTier.balanced : QualityTier.ultra);

  final Scene scene = Scene();

  late final OrbitCameraController cameraController;
  late final CameraComponent _cameraComponent;
  late final Node _cameraNode;

  AstrolabeAssembly? _astrolabe;
  SanctuaryStage? _stage;
  LightingVfxController? _vfx;

  bool _isReady = false;
  Object? _initError;

  // Active high-level presets.
  ObservatoryMood _mood = ObservatoryMood.solarisGold;
  QualityTier _quality;
  CameraPreset _activeCameraPreset = CameraPreset.establishing;

  // Interactive toggles & sliders.
  bool _autoTour = true;
  bool _shadowsEnabled = true;
  bool _planarReflectionsEnabled = true;
  bool _bloomEnabled = true;
  bool _lensFlareEnabled = true;
  bool _godRaysEnabled = true;
  bool _aoEnabled = true;
  bool _ssrEnabled = false;
  bool _fogEnabled = true;
  bool _vignetteEnabled = true;
  bool _chromaticAberrationEnabled = false;
  bool _depthOfFieldEnabled = false;

  ToneMappingMode _toneMapping = ToneMappingMode.agx;
  double _exposure = 1.05;
  double _bloomIntensity = 0.28;
  double _sunElevationDeg = 13.0;
  double _sunAzimuthDeg = -145.0;
  double _kineticSpeed = 1.0;

  // Live material overrides.
  double _metallic = 0.96;
  double _roughness = 0.18;
  double _coreGlow = 2.7;
  double _iridescence = 0.75;

  // Surge physics & cinematic intro reveal state.
  double _surgeEnergy = 0.0;
  double _elapsed = 0.0;
  double _introProgress = 0.0;
  bool _introActive = true;
  int _surgeCount = 0;

  // Rolling FPS telemetry (updated at ~4 Hz to avoid unnecessary UI rebuilds).
  double _fps = 60.0;
  double _frameMs = 16.6;
  double _fpsAccumTime = 0.0;
  int _fpsAccumFrames = 0;

  // Public getters.
  bool get isReady => _isReady;
  Object? get initError => _initError;
  ObservatoryMood get mood => _mood;
  MoodConfig get moodConfig => kMoodConfigs[_mood]!;
  QualityTier get quality => _quality;
  CameraPreset get activeCameraPreset => _activeCameraPreset;
  bool get autoTour => _autoTour;
  bool get shadowsEnabled => _shadowsEnabled;
  bool get planarReflectionsEnabled => _planarReflectionsEnabled;
  bool get bloomEnabled => _bloomEnabled;
  bool get lensFlareEnabled => _lensFlareEnabled;
  bool get godRaysEnabled => _godRaysEnabled;
  bool get aoEnabled => _aoEnabled;
  bool get ssrEnabled => _ssrEnabled;
  bool get fogEnabled => _fogEnabled;
  bool get vignetteEnabled => _vignetteEnabled;
  bool get chromaticAberrationEnabled => _chromaticAberrationEnabled;
  bool get depthOfFieldEnabled => _depthOfFieldEnabled;
  ToneMappingMode get toneMapping => _toneMapping;
  double get exposure => _exposure;
  double get bloomIntensity => _bloomIntensity;
  double get sunElevationDeg => _sunElevationDeg;
  double get sunAzimuthDeg => _sunAzimuthDeg;
  double get kineticSpeed => _kineticSpeed;
  double get metallic => _metallic;
  double get roughness => _roughness;
  double get coreGlow => _coreGlow;
  double get iridescence => _iridescence;
  double get surgeEnergy => _surgeEnergy;
  int get surgeCount => _surgeCount;
  double get fps => _fps;
  double get frameMs => _frameMs;

  String get backendLabel =>
      kIsWeb ? 'WebGL2 · Flutter Scene' : 'Impeller · Flutter GPU';

  /// Initializes engine static resources and constructs the entire 3D world.
  Future<void> initialize() async {
    try {
      await Scene.initializeStaticResources();

      // Configure camera node with built-in OrbitCameraController (smooth damping).
      _cameraComponent = CameraComponent(
        projection: PerspectiveProjection(
          fovRadiansY: 46.0 * math.pi / 180.0,
          near: 0.15,
          far: 180.0,
        ),
        activateOnMount: true,
      );
      cameraController = OrbitCameraController(
        target: vm.Vector3(0.0, 2.35, 0.0),
        distance: 17.5,
        azimuth: -0.35,
        polar: 0.12,
        minDistance: 3.6,
        maxDistance: 28.0,
        minPolar: 0.05,
        maxPolar: 1.38,
        rotateSpeed: math.pi * 1.1,
        dollySpeed: 0.18,
        smoothing: 0.14,
      );

      _cameraNode = Node(name: 'observatory_camera')
        ..addComponent(_cameraComponent)
        ..addComponent(cameraController);
      scene.add(_cameraNode);

      final initialConfig = kMoodConfigs[_mood]!;
      _loadDefaultsFromConfig(initialConfig);

      // Build centerpiece astrolabe, architectural sanctuary, and VFX/lighting.
      _astrolabe = await AstrolabeAssembly.create(initialMood: initialConfig);
      _stage = await SanctuaryStage.create(
        initialMood: initialConfig,
        initialQuality: _quality,
      );
      _vfx = LightingVfxController.create(
        scene: scene,
        initialMood: initialConfig,
      );

      scene.add(_stage!.rootNode);
      scene.add(_astrolabe!.rootNode);

      _applyQualityToScene();
      _applyAtmosphereAndLook();

      // Request initial reflection probe capture once world is mounted.
      _stage!.reflectionProbe.requestCapture();

      // Start cinematic intro sweep into Establishing shot.
      _introActive = true;
      _introProgress = 0.0;

      _isReady = true;
      _initError = null;
      notifyListeners();
    } catch (error) {
      _initError = error;
      notifyListeners();
    }
  }

  /// Called every frame by `SceneView.onTick`.
  void onTick(Duration elapsed, double deltaSeconds) {
    if (!_isReady) return;
    final dt = deltaSeconds.clamp(0.0, 0.05);
    _elapsed += dt;

    // Update rolling FPS telemetry ~4 times per second.
    _fpsAccumTime += deltaSeconds;
    _fpsAccumFrames++;
    if (_fpsAccumTime >= 0.25) {
      final avgDt = _fpsAccumTime / _fpsAccumFrames;
      if (avgDt > 0.0001) {
        _fps = (1.0 / avgDt).clamp(1.0, 240.0);
        _frameMs = (avgDt * 1000.0).clamp(0.1, 250.0);
      }
      _fpsAccumTime = 0.0;
      _fpsAccumFrames = 0;
      notifyListeners();
    }

    // Smooth exponential decay of Aether Surge energy.
    if (_surgeEnergy > 0.001) {
      _surgeEnergy = math.max(0.0, _surgeEnergy * math.exp(-dt * 1.45));
    } else {
      _surgeEnergy = 0.0;
    }

    // Cinematic first-load swoop into the establishing frame.
    if (_introActive) {
      _introProgress = (_introProgress + dt * 0.45).clamp(0.0, 1.0);
      cameraController.orbitBy(dt * 0.36, dt * 0.10);
      cameraController.dollyBy(dt * 0.65);
      if (_introProgress >= 1.0) {
        _introActive = false;
      }
    } else if (_autoTour) {
      // Silky slow orbital showcase motion with gentle vertical breathing.
      final polarBreath = math.sin(_elapsed * 0.32) * 0.025 * dt;
      cameraController.orbitBy(dt * 0.16, polarBreath);
    }

    _astrolabe?.update(
      dt: dt,
      elapsed: _elapsed,
      speedScale: _kineticSpeed,
      surgeEnergy: _surgeEnergy,
    );
    _stage?.update(
      dt: dt,
      elapsed: _elapsed,
      surgeEnergy: _surgeEnergy,
    );
    _vfx?.update(
      dt: dt,
      speedScale: _kineticSpeed,
      surgeEnergy: _surgeEnergy,
    );
  }

  /// Called when the user drags/scrolls the 3D viewport to smoothly yield intro/tour.
  void notifyUserCameraInteraction() {
    if (_introActive) {
      _introActive = false;
    }
  }

  /// Fires the signature "Aether Surge": core overdrive, ring turbo spin,
  /// expanding obsidian floor shockwave, supernova spark burst, and screen-space
  /// refractive distortion ring!
  void triggerSurge({Offset? normalizedScreenCenter}) {
    if (!_isReady) return;
    _surgeEnergy = 1.35;
    _surgeCount++;
    _stage?.triggerFloorShockwave();
    _vfx?.triggerSurge(normalizedScreenCenter: normalizedScreenCenter);
    notifyListeners();
  }

  /// Switches to one of the 4 curated atmosphere & post-processing moods.
  void selectMood(ObservatoryMood next) {
    if (!_isReady) return;
    _mood = next;
    final config = kMoodConfigs[next]!;
    _loadDefaultsFromConfig(config);
    _astrolabe?.applyMood(config);
    _astrolabe?.applyMaterialOverrides(
      metallic: _metallic,
      roughness: _roughness,
      coreGlow: _coreGlow,
      iridescence: _iridescence,
      flowSpeed: _kineticSpeed,
    );
    _stage?.applyMood(config);
    _applyAtmosphereAndLook();
    _stage?.reflectionProbe.requestCapture();
    notifyListeners();
  }

  /// Selects a camera framing bookmark.
  void selectCameraPreset(CameraPreset preset) {
    if (!_isReady) return;
    _activeCameraPreset = preset;
    _introActive = false;
    cameraController.target = vm.Vector3(0.0, preset.targetY, 0.0);
    // Nudge orbit smoothly via controller framing + delta.
    final currentDist = cameraController.distance;
    if (currentDist > 0.1 && preset.distance > 0.1) {
      final ratio = math.log(currentDist / preset.distance) /
          cameraController.dollySpeed;
      cameraController.dollyBy(ratio);
    }
    cameraController.orbitBy(preset.azimuth * 0.45, 0.0);
    notifyListeners();
  }

  void setQuality(QualityTier tier) {
    if (_quality == tier) return;
    _quality = tier;
    if (_isReady) {
      _applyQualityToScene();
      _applyAtmosphereAndLook();
    }
    notifyListeners();
  }

  void setAutoTour(bool value) {
    _autoTour = value;
    if (value) _introActive = false;
    notifyListeners();
  }

  void setSunAngles({double? elevationDeg, double? azimuthDeg}) {
    if (elevationDeg != null) _sunElevationDeg = elevationDeg;
    if (azimuthDeg != null) _sunAzimuthDeg = azimuthDeg;
    if (_isReady) {
      _vfx?.applyAtmosphere(
        config: moodConfig,
        sunElevationDeg: _sunElevationDeg,
        sunAzimuthDeg: _sunAzimuthDeg,
        quality: _quality,
        shadowsEnabled: _shadowsEnabled,
      );
      _applyLookSettings();
    }
    notifyListeners();
  }

  void setKineticSpeed(double value) {
    _kineticSpeed = value;
    _pushMaterialOverrides();
    notifyListeners();
  }

  void setShadowsEnabled(bool value) {
    _shadowsEnabled = value;
    if (_isReady) _applyAtmosphereAndLook();
    notifyListeners();
  }

  void setPlanarReflectionsEnabled(bool value) {
    _planarReflectionsEnabled = value;
    _stage?.setPlanarReflectionEnabled(value, _quality.planarReflectionScale);
    notifyListeners();
  }

  void setBloom({bool? enabled, double? intensity}) {
    if (enabled != null) _bloomEnabled = enabled;
    if (intensity != null) _bloomIntensity = intensity;
    if (_isReady) _applyLookSettings();
    notifyListeners();
  }

  void setLensFlareEnabled(bool value) {
    _lensFlareEnabled = value;
    if (_isReady) _applyLookSettings();
    notifyListeners();
  }

  void setGodRaysEnabled(bool value) {
    _godRaysEnabled = value;
    if (_isReady) _applyLookSettings();
    notifyListeners();
  }

  void setAoEnabled(bool value) {
    _aoEnabled = value;
    if (_isReady) _applyLookSettings();
    notifyListeners();
  }

  void setSsrEnabled(bool value) {
    _ssrEnabled = value;
    if (_isReady) _applyLookSettings();
    notifyListeners();
  }

  void setFogEnabled(bool value) {
    _fogEnabled = value;
    if (_isReady) _applyLookSettings();
    notifyListeners();
  }

  void setVignetteEnabled(bool value) {
    _vignetteEnabled = value;
    if (_isReady) _applyLookSettings();
    notifyListeners();
  }

  void setChromaticAberrationEnabled(bool value) {
    _chromaticAberrationEnabled = value;
    if (_isReady) _applyLookSettings();
    notifyListeners();
  }

  void setDepthOfFieldEnabled(bool value) {
    _depthOfFieldEnabled = value;
    if (_isReady) _applyLookSettings();
    notifyListeners();
  }

  void setToneMapping(ToneMappingMode mode) {
    _toneMapping = mode;
    if (_isReady) _applyLookSettings();
    notifyListeners();
  }

  void setExposure(double value) {
    _exposure = value;
    if (_isReady) _applyLookSettings();
    notifyListeners();
  }

  void setMaterialOverrides({
    double? metallic,
    double? roughness,
    double? coreGlow,
    double? iridescence,
  }) {
    if (metallic != null) _metallic = metallic;
    if (roughness != null) _roughness = roughness;
    if (coreGlow != null) _coreGlow = coreGlow;
    if (iridescence != null) _iridescence = iridescence;
    _pushMaterialOverrides();
    notifyListeners();
  }

  void _pushMaterialOverrides() {
    _astrolabe?.applyMaterialOverrides(
      metallic: _metallic,
      roughness: _roughness,
      coreGlow: _coreGlow,
      iridescence: _iridescence,
      flowSpeed: _kineticSpeed,
    );
  }

  void _loadDefaultsFromConfig(MoodConfig config) {
    _sunElevationDeg = config.sunElevationDeg;
    _sunAzimuthDeg = config.sunAzimuthDeg;
    _toneMapping = config.toneMapping;
    _exposure = config.exposure;
    _bloomEnabled = config.bloomEnabled;
    _bloomIntensity = config.bloomIntensity;
    _lensFlareEnabled = config.lensFlareEnabled;
    _godRaysEnabled = config.godRaysEnabled && _quality.allowGodRays;
    _aoEnabled = config.aoEnabled && _quality.allowAo;
    _ssrEnabled = config.ssrEnabled && _quality.allowSsr;
    _fogEnabled = config.fogEnabled;
    _vignetteEnabled = config.vignetteEnabled;
    _chromaticAberrationEnabled = config.chromaticAberrationEnabled;
    _coreGlow = config.coreIntensity;
  }

  void _applyQualityToScene() {
    scene.renderScale = _quality.renderScale;
    scene.antiAliasingMode = _quality == QualityTier.performance
        ? AntiAliasingMode.fxaa
        : AntiAliasingMode.auto;
    _stage?.setPlanarReflectionEnabled(
      _planarReflectionsEnabled,
      _quality.planarReflectionScale,
    );
  }

  void _applyAtmosphereAndLook() {
    _vfx?.applyAtmosphere(
      config: moodConfig,
      sunElevationDeg: _sunElevationDeg,
      sunAzimuthDeg: _sunAzimuthDeg,
      quality: _quality,
      shadowsEnabled: _shadowsEnabled,
    );
    _applyLookSettings();
  }

  void _applyLookSettings() {
    final config = moodConfig;
    final effectiveGodRays =
        _godRaysEnabled && _shadowsEnabled && _quality.allowGodRays;

    scene.environmentSettings = EnvironmentSettings(
      // Preserve active sky & lighting references managed by LightingVfxController.
      environment: scene.environment,
      skybox: scene.skybox,
      skyEnvironment: scene.skyEnvironment,
      sunLight: scene.sunLight,
      toneMapping: _toneMapping,
      exposure: _exposure,
      environmentIntensity: config.environmentIntensity,
      bloomEnabled: _bloomEnabled,
      bloomThreshold: config.bloomThreshold,
      bloomIntensity: _bloomIntensity,
      bloomScatter: config.bloomScatter,
      lensFlareEnabled: _bloomEnabled && _lensFlareEnabled,
      lensFlareIntensity: config.lensFlareIntensity,
      lensFlareGhostCount: 4,
      lensFlareGhostSpacing: 0.28,
      lensFlareHaloRadius: 0.32,
      lensFlareHaloIntensity: 0.35,
      lensFlareChromaticAberration: 0.007,
      colorGradingEnabled: config.colorGradingEnabled,
      contrast: config.contrast,
      saturation: config.saturation,
      temperature: config.temperature,
      vignetteEnabled: _vignetteEnabled,
      vignetteIntensity: config.vignetteIntensity,
      vignetteRadius: 0.78,
      vignetteSmoothness: 0.52,
      chromaticAberrationEnabled: _chromaticAberrationEnabled,
      chromaticAberrationIntensity: config.chromaticAberrationIntensity,
      ambientOcclusionEnabled: _aoEnabled,
      ambientOcclusionMethod: AmbientOcclusionMethod.obscurance,
      ambientOcclusionIntensity: 0.95,
      ambientOcclusionRadius: 0.55,
      ambientOcclusionHalfResolution: true,
      screenSpaceReflectionsEnabled: _ssrEnabled,
      screenSpaceReflectionsIntensity: 0.75,
      screenSpaceReflectionsResolutionScale: 0.6,
      fogEnabled: _fogEnabled,
      fogMode: FogMode.exponential,
      fogColor: config.fogColor.clone(),
      fogDensity: config.fogDensity,
      fogSkyColorInfluence: 0.35,
      godRaysEnabled: effectiveGodRays,
      godRaysIntensity: config.godRaysIntensity,
      godRaysDensity: 0.52,
      godRaysAnisotropy: 0.74,
      godRaysStepCount: _quality.godRaySteps,
      godRaysMaxDistance: 85.0,
      godRaysColor: config.godRaysColor.clone(),
      depthOfFieldEnabled: _depthOfFieldEnabled,
      depthOfFieldFocusDistance: cameraController.distance.clamp(3.0, 24.0),
      depthOfFieldFStop: 2.2,
      depthOfFieldQuality: DepthOfFieldQuality.low,
    );
  }
}
