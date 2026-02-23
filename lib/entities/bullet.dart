import 'dart:ui';

import '../core/renderer.dart';
import 'entity.dart';

class Bullet extends Entity {
  double damage;
  double lifetime;
  double homingStrength;
  Color color;
  double _age = 0;

  Bullet({
    required super.id,
    required super.position,
    required super.velocity,
    super.rotation,
    super.radius = 4,
    this.damage = 10,
    this.lifetime = 3,
    this.homingStrength = 0,
    this.color = const Color(0xFFFFFF88),
  });

  bool get isExpired => _age >= lifetime;

  @override
  void update(double deltaTime) {
    _age += deltaTime;
    if (_age >= lifetime) {
      isActive = false;
      return;
    }
    position = position + velocity * deltaTime;
  }

  @override
  void render(Renderer renderer) {
    renderer.drawCircle(position, radius, color);
  }

  @override
  void onCollision(Entity other) {
    isActive = false;
  }
}
