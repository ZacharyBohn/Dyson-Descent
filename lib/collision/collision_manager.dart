import '../entities/entity.dart';
import '../math/vector2.dart';

class CollisionManager {
  /// Circle-vs-circle broad phase + narrow phase collision detection.
  /// Calls [Entity.onCollision] on both entities when a collision is detected.
  void detectCollisions(List<Entity> entities) {
    final active = entities.where((e) => e.isActive).toList();

    for (int i = 0; i < active.length; i++) {
      for (int j = i + 1; j < active.length; j++) {
        final a = active[i];
        final b = active[j];

        if (_overlaps(a, b)) {
          a.onCollision(b);
          b.onCollision(a);
        }
      }
    }
  }

  bool _overlaps(Entity a, Entity b) {
    final dist = Vector2.distance(a.position, b.position);
    return dist < a.radius + b.radius;
  }
}
