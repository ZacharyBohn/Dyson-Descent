import 'dart:math' as math;
import 'dart:ui';

import '../core/game_transfer.dart';
import '../core/input_manager.dart';
import '../core/renderer.dart';
import '../core/scene.dart';
import '../math/vector2.dart';
import '../world/star_field.dart';

/// Phase 7 skeleton – provides scene infrastructure and visual shell.
///
/// Full gameplay (enemies, loot, hazards) is implemented in Phase 11–15.
/// State persistence (ship / economy carry-over) is wired up in Phase 11.
class DungeonScene extends Scene {
  final StarField   _starField = StarField();
  final math.Random _rng       = math.Random();

  String _dungeonId = '';
  int    _layer     = 1;

  // Animated entry flash
  double _entryFlash = 1.0;

  DungeonScene({required super.onChangeScene, required super.inputManager});

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onEnter() {
    _dungeonId  = GameTransfer.dungeonId ?? 'unknown';
    _layer      = 1;
    _entryFlash = 1.0;
    GameTransfer.clear();

    _starField.generate(rng: _rng, count: 200);
  }

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  @override
  void update(double deltaTime) {
    _entryFlash = (_entryFlash - deltaTime * 2.0).clamp(0.0, 1.0);

    // Always allow tap-to-extract in dungeon.
    inputManager.interactionAvailable = true;

    if (inputManager.isKeyPressed(GameKey.interact)) {
      onChangeScene(SceneType.overworld);
    }
  }

  // ---------------------------------------------------------------------------
  // Render
  // ---------------------------------------------------------------------------

  @override
  void render(Renderer renderer) {
    final w = renderer.size.width;
    final h = renderer.size.height;

    // Background – deeper black with subtle teal tint
    renderer.canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF020B10),
    );

    _starField.render(renderer);

    // Entry flash overlay
    if (_entryFlash > 0) {
      final alpha = (_entryFlash * 160).round();
      renderer.canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()..color = Color.fromARGB(alpha, 0, 200, 220),
      );
    }

    _renderHeader(renderer, w);
    _renderLayerRings(renderer, w, h);
    _renderPlaceholder(renderer, w, h);
    _renderExtractPrompt(renderer, w, h);
  }

  // ---------------------------------------------------------------------------
  // Sub-renderers
  // ---------------------------------------------------------------------------

  void _renderHeader(Renderer renderer, double w) {
    renderer.drawText(
      'DUNGEON',
      Vector2(w / 2 - 46, 14),
      color: const Color(0xFF00CCFF),
      fontSize: 22,
    );
    renderer.drawText(
      'LAYER  $_layer',
      Vector2(w / 2 - 34, 42),
      color: const Color(0xFF006688),
      fontSize: 14,
    );
    renderer.drawText(
      'Gate: $_dungeonId',
      Vector2(w / 2 - 40, 62),
      color: const Color(0xFF224455),
      fontSize: 11,
    );
  }

  void _renderLayerRings(Renderer renderer, double w, double h) {
    final cx = w / 2;
    final cy = h / 2;
    final ringPaint = Paint()
      ..color = const Color(0xFF003344)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (int i = 1; i <= 4; i++) {
      renderer.canvas.drawCircle(Offset(cx, cy), i * 80.0, ringPaint);
    }
    // Centre node
    renderer.canvas.drawCircle(
      Offset(cx, cy),
      12,
      Paint()..color = const Color(0xFF001A22),
    );
    renderer.canvas.drawCircle(
      Offset(cx, cy),
      12,
      Paint()
        ..color = const Color(0xFF00CCFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _renderPlaceholder(Renderer renderer, double w, double h) {
    renderer.drawText(
      'Dungeon interior — Phase 11',
      Vector2(w / 2 - 115, h / 2 + 30),
      color: const Color(0xFF1A3A4A),
      fontSize: 15,
    );
  }

  void _renderExtractPrompt(Renderer renderer, double w, double h) {
    renderer.drawText(
      'Press E to extract',
      Vector2(w / 2 - 68, h - 55),
      color: const Color(0xFF3399AA),
      fontSize: 15,
    );
  }
}
