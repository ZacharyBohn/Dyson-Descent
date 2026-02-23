import '../math/vector2.dart';
import '../core/renderer.dart';

abstract class Entity {
  final String id;
  Vector2 position;
  Vector2 velocity;
  double rotation; // radians
  double radius;
  bool isActive;

  Entity({
    required this.id,
    required this.position,
    Vector2? velocity,
    this.rotation = 0,
    this.radius = 16,
    this.isActive = true,
  }) : velocity = velocity ?? Vector2.zero();

  void update(double deltaTime);
  void render(Renderer renderer);
  void onCollision(Entity other);
}

abstract class LivingEntity extends Entity {
  double health;
  double maxHealth;

  LivingEntity({
    required super.id,
    required super.position,
    super.velocity,
    super.rotation,
    super.radius,
    super.isActive,
    required this.health,
    required this.maxHealth,
  });

  void takeDamage(double amount);

  bool isDead() => health <= 0;
}
