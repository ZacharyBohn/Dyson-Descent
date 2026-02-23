# Starfall: Dyson Descent – LLM Context File

> Use this file to avoid having the LLM needing to read a lot of files into context. Update periodically as needed.

## Game Concept

2D top-down space shooter. Player pilots a ship, mines planets for minerals, sells them at the
Hub station, buys upgrades, and eventually enters Warp Gate dungeons for high-risk loot runs.

## Tech Stack

- **Flutter** — UI shell, game loop via `Ticker`
- **dart:ui Canvas** — all game rendering (no engine); direct draw calls in `Renderer`
- Single isolate, no threading

---

## Architecture

### Game Loop (main.dart → game.dart → scene)

```
Ticker._onTick()
  Game.update(dt)          ← Scene.update(dt)
  InputManager.flushFrame()
  setState()               → CustomPaint.paint()
                                Game.render()  ← Scene.render(renderer)
```

### Scene System

`Scene` (abstract) owns `inputManager` and `onChangeScene` callback.
`SceneType` enum: `start | overworld | dungeon | hub`

Active scene is created and swapped by `Game.changeScene(SceneType)`.

### Input

```dart
InputManager.isKeyPressed(key)  // true only on the frame the key was first pressed
InputManager.isKeyHeld(key)     // true while key is physically held
InputManager.isMouseClicked()   // true on the frame of a tap/click
InputManager.mouseClickPosition // Offset? for that click
```

Key bindings (main.dart `_mapKey`):

| Physical key | GameKey          |
|-------------|-----------------|
| A / ←       | rotateLeft       |
| D / →       | rotateRight      |
| W / ↑       | thrustForward    |
| S / ↓       | thrustBackward   |
| Space       | fire             |
| E           | interact         |

### World vs Screen Space

```dart
// World space (entities, hub structure, warp gates)
renderer.canvas.save();
renderer.canvas.translate(w/2 - ship.x, h/2 - ship.y);
// ... draw world objects at their world positions ...
renderer.canvas.restore();

// Screen space (HUD, hub UI overlay, prompts) — after restore()
```

---

## File Map

```
lib/
  main.dart                   Flutter entry; GameShell (Ticker, key/mouse routing)
  core/
    game.dart                 Game: owns Scene, drives update/render, changeScene()
    scene.dart                abstract Scene + SceneType enum  (18 lines)
    renderer.dart             Renderer: wraps Canvas; drawCircle/Text/Polygon/Line helpers
    input_manager.dart        InputManager + GameKey enum
    game_transfer.dart        GameTransfer: static bag for cross-scene data (dungeonId)
  scenes/
    start_scene.dart          Title screen — START button → SceneType.overworld
    overworld_scene.dart      Main gameplay loop (ship, planets, bullets, drops, hub)
    dungeon_scene.dart        DungeonScene skeleton: starfield, layer header, E-to-extract
    hub_scene.dart            Stub (future dedicated hub scene if needed)
  entities/
    entity.dart               abstract Entity + LivingEntity
    ship.dart                 Ship: WeaponSystem, Shield, Cargo; thrust/rotate/fire
    bullet.dart               Bullet: lifetime, damage, optional homing
    planet.dart               Planet: mineable, flashes on hit, drops minerals on death
    mineral_drop.dart         MineralDrop: collected on overlap; calls drop.collect(ship)
    warp_gate.dart            WarpGate: animated cyan portal; dungeonId; activate/deactivate
    enemy_ship.dart           EnemyShip: patrol + pursue AI (Phase 7+)
    ai_core.dart              AICore boss stub (Phase 8+)
  math/
    vector2.dart              Vector2(x,y); static distance(a,b); fromAngle; operators
  world/
    world_map.dart            WorldMap: generatePlanets(n), generateWarpGates(n); radius field
    star_field.dart           StarField: generate(rng), render(renderer, {scroll}) — parallax
    warp_gate_manager.dart    WarpGateManager stub (Phase 7+)
  player/
    player_controller.dart    PlayerController: handleInput(input, dt) → Bullet?
  combat/
    weapon_system.dart        WeaponSystem: fireRate, damage, heat; fire() → Bullet?
    shield.dart               Shield: absorbs damage; regens after delay
  resources/
    mineral_type.dart         enum MineralType { common, rare }
    cargo.dart                Cargo: commonCount, rareCount, capacity; add/remove
  economy/
    player_economy.dart       PlayerEconomy: gold; addGold / spendGold
    store.dart                Store: sellMinerals(economy, cargo) — common×5g, rare×25g
    repair_shop.dart          RepairShop: calculateRepairCost/repairShip + calculateRefuelCost/refuelShip (0.1g/fuel unit)
  hud/
    hud.dart                  HUD: health/shield/fuel/cargo/gold bars — screen space
    hub_panel.dart            HubPanel: hub station overlay (Store/Repair/Upgrades tabs)
  upgrades/
    upgrade_type.dart         enum UpgradeType (9 types)
    upgrade.dart              Upgrade: level, maxLevel, baseCost; getCost(); apply(ship)
    upgrade_shop.dart         UpgradeShop: availableUpgrades list; purchaseUpgrade()
  dungeon/
    dungeon.dart              Dungeon: layers, advanceLayer() (Phase 7+)
    dungeon_layer.dart        DungeonLayer: enemies, hazards, isCleared() (Phase 7+)
    dungeon_manager.dart      DungeonManager: enterDungeon / exitDungeon (Phase 7+)
  collision/
    collision_manager.dart    CollisionManager: detectCollisions(entities) (Phase 7+)
  enemies/
    enemy_spawner.dart        EnemySpawner: spawnGroup(), removeDefeated() (Phase 7+)
    patrol_path.dart          PatrolPath: waypoints, advance() (Phase 7+)
```

