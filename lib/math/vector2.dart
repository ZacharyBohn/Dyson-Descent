import 'dart:math' as math;

class Vector2 {
  double x;
  double y;

  Vector2(this.x, this.y);

  Vector2.zero()
      : x = 0,
        y = 0;

  Vector2.fromAngle(double radians)
      : x = math.cos(radians),
        y = math.sin(radians);

  double length() => math.sqrt(x * x + y * y);

  void normalize() {
    final len = length();
    if (len > 0) {
      x /= len;
      y /= len;
    }
  }

  Vector2 normalized() {
    final len = length();
    if (len == 0) return Vector2.zero();
    return Vector2(x / len, y / len);
  }

  static double distance(Vector2 a, Vector2 b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  Vector2 operator +(Vector2 other) => Vector2(x + other.x, y + other.y);
  Vector2 operator -(Vector2 other) => Vector2(x - other.x, y - other.y);
  Vector2 operator *(double scalar) => Vector2(x * scalar, y * scalar);

  @override
  String toString() => 'Vector2($x, $y)';
}
