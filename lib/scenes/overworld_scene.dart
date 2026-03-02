import 'dart:math' as math;
import 'dart:ui';

import '../audio/audio_manager.dart';
import '../core/game_transfer.dart';
import '../core/renderer.dart';
import '../core/scene.dart';
import '../economy/player_economy.dart';
import '../enemies/enemy_spawner.dart';
import '../enemies/patrol_path.dart';
import '../entities/bullet.dart';
import '../entities/enemy_ship.dart';
import '../entities/mineral_drop.dart';
import '../entities/planet.dart';
import '../entities/ship.dart';
import '../hud/hub_panel.dart';
import '../hud/hud.dart';
import '../hud/minimap.dart';
import '../math/vector2.dart';
import '../player/player_controller.dart';
import '../resources/mineral_type.dart';
import '../world/star_field.dart';
import '../world/world_map.dart';

class OverworldScene extends Scene {
  late Ship _ship;
  late PlayerController _playerController;
  late WorldMap _worldMap;
  late PlayerEconomy _economy;
  late EnemySpawner _enemySpawner;

  final StarField _starField = StarField();
  final HubPanel _hubPanel = HubPanel();
  final HUD _hud = HUD();
  final Minimap _minimap = Minimap();
  final math.Random _rng = math.Random();

  final List<Bullet> _bullets = [];
  final List<Bullet> _enemyBullets = [];
  final List<MineralDrop> _drops = [];
  int _dropCounter = 0;

  Rect _muteButtonRect = Rect.zero;
  double _totalTime = 0.0;

  // Phase 10 — kill-quota and gate-loop state
  int _phaseEnemyTotal = 10;
  String _notificationText = '';
  double _notificationTimer = 0.0;
  double _minimapFlashTimer = 0.0;

  // Vision radius: approximate half-diagonal of a typical screen in world units.
  static const double _visionRadius = 650.0;

  // Hub is a fixed world-space landmark near the centre.
  final Vector2 _hubPos = Vector2(300, 0);

  OverworldScene({required super.onChangeScene, required super.inputManager});

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onEnter() {
    // Restore ship/economy if returning from the race; otherwise start fresh.
    if (GameTransfer.ship != null) {
      _ship = GameTransfer.ship!;
      _economy = GameTransfer.economy ?? PlayerEconomy();
      GameTransfer.ship = null;
      GameTransfer.economy = null;
      // Re-anchor near origin so the player doesn't spawn in race-space coordinates.
      _ship.position = Vector2.zero();
      _ship.velocity = Vector2.zero();
      _playerController = PlayerController(controlledShip: _ship);
    } else {
      _ship = Ship(id: 'player', position: Vector2.zero());
      _playerController = PlayerController(controlledShip: _ship);
      _economy = PlayerEconomy();
    }

    _worldMap = WorldMap();
    _enemySpawner = EnemySpawner(maxEnemies: 50);

    _worldMap.generateAsteroids(40);

    _bullets.clear();
    _enemyBullets.clear();
    _drops.clear();
    _dropCounter = 0;
    _hubPanel.isOpen = false;
    _notificationTimer = 0;
    _minimapFlashTimer = 0;

    _spawnInitialEnemies(10);
    _showNotification('10 enemies patrol this sector — destroy them all!', 6.0);

    _hubPanel.onWarpNewSystem = () {
      _worldMap = WorldMap();
      _worldMap.generateAsteroids(40);
      _drops.clear();
      _enemyBullets.clear();
      _enemySpawner = EnemySpawner(maxEnemies: 50);
      _spawnInitialEnemies(10);
      _showNotification('New system! 10 enemies patrol this sector!', 6.0);
    };

    _starField.generate(rng: _rng);
  }

  // ---------------------------------------------------------------------------
  // Phase 10 helpers
  // ---------------------------------------------------------------------------

  void _showNotification(String text, double duration) {
    _notificationText = text;
    _notificationTimer = duration;
  }

  /// Spawns [count] enemies spread randomly across the map for the initial
  /// patrol phase.  Each enemy gets its own local circular patrol path.
  void _spawnInitialEnemies(int count) {
    _phaseEnemyTotal = count;
    for (int i = 0; i < count; i++) {
      Vector2 pos;
      int attempts = 0;
      do {
        final angle = _rng.nextDouble() * 2 * math.pi;
        final dist = 2000.0 + _rng.nextDouble() * 4000.0;
        pos = Vector2(math.cos(angle) * dist, math.sin(angle) * dist);
        attempts++;
      } while (attempts < 50 && Vector2.distance(pos, _hubPos) < 1000);

      final waypoints = List.generate(4, (j) {
        final a = j * math.pi / 2;
        return Vector2(pos.x + math.cos(a) * 150, pos.y + math.sin(a) * 150);
      });

      final before = _enemySpawner.activeEnemies.length;
      _enemySpawner.spawnGroup(pos, 1);
      if (_enemySpawner.activeEnemies.length > before) {
        _enemySpawner.activeEnemies.last.patrolPath = PatrolPath(
          waypoints: waypoints,
          moveSpeed: 70,
        );
      }
    }
  }

