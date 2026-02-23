import '../core/renderer.dart';
import 'entity.dart';
import 'ship.dart';

class AICore extends LivingEntity {
  int _phase = 0;

  AICore({
    required super.id,
    required super.position,
    super.radius = 60,
    super.health = 500,
    super.maxHealth = 500,
  });

  int get phase => _phase;

  void initializePhase(int phase) {
    _phase = phase;
  }

  void updateAI(Ship player, double deltaTime) {}

  @override
  void takeDamage(double amount) {
    health = (health - amount).clamp(0, maxHealth);
  }

  @override
  void update(double deltaTime) {}

  @override
  void render(Renderer renderer) {}

  @override
  void onCollision(Entity other) {}
}
