import 'dart:ui';

import '../core/renderer.dart';
import '../resources/mineral_type.dart';
import 'entity.dart';
import 'ship.dart';

class MineralDrop extends Entity {
  MineralType type;
  int quantity;

  MineralDrop({
    required super.id,
    required super.position,
    super.velocity,
    super.radius = 8,
    required this.type,
    required this.quantity,
  });

  void collect(Ship ship) {
    if (!isActive) return;
    if (ship.cargo.canStore(quantity)) {
      ship.cargo.add(type, quantity);
      isActive = false;
    }
  }

  @override
  void update(double deltaTime) {
    position = position + velocity * deltaTime;
    // Slow down over time (drag in space)
    velocity = velocity * 0.98;
  }

  @override
  void render(Renderer renderer) {
    final color = type == MineralType.common
        ? const Color(0xFFFFAA33)   // orange for common
        : const Color(0xFFAA44FF);  // purple for rare
    renderer.drawCircle(position, radius, color);
  }

  @override
  void onCollision(Entity other) {
    if (other is Ship) collect(other);
  }
}