  /// Called whenever an enemy dies.  Drops loot, flashes the minimap, and
  /// either shows the remaining count or triggers a gate spawn.
  void _handleEnemyKill(EnemyShip enemy) {
    _spawnEnemyDrops(enemy);
    _minimapFlashTimer = 5.0;

    final remaining = _enemySpawner.aliveCount;
    if (remaining > 0) {
      _showNotification('$remaining / $_phaseEnemyTotal enemies remain', 3.5);
    } else {
      _showNotification('Sector cleared! New enemies incoming...', 4.0);
      _spawnInitialEnemies(10);
    }
  }

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  @override
  void update(double deltaTime) {
    _totalTime += deltaTime;
    if (_notificationTimer > 0) _notificationTimer -= deltaTime;
    if (_minimapFlashTimer > 0) _minimapFlashTimer -= deltaTime;

    if (inputManager.isMouseClicked()) {
      final pos = inputManager.mouseClickPosition;
      if (pos != null && _muteButtonRect.contains(pos)) {
        AudioManager.instance.toggleMute();
      }
    }

    // Tell InputManager whether a tap should trigger interact (near hub/gate)
    // rather than fire. Hub-open state is excluded so tap routes to panel buttons.
    inputManager.interactionAvailable =
        !_hubPanel.isOpen &&
        Vector2.distance(_ship.position, _hubPos) < HubPanel.dockRadius;

    if (!_hubPanel.isOpen) {
      final bullet = _playerController.handleInput(inputManager, deltaTime);
      if (bullet != null) _bullets.add(bullet);
    } else {
      _ship.isThrustingForward = false;
    }

    _ship.update(deltaTime);
    for (final planet in _worldMap.planets) {
      planet.update(deltaTime);
    }
    for (final b in _bullets) {
      b.update(deltaTime);
    }
    for (final b in _enemyBullets) {
      b.update(deltaTime);
    }
    for (final drop in _drops) {
      drop.update(deltaTime);
    }

    // Update enemy AI and collect any shots fired; stamp vision timestamps.
    for (final enemy in _enemySpawner.activeEnemies) {
      if (!enemy.isActive) continue;
      final shot = enemy.updateAI(_ship, deltaTime);
      if (shot != null) _enemyBullets.add(shot);
      if (Vector2.distance(_ship.position, enemy.position) <= _visionRadius) {
        enemy.lastSeenTime = _totalTime;
      }
    }

    _checkBulletPlanetCollisions();
    _checkBulletEnemyCollisions();
    _checkEnemyBulletShipCollisions();
    _checkEnemyShipRamCollisions(deltaTime);
    _checkShipAsteroidCollisions(deltaTime);
    _checkShipDropCollisions();

    _bullets.removeWhere((b) => !b.isActive);
    _enemyBullets.removeWhere((b) => !b.isActive);
    _drops.removeWhere((d) => !d.isActive);
    _enemySpawner.removeDefeated();

    _enforceWorldBoundary();

    _hubPanel.update(
      input: inputManager,
      shipPos: _ship.position,
      hubPos: _hubPos,
      ship: _ship,
      economy: _economy,
    );

  }

  // ---------------------------------------------------------------------------
  // Render
  // ---------------------------------------------------------------------------

