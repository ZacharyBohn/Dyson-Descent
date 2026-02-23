import 'dart:ui';

import '../core/renderer.dart';
import '../entities/planet.dart';
import '../entities/warp_gate.dart';
import '../math/vector2.dart';

class Minimap {
  static const double size = 150;
  static const double pad = 10;
  // Keep private aliases so internal code is unchanged.
  static const double _size = size;
  static const double _pad = pad;

  void render(
    Renderer renderer, {
    required Vector2 shipPos,
    required double worldRadius,
    required List<Planet> planets,
    required List<WarpGate> gates,
    required Vector2 hubPos,
  }) {
    final sw = renderer.size.width;
    final ox = sw - _size - _pad; // top-left x
    const oy = _pad;              // top-left y

    final canvas = renderer.canvas;

    // Dark background
    canvas.drawRect(
      Rect.fromLTWH(ox, oy, _size, _size),
      Paint()..color = const Color(0xBB000018),
    );

    // Clip rendering to minimap rect
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(ox, oy, _size, _size));

    // Map a world position to minimap pixel offset
    Offset w2m(Vector2 wp) => Offset(
          ox + (wp.x / worldRadius * 0.5 + 0.5) * _size,
          oy + (wp.y / worldRadius * 0.5 + 0.5) * _size,
        );

    // Planets
    for (final planet in planets) {
      if (!planet.isActive) continue;
      canvas.drawCircle(
        w2m(planet.position),
        2.5,
        Paint()..color = planet.color,
      );
    }

    // Warp gates
    for (final gate in gates) {
      canvas.drawCircle(
        w2m(gate.position),
        3.0,
        Paint()..color = const Color(0xFF00FFEE),
      );
    }

    // Hub (small square)
    canvas.drawRect(
      Rect.fromCenter(center: w2m(hubPos), width: 6, height: 6),
      Paint()..color = const Color(0xFF88CCFF),
    );

    // Ship (white dot, always visible)
    canvas.drawCircle(
      w2m(shipPos),
      3.0,
      Paint()..color = const Color(0xFFFFFFFF),
    );

    canvas.restore();

    // Border (drawn after restore so it sits on top, unclipped)
    canvas.drawRect(
      Rect.fromLTWH(ox, oy, _size, _size),
      Paint()
        ..color = const Color(0xFF446688)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}
