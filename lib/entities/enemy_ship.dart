import 'dart:math' as math;
import 'dart:ui';

import '../combat/weapon_system.dart';
import '../core/renderer.dart';
import '../enemies/patrol_path.dart';
import '../math/vector2.dart';
import 'bullet.dart';
import 'entity.dart';
import 'ship.dart';

class EnemyShip extends LivingEntity {
  double detectionRadius;
  PatrolPath patrolPath;
  WeaponSystem weaponSystem;

  EnemyShip({
    required super.id,
    required super.position,
    super.velocity,
    super.rotation,
    super.radius = 12,
    super.health = 60,
    super.maxHealth = 60,
    this.detectionRadius = 300,
    PatrolPath? patrolPath,
    WeaponSystem? weaponSystem,
  })  : patrolPath = patrolPath ?? PatrolPath(waypoints: []),
        weaponSystem = weaponSystem ?? WeaponSystem(fireRate: 1);

  @override
  void takeDamage(double amount) {
    health = (health - amount).clamp(0, maxHealth);
    if (isDead()) isActive = false;
  }

  /// Updates AI and returns a [Bullet] if the enemy fires this frame.
  Bullet? updateAI(Ship player, double deltaTime) {
    Bullet? shot;
    final dist = Vector2.distance(position, player.position);
    if (dist < detectionRadius) {
      shot = _pursuePlayer(player, deltaTime);
    } else {
      _patrol(deltaTime);
    }
    weaponSystem.update(deltaTime);
    position = position + velocity * deltaTime;
    return shot;
  }

  Bullet? _pursuePlayer(Ship player, double deltaTime) {
    final dir = (player.position - position).normalized();
    velocity = dir * (patrolPath.moveSpeed * 1.5);
    rotation = _angleTowards(player.position);

    if (Vector2.distance(position, player.position) < detectionRadius * 0.6) {
      return weaponSystem.fire(position, rotation,
          bulletColor: const Color(0xFFFF4444));
    }
    return null;
  }

  void _patrol(double deltaTime) {
    if (!patrolPath.hasWaypoints) return;
    final target = patrolPath.getNextTarget();
    final dist = Vector2.distance(position, target);
    if (dist < 10) patrolPath.advance();

    final dir = (target - position).normalized();
    velocity = dir * patrolPath.moveSpeed;
    rotation = _angleTowards(target);
  }

  double _angleTowards(Vector2 target) {
    final diff = target - position;
    if (diff.length() == 0) return rotation;
    return math.atan2(diff.y, diff.x);
  }

  @override
  void update(double deltaTime) {}

  @override
  void render(Renderer renderer) {
    final cosR = math.cos(rotation);
    final sinR = math.sin(rotation);

    const double noseLen = 14.0;
    const double sideLen = 9.0;
    const double sideHalf = 7.0;

    final nose = Offset(
      position.x + cosR * noseLen,
      position.y + sinR * noseLen,
    );
    final leftWing = Offset(
      position.x - cosR * sideLen - sinR * sideHalf,
      position.y - sinR * sideLen + cosR * sideHalf,
    );
    final rightWing = Offset(
      position.x - cosR * sideLen + sinR * sideHalf,
      position.y - sinR * sideLen - cosR * sideHalf,
    );

    renderer.drawPolygon([nose, leftWing, rightWing], const Color(0xFF5C1A1A));

    final path = Path()
      ..moveTo(nose.dx, nose.dy)
      ..lineTo(leftWing.dx, leftWing.dy)
      ..lineTo(rightWing.dx, rightWing.dy)
      ..close();
    renderer.canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFF4444)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    _renderHealthBar(renderer);
  }

  void _renderHealthBar(Renderer renderer) {
    const double barW = 24.0;
    const double barH = 3.0;
    final barX = position.x - barW / 2;
    final barY = position.y - radius - 8;

    renderer.canvas.drawRect(
      Rect.fromLTWH(barX, barY, barW, barH),
      Paint()..color = const Color(0xFF441111),
    );
    renderer.canvas.drawRect(
      Rect.fromLTWH(barX, barY, barW * (health / maxHealth), barH),
      Paint()..color = const Color(0xFFFF3333),
    );
  }

  @override
  void onCollision(Entity other) {}
}
