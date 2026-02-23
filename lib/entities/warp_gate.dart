import 'dart:math' as math;
import 'dart:ui';

import '../core/renderer.dart';
import 'entity.dart';

class WarpGate extends Entity {
  String dungeonId;
  double _spin = 0.0;

  WarpGate({
    required super.id,
    required super.position,
    super.radius = 30,
    super.isActive = true,
    required this.dungeonId,
  });

  void activate() => isActive = true;
  void deactivate() => isActive = false;

  @override
  void update(double deltaTime) {
    _spin += deltaTime * 1.2;
  }

  @override
  void render(Renderer renderer) {
    final cx = position.x;
    final cy = position.y;

    // Portal interior
    renderer.canvas.drawCircle(
      Offset(cx, cy),
      radius * 0.65,
      Paint()..color = const Color(0xFF001828),
    );

    // Outer ring
    renderer.canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = const Color(0x8800FFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Inner ring
    renderer.canvas.drawCircle(
      Offset(cx, cy),
      radius * 0.65,
      Paint()
        ..color = const Color(0x5500FFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Spinning tick marks (6)
    final tickPaint = Paint()
      ..color = const Color(0xFF00FFFF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 6; i++) {
      final angle = _spin + i * math.pi / 3;
      final innerR = radius * 0.72;
      final outerR = radius * 0.95;
      renderer.canvas.drawLine(
        Offset(cx + math.cos(angle) * innerR, cy + math.sin(angle) * innerR),
        Offset(cx + math.cos(angle) * outerR, cy + math.sin(angle) * outerR),
        tickPaint,
      );
    }

    // Center glow
    renderer.canvas.drawCircle(
      Offset(cx, cy),
      5,
      Paint()..color = const Color(0xFF00FFFF),
    );
  }

  @override
  void onCollision(Entity other) {}
}
