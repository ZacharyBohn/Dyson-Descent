import 'dart:math' as math;
import 'dart:ui';

import '../audio/audio_manager.dart';
import '../core/renderer.dart';
import '../core/scene.dart';
import '../math/vector2.dart';
import '../world/star_field.dart';

class StartScene extends Scene {
  final StarField _starField = StarField();
  Rect _startButtonRect = Rect.zero;

  StartScene({required super.onChangeScene, required super.inputManager});

  @override
  void onEnter() {
    _starField.generate(rng: math.Random());
  }

  @override
  void update(double deltaTime) {
    if (inputManager.isMouseClicked()) {
      final pos = inputManager.mouseClickPosition;
      if (pos != null && _startButtonRect.contains(pos)) {
        AudioManager.instance.startMusic();
        onChangeScene(SceneType.overworld);
      }
    }
  }

  @override
  void render(Renderer renderer) {
    final w = renderer.size.width;
    final h = renderer.size.height;

    _starField.render(renderer);

    const btnW = 200.0;
    const btnH = 54.0;
    final cx = w / 2;
    final cy = h / 2;

    _startButtonRect = Rect.fromCenter(center: Offset(cx, cy), width: btnW, height: btnH);

    renderer.drawText('Starfall: Dyson Descent', Vector2(cx - 165, cy - 90),
        color: const Color(0xFF88CCFF), fontSize: 30);

    renderer.canvas.drawRRect(
      RRect.fromRectAndRadius(_startButtonRect, const Radius.circular(8)),
      Paint()..color = const Color(0xFF0D2240),
    );
    renderer.canvas.drawRRect(
      RRect.fromRectAndRadius(_startButtonRect, const Radius.circular(8)),
      Paint()
        ..color = const Color(0xFF4488CC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    renderer.drawText('START GAME', Vector2(cx - 52, cy - 11),
        color: const Color(0xFFFFFFFF), fontSize: 18);
  }
}