  @override
  void render(Renderer renderer) {
    final w = renderer.size.width;
    final h = renderer.size.height;

    _starField.render(renderer, scroll: _ship.position);

    // World space
    renderer.canvas.save();
    renderer.canvas.translate(
      w / 2 - _ship.position.x,
      h / 2 - _ship.position.y,
    );

    _renderHubStructure(renderer);
    for (final planet in _worldMap.planets) {
      if (planet.isActive) planet.render(renderer);
    }
    for (final enemy in _enemySpawner.activeEnemies) {
      if (enemy.isActive) enemy.render(renderer);
    }
    for (final drop in _drops) {
      if (drop.isActive) drop.render(renderer);
    }
    for (final b in _bullets) {
      if (b.isActive) b.render(renderer);
    }
    for (final b in _enemyBullets) {
      if (b.isActive) b.render(renderer);
    }
    _ship.render(renderer);

    renderer.canvas.restore();

    // Screen space
    _hud.render(renderer, _ship, _economy);
    _minimap.render(
      renderer,
      shipPos: _ship.position,
      worldRadius: _worldMap.radius,
      planets: _worldMap.planets,
      hubPos: _hubPos,
      enemies: _enemySpawner.activeEnemies,
      totalTime: _totalTime,
      flashAllEnemies: _minimapFlashTimer > 0,
    );
    _renderMuteButton(renderer, w);

    final distToHub = Vector2.distance(_ship.position, _hubPos);
    if (!_hubPanel.isOpen && distToHub < HubPanel.promptRadius) {
      _renderHubPrompt(renderer, w, h, distToHub);
    }
    if (_hubPanel.isOpen) _hubPanel.render(renderer, _ship, _economy);

    // Kill-quota notification — top-centre, fades during last 1.5 s
    if (_notificationTimer > 0) _renderNotification(renderer, w, h);
  }

  void _renderNotification(Renderer renderer, double w, double h) {
    final fade = (_notificationTimer / 1.5).clamp(0.0, 1.0);
    final alpha = (fade * 220 + 20).round();
    final x = w / 2 - _notificationText.length * 4.3;
    renderer.drawText(
      _notificationText,
      Vector2(x, h / 2 - 60),
      color: Color.fromARGB(alpha, 255, 210, 60),
      fontSize: 17,
    );
  }

  // ---------------------------------------------------------------------------
  // Hub station structure – drawn in world space
  // ---------------------------------------------------------------------------

