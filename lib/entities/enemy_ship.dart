import 'dart:math' as math;
import 'dart:ui';

import '../combat/weapon_system.dart';
import '../core/renderer.dart';
import '../enemies/patrol_path.dart';
import '../math/vector2.dart';
import 'bullet.dart';
import 'entity.dart';
import 'ship.dart';

enum _AIState { patrol, approach, orbit, escape }

class EnemyShip extends LivingEntity {
  double detectionRadius;
  PatrolPath patrolPath;
  WeaponSystem weaponSystem;

  /// Phase 9.5 – set to elapsed game time whenever this enemy is on-screen.
  /// Starts at -1 (never seen).
  double lastSeenTime = -1.0;

  // ---- Combat state machine ------------------------------------------------
  _AIState _aiState = _AIState.patrol;
  Vector2 _escapeDir = Vector2(1, 0);
  final _rng = math.Random();

  static const double _approachSpeed    = 120.0;
  static const double _orbitRange       = 250.0; // engage/shoot within this radius
  static const double _orbitHoldDist    = 150.0; // back away if closer than this
  static const double _orbitBackSpeed   = 50.0;
  static const double _escapeThreshold  = 100.0; // flee when closer than this
  static const double _escapeSpeed      = 200.0;
  static const double _escapeReturnDist = 230.0; // re-engage once this far
  // -------------------------------------------------------------------------

  EnemyShip({
    required super.id,
    required super.position,
    super.velocity,
    super.rotation,
    super.radius = 12,
    super.health = 60,
    super.maxHealth = 60,
    this.detectionRadius = 350,
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
      if (_aiState == _AIState.patrol) _aiState = _AIState.approach;
      shot = _runCombat(player, deltaTime);
    } else {
      _aiState = _AIState.patrol;
      _patrol(deltaTime);
    }

    weaponSystem.update(deltaTime);
    position = position + velocity * deltaTime;
    return shot;
  }

  // ---------------------------------------------------------------------------
  // Combat state machine
  // ---------------------------------------------------------------------------

  Bullet? _runCombat(Ship player, double dt) {
    final dist = Vector2.distance(position, player.position);

    // State transitions.
    switch (_aiState) {
      case _AIState.approach:
        if (dist < _orbitRange) _aiState = _AIState.orbit;
      case _AIState.orbit:
        if (dist < _escapeThreshold) {
          _beginEscape(player);
        } else if (dist > _orbitRange + 80) {
          _aiState = _AIState.approach;
        }
      case _AIState.escape:
        if (dist > _escapeReturnDist) _aiState = _AIState.approach;
      default:
        break;
    }

    switch (_aiState) {
      case _AIState.approach: return _doApproach(player);
      case _AIState.orbit:    return _doOrbit(player);
      case _AIState.escape:   _doEscape(); return null;
      default:                return null;
    }
  }

  /// Moves straight toward the player to close distance.
  Bullet? _doApproach(Ship player) {
    rotation = _angleTowards(player.position);
    final toPlayer = player.position - position;
    if (toPlayer.length() > 0) velocity = toPlayer.normalized() * _approachSpeed;
    return null;
  }

  /// Holds position facing the player and fires continuously.
  /// Backs away slowly if the player gets within [_orbitHoldDist].
  Bullet? _doOrbit(Ship player) {
    rotation = _angleTowards(player.position);
    final dist = Vector2.distance(position, player.position);
    if (dist < _orbitHoldDist) {
      final away = (position - player.position).normalized();
      velocity = away * _orbitBackSpeed;
    } else {
      velocity = Vector2.zero();
    }
    return weaponSystem.fire(position, rotation,
        bulletColor: const Color(0xFFFF4444));
  }

  /// Picks a random escape direction that is not toward the player,
  /// sets [_escapeDir], and switches to the escape state.
  void _beginEscape(Ship player) {
    final toPlayer = (player.position - position).normalized();
    final baseAngle = math.atan2(toPlayer.y, toPlayer.x);
    // Offset in [90°, 270°] so we never flee toward the player.
    final offset = math.pi * 0.5 + _rng.nextDouble() * math.pi;
    final angle = baseAngle + offset;
    _escapeDir = Vector2(math.cos(angle), math.sin(angle));
    _aiState = _AIState.escape;
  }

  /// Flees in [_escapeDir] at high speed until far enough to re-engage.
  void _doEscape() {
    velocity = _escapeDir * _escapeSpeed;
    rotation = math.atan2(_escapeDir.y, _escapeDir.x);
  }

  // ---------------------------------------------------------------------------
  // Patrol
  // ---------------------------------------------------------------------------

  void _patrol(double deltaTime) {
    if (!patrolPath.hasWaypoints) return;
    final target = patrolPath.getNextTarget();
    final dist   = Vector2.distance(position, target);
    if (dist < 10) patrolPath.advance();

    final dir = (target - position).normalized();
    velocity  = dir * patrolPath.moveSpeed;
    rotation  = _angleTowards(target);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  double _angleTowards(Vector2 target) {
    final diff = target - position;
    if (diff.length() == 0) return rotation;
    return math.atan2(diff.y, diff.x);
  }

  // ---------------------------------------------------------------------------
  // Entity overrides
  // ---------------------------------------------------------------------------

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
