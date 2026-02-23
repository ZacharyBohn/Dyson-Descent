import 'dart:ui';

import '../math/vector2.dart';

/// Wraps Flutter's Canvas and provides game-level draw calls.
/// Entities receive a Renderer in their render() method.
class Renderer {
  Canvas? _canvas;
  Size _size = Size.zero;

  Canvas get canvas {
    assert(_canvas != null, 'Renderer.begin() must be called before drawing.');
    return _canvas!;
  }

  Size get size => _size;

  void begin(Canvas canvas, Size size) {
    _canvas = canvas;
    _size = size;
  }

  void end() {
    _canvas = null;
  }

  /// Draw a filled circle at [position] with [radius] and [color].
  void drawCircle(Vector2 position, double radius, Color color) {
    final paint = Paint()..color = color;
    canvas.drawCircle(Offset(position.x, position.y), radius, paint);
  }

  /// Draw [text] at [position] with optional [color] and [fontSize].
  void drawText(
    String text,
    Vector2 position, {
    Color color = const Color(0xFFFFFFFF),
    double fontSize = 14,
  }) {
    final paragraphBuilder = ParagraphBuilder(
      ParagraphStyle(fontSize: fontSize),
    )
      ..pushStyle(TextStyle(color: color))
      ..addText(text);
    final paragraph = paragraphBuilder.build()
      ..layout(ParagraphConstraints(width: _size.width));
    canvas.drawParagraph(paragraph, Offset(position.x, position.y));
  }

  /// Draw a convex polygon defined by [points] with [color].
  void drawPolygon(List<Offset> points, Color color) {
    if (points.length < 3) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  /// Draw a line between [from] and [to].
  void drawLine(Vector2 from, Vector2 to, Color color, {double strokeWidth = 1}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(from.x, from.y),
      Offset(to.x, to.y),
      paint,
    );
  }
}
