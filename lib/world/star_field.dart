import 'dart:math' as math;
import 'dart:ui';

import '../core/renderer.dart';
import '../math/vector2.dart';

class _Star {
  final double x; // 0..1 normalised screen fraction
  final double y;
  final double radius;
  final double brightness; // 0..1

  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.brightness,
  });
}

/// A randomly generated parallax star field rendered in screen space.
///
/// Call [generate] once (e.g. in onEnter), then [render] every frame.
/// Pass [scroll] to [render] to tile-wrap the field with the camera.
class StarField {
  final List<_Star> _stars = [];

  void generate({required math.Random rng, int? count}) {
    final n = count ?? (300 + rng.nextInt(301));
    _stars.clear();
    for (int i = 0; i < n; i++) {
      _stars.add(_Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: 0.5 + rng.nextDouble() * 1.5,
        brightness: 0.4 + rng.nextDouble() * 0.6,
      ));
    }
  }

  /// Renders stars to screen space.
  ///
  /// [scroll] is the camera world-position; stars tile-wrap to create parallax.
  void render(Renderer renderer, {Vector2? scroll}) {
    final w = renderer.size.width;
    final h = renderer.size.height;
    for (final star in _stars) {
      final double sx, sy;
      if (scroll != null) {
        sx = (star.x * w - scroll.x % w + w) % w;
        sy = (star.y * h - scroll.y % h + h) % h;
      } else {
        sx = star.x * w;
        sy = star.y * h;
      }
      final b = (star.brightness * 255).round();
      renderer.drawCircle(Vector2(sx, sy), star.radius, Color.fromARGB(255, b, b, b));
    }
  }
}
