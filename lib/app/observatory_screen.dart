import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scene/scene.dart';

import '../scene/atmosphere_presets.dart';
import '../scene/observatory_world.dart';
import '../ui/glass_surface.dart';
import '../ui/mood_switcher_bar.dart';
import '../ui/studio_inspector_panel.dart';
import '../ui/telemetry_badge.dart';

/// Full-viewport interactive 3D showcase screen combining `SceneView`,
/// `CameraControls`, tap-to-surge shockwaves, keyboard shortcuts, and the
/// glassmorphic Studio HUD.
class ObservatoryScreen extends StatefulWidget {
  const ObservatoryScreen({super.key});

  @override
  State<ObservatoryScreen> createState() => _ObservatoryScreenState();
}

class _ObservatoryScreenState extends State<ObservatoryScreen> {
  late final ObservatoryWorld _world;
  final FocusNode _keyboardFocusNode = FocusNode();

  bool _hudVisible = true;
  bool _inspectorOpen = false;
  bool _hintVisible = true;

  Offset? _pointerDownPos;
  DateTime? _pointerDownTime;

  @override
  void initState() {
    super.initState();
    _world = ObservatoryWorld()..addListener(_onWorldChanged);
    _world.initialize();

    // Auto-fade the onboarding interaction hint after 7 seconds.
    Future<void>.delayed(const Duration(seconds: 7), () {
      if (mounted && _hintVisible) {
        setState(() => _hintVisible = false);
      }
    });
  }

  void _onWorldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _world.removeListener(_onWorldChanged);
    _world.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space) {
      _world.triggerSurge();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit1) {
      _world.selectMood(ObservatoryMood.solarisGold);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit2) {
      _world.selectMood(ObservatoryMood.neonVoid);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit3) {
      _world.selectMood(ObservatoryMood.auroraSpire);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit4) {
      _world.selectMood(ObservatoryMood.pbrStudio);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyT) {
      _world.setAutoTour(!_world.autoTour);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyI) {
      setState(() {
        _hudVisible = true;
        _inspectorOpen = !_inspectorOpen;
      });
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyH) {
      setState(() => _hudVisible = !_hudVisible);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onViewportPointerDown(PointerDownEvent event) {
    _pointerDownPos = event.localPosition;
    _pointerDownTime = DateTime.now();
  }

  void _onViewportPointerMove(PointerMoveEvent event) {
    if (_pointerDownPos != null &&
        (event.localPosition - _pointerDownPos!).distance > 8.0) {
      _world.notifyUserCameraInteraction();
      if (_hintVisible) setState(() => _hintVisible = false);
    }
  }

  void _onViewportPointerUp(PointerUpEvent event, Size viewportSize) {
    final downPos = _pointerDownPos;
    final downTime = _pointerDownTime;
    _pointerDownPos = null;
    _pointerDownTime = null;
    if (downPos == null || downTime == null) return;

    final moved = (event.localPosition - downPos).distance;
    final elapsedMs = DateTime.now().difference(downTime).inMilliseconds;
    // Quick clean tap/click fires an Aether Surge centered at the tap!
    if (moved < 9.0 && elapsedMs < 280 && viewportSize.width > 0) {
      final uv = Offset(
        event.localPosition.dx / viewportSize.width,
        event.localPosition.dy / viewportSize.height,
      );
      _world.triggerSurge(normalizedScreenCenter: uv);
      if (_hintVisible) setState(() => _hintVisible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF05070D),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_world.initError != null) {
      return _ErrorView(
        error: _world.initError!,
        onRetry: _world.initialize,
      );
    }

    if (!_world.isReady) {
      return const _LoadingView();
    }

    final safePadding = MediaQuery.paddingOf(context);
    final screenSize = MediaQuery.sizeOf(context);
    final accent = _world.mood.accentColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Live full-screen GPU-rendered 3D scene with smooth orbit controls.
        LayoutBuilder(
          builder: (context, constraints) {
            final viewportSize = constraints.biggest;
            return Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _onViewportPointerDown,
              onPointerMove: _onViewportPointerMove,
              onPointerUp: (e) => _onViewportPointerUp(e, viewportSize),
              onPointerSignal: (_) => _world.notifyUserCameraInteraction(),
              child: CameraControls(
                controller: _world.cameraController,
                autofocus: false,
                child: SceneView(
                  _world.scene,
                  onTick: _world.onTick,
                  loadingBuilder: (context, progress) =>
                      _LoadingView(progress: progress),
                  errorBuilder: (context, error, retry) =>
                      _ErrorView(error: error, onRetry: retry),
                ),
              ),
            );
          },
        ),

        // 2. Top-left Brand & Live Telemetry HUD.
        if (_hudVisible)
          Positioned(
            top: safePadding.top + 16,
            left: safePadding.left + 16,
            child: TelemetryBadge(world: _world),
          ),

        // 3. Subtle transient interaction hint pill.
        if (_hudVisible && _hintVisible && !_inspectorOpen)
          Positioned(
            top: safePadding.top + 18,
            right: safePadding.right + 16,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _hintVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: GlassSurface(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  opacity: 0.45,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 15, color: accent),
                      const SizedBox(width: 8),
                      Text(
                        'Drag to orbit · Scroll to zoom · Tap anywhere for Surge',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // 4. Collapsible Right Studio Inspector Panel.
        if (_hudVisible && _inspectorOpen)
          Positioned(
            top: safePadding.top + 16,
            right: safePadding.right + 16,
            bottom: safePadding.bottom + 88,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (screenSize.width - 32).clamp(240.0, 320.0),
              ),
              child: StudioInspectorPanel(
                world: _world,
                onClose: () => setState(() => _inspectorOpen = false),
              ),
            ),
          ),

        // 5. Floating Bottom Mood & Action Dock.
        if (_hudVisible)
          Positioned(
            left: 16,
            right: 16,
            bottom: safePadding.bottom + 18,
            child: Center(
              child: MoodSwitcherBar(
                world: _world,
                inspectorOpen: _inspectorOpen,
                onToggleInspector: () =>
                    setState(() => _inspectorOpen = !_inspectorOpen),
                onToggleHud: () => setState(() => _hudVisible = false),
              ),
            ),
          ),

        // 6. Minimal Restore-HUD pill when HUD is hidden for pure 3D viewing.
        if (!_hudVisible)
          Positioned(
            right: safePadding.right + 16,
            bottom: safePadding.bottom + 18,
            child: GlassSurface(
              accentColor: accent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              borderRadius: BorderRadius.circular(16),
              opacity: 0.5,
              child: InkWell(
                onTap: () => setState(() => _hudVisible = true),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_rounded, size: 16, color: accent),
                    const SizedBox(width: 7),
                    const Text(
                      'Show HUD (H)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.15),
          radius: 1.1,
          colors: [Color(0xFF10182E), Color(0xFF05070D)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(
                value: progress != null && progress! > 0 ? progress : null,
                strokeWidth: 2.2,
                color: const Color(0xFFF6C46D),
                backgroundColor: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'AETHER OBSERVATORY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 4.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Compiling shaders & igniting sanctuary...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF05070D),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: GlassSurface(
          accentColor: const Color(0xFFFF6E7F),
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFF6E7F),
                  size: 38,
                ),
                const SizedBox(height: 12),
                const Text(
                  '3D Renderer Initialization Failed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
