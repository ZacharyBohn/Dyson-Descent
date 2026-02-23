import '../math/vector2.dart';

class PatrolPath {
  List<Vector2> waypoints;
  int currentIndex;
  double moveSpeed;

  PatrolPath({
    required this.waypoints,
    this.moveSpeed = 80,
  }) : currentIndex = 0;

  bool get hasWaypoints => waypoints.isNotEmpty;

  Vector2 getNextTarget() {
    if (!hasWaypoints) return Vector2.zero();
    return waypoints[currentIndex];
  }

  void advance() {
    if (!hasWaypoints) return;
    currentIndex = (currentIndex + 1) % waypoints.length;
  }
}
