import 'dart:ui';

import '../entities/bullet.dart';
import '../math/vector2.dart';

class WeaponSystem {
  double fireRate; // shots per second
  double damageMultiplier;
  double bulletSize;
  double homingStrength;
  double heat;
  double maxHeat;

  double _cooldown = 0;

  static int _bulletIdCounter = 0;
  static const double _bulletSpeed = 600.0;

  WeaponSystem({
    this.fireRate = 2,
    this.damageMultiplier = 1,
    this.bulletSize = 4,
    this.homingStrength = 0,
    this.maxHeat = 100,
  }) : heat = 0;

  bool get isOverheated => heat >= maxHeat;

  bool get canFire => _cooldown <= 0 && !isOverheated;

  /// Returns a new [Bullet] if fired, or null if on cooldown / overheated.
  Bullet? fire(Vector2 position, double rotation,
      {Color bulletColor = const Color(0xFFFFFF88)}) {
    if (!canFire) return null;
    _cooldown = 1.0 / fireRate;
    heat += 10;
    _bulletIdCounter++;
    return Bullet(
      id: 'bullet_$_bulletIdCounter',
      position: Vector2(position.x, position.y),
      velocity: Vector2.fromAngle(rotation) * _bulletSpeed,
      radius: bulletSize,
      damage: 10 * damageMultiplier,
      color: bulletColor,
    );
  }

  void update(double deltaTime) {
    if (_cooldown > 0) _cooldown -= deltaTime;
    if (heat > 0) heat = (heat - 20 * deltaTime).clamp(0, maxHeat);
  }
}
