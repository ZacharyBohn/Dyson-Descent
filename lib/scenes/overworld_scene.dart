import 'dart:math' as math;
import 'dart:ui';

import '../audio/audio_manager.dart';
import '../core/game_transfer.dart';
import '../core/input_manager.dart';
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
  late Ship             _ship;
  late PlayerController _playerController;
  late WorldMap         _worldMap;
  late PlayerEconomy    _economy;
  late EnemySpawner     _enemySpawner;

  final StarField  _starField = StarField();
  final HubPanel   _hubPanel  = HubPanel();
  final HUD        _hud       = HUD();
  final Minimap    _minimap   = Minimap();
  final math.Random _rng      = math.Random();

  final List<Bullet>      _bullets      = [];
  final List<Bullet>      _enemyBullets = [];
  final List<MineralDrop> _drops        = [];
  int _dropCounter = 0;

  Rect _muteButtonRect = Rect.zero;

  // Hub is a fixed world-space landmark near the centre.
  final Vector2 _hubPos = Vector2(300, 0);

  OverworldScene({required super.onChangeScene, required super.inputManager});

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onEnter() {
    _ship             = Ship(id: 'player', position: Vector2.zero());
    _playerController = PlayerController(controlledShip: _ship);
    _worldMap         = WorldMap();
    _economy          = PlayerEconomy();
    _enemySpawner     = EnemySpawner();

    _worldMap.generateAsteroids(40);
    _worldMap.generateWarpGates(4);

    _bullets.clear();
    _enemyBullets.clear();
    _drops.clear();
    _dropCounter   = 0;
    _hubPanel.isOpen = false;

    _spawnEnemiesNearGates();

    _hubPanel.onWarpNewSystem = () {
      _worldMap = WorldMap();
      _worldMap.generateAsteroids(40);
      _worldMap.generateWarpGates(4);
      _drops.clear();
      _enemyBullets.clear();
      _enemySpawner = EnemySpawner();
      _spawnEnemiesNearGates();
    };

    _starField.generate(rng: _rng);
  }

  void _spawnEnemiesNearGates() {
    for (final gate in _worldMap.gates) {
      // Create a simple square patrol path around the gate
      final waypoints = List.generate(4, (j) {
        final angle = j * math.pi / 2;
        return Vector2(
          gate.position.x + math.cos(angle) * 180,
          gate.position.y + math.sin(angle) * 180,
        );
      });
      final path = PatrolPath(waypoints: waypoints, moveSpeed: 80);

      final before = _enemySpawner.activeEnemies.length;
      _enemySpawner.spawnGroup(gate.position, 3);
      for (int i = before; i < _enemySpawner.activeEnemies.length; i++) {
        _enemySpawner.activeEnemies[i].patrolPath = path;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  @override
  void update(double deltaTime) {
    if (inputManager.isMouseClicked()) {
      final pos = inputManager.mouseClickPosition;
      if (pos != null && _muteButtonRect.contains(pos)) {
        AudioManager.instance.toggleMute();
      }
    }

    if (!_hubPanel.isOpen) {
      final bullet = _playerController.handleInput(inputManager, deltaTime);
      if (bullet != null) _bullets.add(bullet);
    } else {
      _ship.isThrustingForward = false;
    }

    _ship.update(deltaTime);
    for (final planet in _worldMap.planets) { planet.update(deltaTime); }
    for (final gate   in _worldMap.gates)   { gate.update(deltaTime); }
    for (final b      in _bullets)          { b.update(deltaTime); }
    for (final b      in _enemyBullets)     { b.update(deltaTime); }
    for (final drop   in _drops)            { drop.update(deltaTime); }

    // Update enemy AI and collect any shots fired
    for (final enemy in _enemySpawner.activeEnemies) {
      if (!enemy.isActive) continue;
      final shot = enemy.updateAI(_ship, deltaTime);
      if (shot != null) _enemyBullets.add(shot);
    }

    _checkBulletPlanetCollisions();
    _checkBulletEnemyCollisions();
    _checkEnemyBulletShipCollisions();
    _checkEnemyShipRamCollisions(deltaTime);
    _checkShipDropCollisions();

    _bullets.removeWhere((b) => !b.isActive);
    _enemyBullets.removeWhere((b) => !b.isActive);
    _drops.removeWhere((d)   => !d.isActive);
    _enemySpawner.removeDefeated();

    _enforceWorldBoundary();

    _hubPanel.update(
      input:   inputManager,
      shipPos: _ship.position,
      hubPos:  _hubPos,
      ship:    _ship,
      economy: _economy,
    );

    if (!_hubPanel.isOpen) _checkWarpGateEntry();
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
    renderer.canvas.translate(w / 2 - _ship.position.x, h / 2 - _ship.position.y);

    _renderHubStructure(renderer);
    for (final gate   in _worldMap.gates)   { gate.render(renderer); }
    for (final planet in _worldMap.planets) { if (planet.isActive) planet.render(renderer); }
    for (final enemy  in _enemySpawner.activeEnemies) { if (enemy.isActive) enemy.render(renderer); }
    for (final drop   in _drops)            { if (drop.isActive) drop.render(renderer); }
    for (final b      in _bullets)          { if (b.isActive) b.render(renderer); }
    for (final b      in _enemyBullets)     { if (b.isActive) b.render(renderer); }
    _ship.render(renderer);

    renderer.canvas.restore();

    // Screen space
    _hud.render(renderer, _ship, _economy);
    _minimap.render(
      renderer,
      shipPos:     _ship.position,
      worldRadius: _worldMap.radius,
      planets:     _worldMap.planets,
      gates:       _worldMap.gates,
      hubPos:      _hubPos,
    );
    _renderMuteButton(renderer, w);

    final distToHub = Vector2.distance(_ship.position, _hubPos);
    if (!_hubPanel.isOpen && distToHub < HubPanel.promptRadius) {
      _renderHubPrompt(renderer, w, h, distToHub);
    }
    if (_hubPanel.isOpen) _hubPanel.render(renderer, _ship, _economy);

    if (!_hubPanel.isOpen) _renderNearestGatePrompt(renderer, w, h);
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
    renderer.canvas.drawCircle(Offset(cx, cy), 18, Paint()..color = const Color(0xFF1A3044));
    renderer.canvas.drawCircle(
      Offset(cx, cy),
      18,
      Paint()
        ..color = const Color(0xFF55AACC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    renderer.drawText('HUB', Vector2(cx - 12, cy - 30),
        color: const Color(0xFF88CCFF), fontSize: 11);
  }

  // ---------------------------------------------------------------------------
  // Hub proximity prompt – drawn in screen space
  // ---------------------------------------------------------------------------

  void _renderHubPrompt(Renderer renderer, double w, double h, double dist) {
    final t     = (1 - dist / HubPanel.promptRadius).clamp(0.0, 1.0);
    final alpha = (t * 215 + 40).round();
    renderer.drawText('Press E to dock', Vector2(w / 2 - 55, h - 60),
        color: Color.fromARGB(alpha, 100, 220, 255), fontSize: 16);
  }

  // ---------------------------------------------------------------------------
  // Warp gate helpers
  // ---------------------------------------------------------------------------

  static const double _gatePromptRadius = 120.0;

  void _checkWarpGateEntry() {
    if (!inputManager.isKeyPressed(GameKey.interact)) return;
    for (final gate in _worldMap.gates) {
      if (!gate.isActive) continue;
      if (Vector2.distance(_ship.position, gate.position) < _gatePromptRadius) {
        GameTransfer.dungeonId = gate.dungeonId;
        onChangeScene(SceneType.dungeon);
        return;
      }
    }
  }

  void _renderNearestGatePrompt(Renderer renderer, double w, double h) {
    for (final gate in _worldMap.gates) {
      if (!gate.isActive) continue;
      final dist = Vector2.distance(_ship.position, gate.position);
      if (dist < _gatePromptRadius) {
        final t     = (1 - dist / _gatePromptRadius).clamp(0.0, 1.0);
        final alpha = (t * 215 + 40).round();
        renderer.drawText(
          'Press E to enter dungeon',
          Vector2(w / 2 - 90, h - 60),
          color: Color.fromARGB(alpha, 0, 220, 220),
          fontSize: 16,
        );
        return;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Collision helpers
  // ---------------------------------------------------------------------------

  void _checkBulletPlanetCollisions() {
    for (final bullet in _bullets) {
      if (!bullet.isActive) continue;
      for (final planet in _worldMap.planets) {
        if (!planet.isActive) continue;
        if (Vector2.distance(bullet.position, planet.position) < bullet.radius + planet.radius) {
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
        if (Vector2.distance(bullet.position, enemy.position) < bullet.radius + enemy.radius) {
          final wasAlive = !enemy.isDead();
          enemy.takeDamage(bullet.damage);
          bullet.isActive = false;
          if (wasAlive && enemy.isDead()) _spawnEnemyDrops(enemy);
          break;
        }
      }
    }
  }

  void _checkEnemyBulletShipCollisions() {
    for (final bullet in _enemyBullets) {
      if (!bullet.isActive) continue;
      if (Vector2.distance(bullet.position, _ship.position) < bullet.radius + _ship.radius) {
        _ship.takeDamage(bullet.damage);
        bullet.isActive = false;
      }
    }
  }

  void _checkEnemyShipRamCollisions(double deltaTime) {
    for (final enemy in _enemySpawner.activeEnemies) {
      if (!enemy.isActive) continue;
      if (Vector2.distance(_ship.position, enemy.position) < _ship.radius + enemy.radius) {
        _ship.takeDamage(15 * deltaTime);
        final wasDead = enemy.isDead();
        enemy.takeDamage(30 * deltaTime);
        if (!wasDead && enemy.isDead()) _spawnEnemyDrops(enemy);
      }
    }
  }

  void _checkShipDropCollisions() {
    for (final drop in _drops) {
      if (!drop.isActive) continue;
      if (Vector2.distance(_ship.position, drop.position) < _ship.radius + drop.radius) {
        drop.collect(_ship);
      }
    }
  }

  void _spawnDrops(Planet planet) {
    for (int i = 0; i < planet.dropAmount; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = 30.0 + _rng.nextDouble() * 60.0;
      _drops.add(MineralDrop(
        id:       'drop_${_dropCounter++}',
        position: Vector2(planet.position.x, planet.position.y),
        velocity: Vector2.fromAngle(angle) * speed,
        type:     planet.mineralType,
        quantity: 1,
      ));
    }
  }

  void _spawnEnemyDrops(EnemyShip enemy) {
    final count = 1 + _rng.nextInt(2); // 1–2 rare minerals
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = 40.0 + _rng.nextDouble() * 60.0;
      _drops.add(MineralDrop(
        id:       'drop_${_dropCounter++}',
        position: Vector2(enemy.position.x, enemy.position.y),
        velocity: Vector2.fromAngle(angle) * speed,
        type:     MineralType.rare,
        quantity: 1,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Mute button – drawn in screen space, to the left of the minimap
  // ---------------------------------------------------------------------------

  void _renderMuteButton(Renderer renderer, double w) {
    const double btnW   = 44;
    const double btnH   = 36;
    const double gap    = 8;
    final double bx = w - Minimap.size - Minimap.pad - gap - btnW;
    const double by = Minimap.pad;

    _muteButtonRect = Rect.fromLTWH(bx, by, btnW, btnH);

    final muted  = AudioManager.instance.isMuted;
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
    if (_ship.position.x > r)  { _ship.position.x = r;  if (_ship.velocity.x > 0) _ship.velocity.x = 0; }
    if (_ship.position.x < -r) { _ship.position.x = -r; if (_ship.velocity.x < 0) _ship.velocity.x = 0; }
    if (_ship.position.y > r)  { _ship.position.y = r;  if (_ship.velocity.y > 0) _ship.velocity.y = 0; }
    if (_ship.position.y < -r) { _ship.position.y = -r; if (_ship.velocity.y < 0) _ship.velocity.y = 0; }
  }
}