  void _renderHubStructure(Renderer renderer) {
    final cx = _hubPos.x;
    final cy = _hubPos.y;

    // Docking zone indicator
    renderer.canvas.drawCircle(
      Offset(cx, cy),
      HubPanel.dockRadius,
      Paint()
        ..color = const Color(0x2244FF88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Cross arms
    final armPaint = Paint()
      ..color = const Color(0xFF334D66)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      renderer.canvas.drawLine(
        Offset(cx + math.cos(angle) * 18, cy + math.sin(angle) * 18),
        Offset(cx + math.cos(angle) * 48, cy + math.sin(angle) * 48),
        armPaint,
      );
    }

    // Core body
    renderer.canvas.drawCircle(
      Offset(cx, cy),
      18,
      Paint()..color = const Color(0xFF1A3044),
    );
    renderer.canvas.drawCircle(
      Offset(cx, cy),
      18,
      Paint()
        ..color = const Color(0xFF55AACC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    renderer.drawText(
      'HUB',
      Vector2(cx - 12, cy - 30),
      color: const Color(0xFF88CCFF),
      fontSize: 11,
    );
  }

  // ---------------------------------------------------------------------------
  // Hub proximity prompt – drawn in screen space
  // ---------------------------------------------------------------------------

  void _renderHubPrompt(Renderer renderer, double w, double h, double dist) {
    final t = (1 - dist / HubPanel.promptRadius).clamp(0.0, 1.0);
    final alpha = (t * 215 + 40).round();
    renderer.drawText(
      'Press E to dock',
      Vector2(w / 2 - 55, h - 60),
      color: Color.fromARGB(alpha, 100, 220, 255),
      fontSize: 16,
    );
  }

  // ---------------------------------------------------------------------------
  // Collision helpers
  // ---------------------------------------------------------------------------

  void _checkBulletPlanetCollisions() {
    for (final bullet in _bullets) {
      if (!bullet.isActive) continue;
      for (final planet in _worldMap.planets) {
        if (!planet.isActive) continue;
        if (Vector2.distance(bullet.position, planet.position) <
            bullet.radius + planet.radius) {
          final wasAlive = !planet.isDead();
          planet.takeDamage(bullet.damage);
          bullet.isActive = false;
          if (wasAlive && planet.isDead()) _spawnDrops(planet);
          break;
        }
      }
    }
  }

  void _checkBulletEnemyCollisions() {
    for (final bullet in _bullets) {
      if (!bullet.isActive) continue;
      for (final enemy in _enemySpawner.activeEnemies) {
        if (!enemy.isActive) continue;
        if (Vector2.distance(bullet.position, enemy.position) <
            bullet.radius + enemy.radius) {
          final wasAlive = !enemy.isDead();
          enemy.takeDamage(bullet.damage);
          bullet.isActive = false;
          if (wasAlive && enemy.isDead()) _handleEnemyKill(enemy);
          break;
        }
      }
    }
  }

  void _checkEnemyBulletShipCollisions() {
    for (final bullet in _enemyBullets) {
      if (!bullet.isActive) continue;
      if (Vector2.distance(bullet.position, _ship.position) <
          bullet.radius + _ship.radius) {
        _ship.takeDamage(bullet.damage);
        bullet.isActive = false;
      }
    }
  }

  void _checkEnemyShipRamCollisions(double deltaTime) {
    for (final enemy in _enemySpawner.activeEnemies) {
      if (!enemy.isActive) continue;
      if (Vector2.distance(_ship.position, enemy.position) <
          _ship.radius + enemy.radius) {
        _ship.takeDamage(15 * deltaTime);
        final wasDead = enemy.isDead();
        enemy.takeDamage(30 * deltaTime);
        if (!wasDead && enemy.isDead()) _handleEnemyKill(enemy);
      }
    }
  }

  void _checkShipDropCollisions() {
    for (final drop in _drops) {
      if (!drop.isActive) continue;
      if (Vector2.distance(_ship.position, drop.position) <
          _ship.radius + drop.radius) {
        drop.collect(_ship);
      }
    }
  }

  void _checkShipAsteroidCollisions(double deltaTime) {
    for (final asteroid in _worldMap.planets) {
      if (!asteroid.isActive) continue;
      final dist = Vector2.distance(_ship.position, asteroid.position);
      final minDist = _ship.radius + asteroid.radius;
      if (dist < minDist) {
        // Push ship out along the collision normal
        final diff = _ship.position - asteroid.position;
        final normal = diff.length() > 0 ? diff.normalized() : Vector2(1, 0);
        _ship.position = asteroid.position + normal * minDist;

        // Reflect velocity along the normal and dampen it
        final dot = _ship.velocity.x * normal.x + _ship.velocity.y * normal.y;
        if (dot < 0) {
          _ship.velocity = _ship.velocity - normal * (2 * dot);
          _ship.velocity = _ship.velocity * 0.3;
        }

        // Deal collision damage
        _ship.takeDamage(20 * deltaTime);
      }
    }
  }

  void _spawnDrops(Planet planet) {
    for (int i = 0; i < planet.dropAmount; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = 30.0 + _rng.nextDouble() * 60.0;
      _drops.add(
        MineralDrop(
          id: 'drop_${_dropCounter++}',
          position: Vector2(planet.position.x, planet.position.y),
          velocity: Vector2.fromAngle(angle) * speed,
          type: planet.mineralType,
          quantity: 1,
        ),
      );
    }
  }

  void _spawnEnemyDrops(EnemyShip enemy) {
    final count = 1 + _rng.nextInt(2); // 1–2 rare minerals
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = 40.0 + _rng.nextDouble() * 60.0;
      _drops.add(
        MineralDrop(
          id: 'drop_${_dropCounter++}',
          position: Vector2(enemy.position.x, enemy.position.y),
          velocity: Vector2.fromAngle(angle) * speed,
          type: MineralType.rare,
          quantity: 1,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Mute button – drawn in screen space, below the minimap
  // ---------------------------------------------------------------------------

  void _renderMuteButton(Renderer renderer, double w) {
    const double btnW = 44;
    const double btnH = 36;
    const double gap = 8;
    final double bx = w - Minimap.pad - btnW;
    final double by = Minimap.pad + Minimap.size + gap;

    _muteButtonRect = Rect.fromLTWH(bx, by, btnW, btnH);

    final muted = AudioManager.instance.isMuted;
    final canvas = renderer.canvas;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(_muteButtonRect, const Radius.circular(6)),
      Paint()..color = const Color(0xBB000018),
    );
    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(_muteButtonRect, const Radius.circular(6)),
      Paint()
        ..color = muted ? const Color(0xFF664444) : const Color(0xFF446688)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Label
    renderer.drawText(
      muted ? '✕♪' : '♪',
      Vector2(bx + (muted ? 8 : 14), by + 9),
      color: muted ? const Color(0xFF996666) : const Color(0xFF88CCFF),
      fontSize: 16,
    );
  }

  void _enforceWorldBoundary() {
    final r = _worldMap.radius;
    if (_ship.position.x > r) {
      _ship.position.x = r;
      if (_ship.velocity.x > 0) _ship.velocity.x = 0;
    }
    if (_ship.position.x < -r) {
      _ship.position.x = -r;
      if (_ship.velocity.x < 0) _ship.velocity.x = 0;
    }
    if (_ship.position.y > r) {
      _ship.position.y = r;
      if (_ship.velocity.y > 0) _ship.velocity.y = 0;
    }
    if (_ship.position.y < -r) {
      _ship.position.y = -r;
      if (_ship.velocity.y < 0) _ship.velocity.y = 0;
    }
  }
}