---

## Key Classes — Signatures

### Entity / LivingEntity  (`entities/entity.dart`)
```dart
abstract class Entity {
  String id; Vector2 position; Vector2 velocity; double rotation; double radius; bool isActive;
  void update(double dt); void render(Renderer r); void onCollision(Entity other);
}
abstract class LivingEntity extends Entity {
  double health; double maxHealth;
  void takeDamage(double amount); bool isDead();
}
```

### Ship  (`entities/ship.dart`)
```dart
class Ship extends LivingEntity {
  double fuel, maxFuel, fuelEfficiencyMultiplier; // multiplier applied inside consumeFuel()
  double thrustPower, rotationSpeed, maxSpeed;
  bool isThrustingForward;
  WeaponSystem weaponSystem; Shield shield; Cargo cargo;
  void rotateLeft(double dt); void rotateRight(double dt);
  void thrustForward(double dt); void thrustBackward(double dt);
}
```

### WorldMap  (`world/world_map.dart`)
```dart
class WorldMap {
  double radius;                      // world boundary radius
  List<Planet> planets;
  List<WarpGate> gates;
  void generatePlanets(int count);
  void generateWarpGates(int count);  // gates placed >1000 units from centre
}
```

### HubPanel  (`hud/hub_panel.dart`)
```dart
class HubPanel {
  static const double dockRadius;     // 100 — must be inside to press E
  static const double promptRadius;   // 250 — shows "Press E to dock"
  bool isOpen;
  void update({InputManager input, Vector2 shipPos, Vector2 hubPos, Ship ship, PlayerEconomy economy});
  void render(Renderer renderer, Ship ship, PlayerEconomy economy);
}
```

### StarField  (`world/star_field.dart`)
```dart
class StarField {
  void generate({required Random rng, int? count});
  void render(Renderer renderer, {Vector2? scroll});  // scroll = ship world pos for parallax
}
```

### Renderer  (`core/renderer.dart`)
```dart
class Renderer {
  Canvas get canvas;  Size get size;
  void begin(Canvas, Size); void end();
  void drawCircle(Vector2 pos, double radius, Color color);
  void drawText(String text, Vector2 pos, {Color color, double fontSize});
  void drawLine(Vector2 from, Vector2 to, Color color, {double strokeWidth});
  void drawPolygon(List<Offset> points, Color color);
}
```

---

## OverworldScene Overview  (`scenes/overworld_scene.dart`)

Owns: `_ship`, `_playerController`, `_worldMap`, `_economy`, `_starField`, `_hubPanel`, `_hud`,
`_bullets`, `_drops`.

Hub is at world position `(300, 0)`. Player presses **E** within 100 units to open the hub UI.
The HubPanel renders an overlay with Store / Repair / Upgrades tabs.

Button rects are rebuilt each `render()` and consumed on the next frame's `update()`.

---

## Completed Phases

| Phase | Feature |
|-------|---------|
| 0 | Project setup (Flutter, folder structure) |
| 1 | Start screen (title + START button) |
| 2 | Overworld: ship movement, camera, world boundary |
| 3 | Planets + minerals: mine, collect drops |
| 4 | Weapons: fire, bullet physics, planet destruction |
| 5 | Thrust animation (flame flicker) |
| 6 | Warp gates (animated cyan portals) + Hub station (dock UI: Store / Repair / Upgrades) |
| 7 | Economy (store exchange rates, repair cost formula) + DungeonScene skeleton + warp gate entry |
| 8 | Upgrade System Foundation: all 9 upgrades apply to live ship stats; `fuelEfficiencyMultiplier` on Ship (–10% per level, min 0.10); Fuel Depot added to Repair tab (refuel costs 0.1g/unit, max 100g for full 1000-unit tank) |
| 9 | Enemy AI & Combat: EnemyShip patrol/pursue AI wired into OverworldScene; EnemySpawner spawns 3 enemies per warp gate with circular patrol paths; player bullets deal damage to enemies; enemy bullets (red) deal damage to player ship (shield first); ramming collision (continuous damage); enemies drop 1–2 rare minerals on death; `Bullet.color` field + `WeaponSystem.fire(bulletColor:)` param |

## Next Up

**Phase 10** — Dungeon Combat: flesh out DungeonScene with enemy waves (EnemySpawner per layer), player health persistence across scenes (GameTransfer), collision checks, layer clear condition (all enemies dead), and loot drops on layer completion.
