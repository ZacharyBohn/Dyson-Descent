import 'dart:math' as math;
import 'dart:ui';

import '../combat/shield.dart';
import '../combat/weapon_system.dart';
import '../core/renderer.dart';
import '../math/vector2.dart';
import '../resources/cargo.dart';
import 'entity.dart';

class Ship extends LivingEntity {
  double fuel;
  double maxFuel;
  // Multiplier applied to all fuel consumption (1.0 = baseline; reduced by fuelEfficiency upgrades).
  double fuelEfficiencyMultiplier;

  double thrustPower;
  double reverseThrustPower;
  double rotationSpeed;
  double frictionCoefficient;
  double maxSpeed;
  double sublightThrustPower;

  bool isThrustingForward = false;
  double _thrustFlicker = 0.0;

  WeaponSystem weaponSystem;
  Shield shield;
  Cargo cargo;

  Ship({
    required super.id,
    required super.position,
    super.velocity,
    super.rotation,
    super.radius = 12,
    super.health = 100,
    super.maxHealth = 100,
    this.maxFuel = 1000,
    this.fuelEfficiencyMultiplier = 1.0,
    this.thrustPower = 700,
    this.reverseThrustPower = 40,
    this.rotationSpeed = 3.0,
    this.frictionCoefficient = 0.98,
    this.maxSpeed = 400,
    this.sublightThrustPower = 40,
    WeaponSystem? weaponSystem,
    Shield? shield,
    Cargo? cargo,
  }) : fuel = maxFuel,
       weaponSystem = weaponSystem ?? WeaponSystem(),
       shield = shield ?? Shield(maxShieldStrength: 50),
       cargo = cargo ?? Cargo();

  @override
  void takeDamage(double amount) {
    double remaining = amount;
    if (shield.isActive) {
      final absorbed = remaining.clamp(0.0, shield.shieldStrength);
      shield.absorbDamage(absorbed);
      remaining -= absorbed;
    }
    if (remaining > 0) {
      health = (health - remaining).clamp(0.0, maxHealth);
    }
  }

  void rotateLeft(double deltaTime) {
    rotation -= rotationSpeed * deltaTime;
  }

  void rotateRight(double deltaTime) {
    rotation += rotationSpeed * deltaTime;
  }

  void thrustForward(double deltaTime) {
    isThrustingForward = true;
    final dir = Vector2.fromAngle(rotation);
    if (fuel > 0) {
      velocity = velocity + dir * (thrustPower * deltaTime);
      _capSpeed();
      consumeFuel(10 * deltaTime);
    } else {
      velocity = velocity + dir * (sublightThrustPower * deltaTime);
      _capSpeed();
    }
  }

  void thrustBackward(double deltaTime) {
    if (fuel <= 0) return;
    final dir = Vector2.fromAngle(rotation);
    velocity = velocity - dir * (reverseThrustPower * deltaTime);
    _capSpeed();
    consumeFuel(5 * deltaTime);
  }

  void applyFriction(double deltaTime) {
    velocity = velocity * frictionCoefficient;
  }

  void consumeFuel(double amount) {
    fuel = (fuel - amount * fuelEfficiencyMultiplier).clamp(0.0, maxFuel);
  }

  void _capSpeed() {
    if (velocity.length() > maxSpeed) {
      velocity.normalize();
      velocity = velocity * maxSpeed;
    }
  }

  @override
  void update(double deltaTime) {
    position = position + velocity * deltaTime;
    applyFriction(deltaTime);
    shield.update(deltaTime);
    weaponSystem.update(deltaTime);
    _thrustFlicker += deltaTime * 10;
  }

  @override
  void render(Renderer renderer) {
    _renderThrust(renderer);

    const double noseLen = 16.0;
    const double sideLen = 10.0;
    const double sideHalf = 8.0;

    final cosR = math.cos(rotation);
    final sinR = math.sin(rotation);

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

    renderer.drawPolygon([nose, leftWing, rightWing], const Color(0xFF1A3A5C));

    final path = Path()
      ..moveTo(nose.dx, nose.dy)
      ..lineTo(leftWing.dx, leftWing.dy)
      ..lineTo(rightWing.dx, rightWing.dy)
      ..close();
    renderer.canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF66BBFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _renderThrust(Renderer renderer) {
    if (!isThrustingForward) return;

    final cosR = math.cos(rotation);
    final sinR = math.sin(rotation);

    // Tail centre: midpoint of the two wing vertices
    const double sideLen = 10.0;
    final tailX = position.x - cosR * sideLen;
    final tailY = position.y - sinR * sideLen;

    final flicker = 0.7 + 0.125 * math.sin(_thrustFlicker);

    if (fuel > 0) {
      // Main thruster — large orange/yellow flame
      final flameLen = 28.0 * flicker;
      final flameWidth = 7.0 * flicker;

      // Outer glow (orange, semi-transparent)
      final outerTip = Offset(
        tailX - cosR * flameLen * 1.4,
        tailY - sinR * flameLen * 1.4,
      );
      final leftBase = Offset(
        tailX - sinR * flameWidth,
        tailY + cosR * flameWidth,
      );
      final rightBase = Offset(
        tailX + sinR * flameWidth,
        tailY - cosR * flameWidth,
      );
      renderer.canvas.drawPath(
        Path()
          ..moveTo(outerTip.dx, outerTip.dy)
          ..lineTo(leftBase.dx, leftBase.dy)
          ..lineTo(rightBase.dx, rightBase.dy)
          ..close(),
        Paint()..color = const Color(0x99FF6600),
      );

      // Inner core (yellow/white)
      final innerTip = Offset(tailX - cosR * flameLen, tailY - sinR * flameLen);
      final innerWidth = flameWidth * 0.45;
      final leftInner = Offset(
        tailX - sinR * innerWidth,
        tailY + cosR * innerWidth,
      );
      final rightInner = Offset(
        tailX + sinR * innerWidth,
        tailY - cosR * innerWidth,
      );
      renderer.canvas.drawPath(
        Path()
          ..moveTo(innerTip.dx, innerTip.dy)
          ..lineTo(leftInner.dx, leftInner.dy)
          ..lineTo(rightInner.dx, rightInner.dy)
          ..close(),
        Paint()..color = const Color(0xCCFFEE44),
      );
    } else {
      // Sublight drives — small blue glow
      final glowRadius = (4.0 + 2.0 * flicker).toDouble();
      renderer.canvas.drawCircle(
        Offset(tailX, tailY),
        glowRadius,
        Paint()..color = const Color(0x884466FF),
      );
    }
  }

  @override
  void onCollision(Entity other) {}
}
