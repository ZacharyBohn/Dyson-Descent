# Starfall: Dyson Descent – LLM Context File

> Use this file to avoid having the LLM needing to read a lot of files into context. Update periodically as needed.

## Game Concept

2D top-down space simulation. The player pilots a ship from their **Mothership** base, mines asteroids
for two ore types (energy ore and material ore), deposits them at the Mothership's manufacturing plant,
and converts them into **Energy** and **Material** — the two resources that power all upgrades, ship
rebuilds, and base automation. Eventually the player purchases auto-collector drones and defense turrets.

An **Enemy Mothership** spawns ~3 minutes in with its own fleet of collectors and attack ships. Both
factions follow symmetric rules. The faction that accumulates resources and builds a stronger fleet wins.
**Goal:** destroy the Enemy Mothership before it destroys yours.

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
`SceneType` enum: `start | overworld`

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
// World space (entities, mothership, asteroids)
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
    scene.dart                abstract Scene + SceneType enum
    renderer.dart             Renderer: wraps Canvas; drawCircle/Text/Polygon/Line helpers
    input_manager.dart        InputManager + GameKey enum
    game_transfer.dart        GameTransfer: static bag for cross-scene data
  scenes/
    start_scene.dart          Title screen — START button → SceneType.overworld
    overworld_scene.dart      Main gameplay loop (ship, asteroids, bullets, drops, mothership)
  entities/
    entity.dart               abstract Entity + LivingEntity
    ship.dart                 Ship: WeaponSystem, Shield, Cargo; thrust/rotate/fire; energy replaces fuel
    bullet.dart               Bullet: lifetime, damage, optional homing
    planet.dart               Asteroid: mineable, flashes on hit, drops ores on death; isEnergyOre flag
    mineral_drop.dart         MineralDrop: collected on overlap; calls drop.collect(ship)
    enemy_ship.dart           EnemyShip: patrol + drive-by AI; optional targetOverride for Mothership assaults
    mothership.dart           Mothership (player base): hexagon entity, health pool, resource display [Phase 12]
    enemy_mothership.dart     EnemyMothership: symmetric to player; owns collector fleet; upgrade timers [Phase 16]
    collector_ship.dart       CollectorShip: mines nearest asteroid, returns ore to owning Mothership [Phase 16]
    turret.dart               Turret: anchored to player Mothership; auto-aims/fires at nearby enemies [Phase 17]
  math/
    vector2.dart              Vector2(x,y); static distance(a,b); fromAngle; operators
  world/
    world_map.dart            WorldMap: generateAsteroids(n); 20% energy ore (green glow), 80% material ore; radius field
    star_field.dart           StarField: generate(rng), render(renderer, {scroll}) — parallax
  player/
    player_controller.dart    PlayerController: handleInput(input, dt) → Bullet?
  combat/
    weapon_system.dart        WeaponSystem: fireRate, damage, heat; fire() → Bullet?
    shield.dart               Shield: absorbs damage; regens after delay
  resources/
    mineral_type.dart         enum ResourceType { energyOre, materialOre }
    cargo.dart                Cargo: energyOreCount, materialOreCount, capacity; add/remove
  economy/
    player_economy.dart       PlayerEconomy: energyResource, materialResource; add/spend methods
    repair_shop.dart          RepairShop: repairShip (costs Material); reEnergizeShip (costs baseEnergy) [Phase 13]
  hud/
    hud.dart                  HUD: health/shield/energy/resources bars — screen space; Mothership health bar [Phase 18]
    hub_panel.dart            MothershipPanel: Manufacturing / Ship Upgrades / Base Upgrades tabs
    minimap.dart              Minimap: ship, asteroids, enemies, player Mothership, enemy Mothership marker
  upgrades/
    upgrade_type.dart         enum UpgradeType (ship upgrades + base upgrades: respawnCost, shipMaxEnergy,
                                collectorDroneSlots, turretSlots)
    upgrade.dart              Upgrade: level, maxLevel; energyCost + materialCost; apply(ship)
    upgrade_shop.dart         UpgradeShop: purchaseUpgrade(); tier unlocks via resource thresholds
  collision/
    collision_manager.dart    CollisionManager: detectCollisions(entities)
  enemies/
    enemy_spawner.dart        EnemySpawner: spawnGroup(), removeDefeated()
    patrol_path.dart          PatrolPath: waypoints, advance()
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
  double energy, maxEnergy, energyEfficiencyMultiplier; // replaces fuel
  double thrustPower, rotationSpeed, maxSpeed;
  bool isThrustingForward;
  WeaponSystem weaponSystem; Shield shield; Cargo cargo;
  void rotateLeft(double dt); void rotateRight(double dt);
  void thrustForward(double dt); void thrustBackward(double dt);
  void consumeEnergy(double amount);
}
```

### WorldMap  (`world/world_map.dart`)
```dart
class WorldMap {
  double radius;                        // world boundary radius
  List<Asteroid> asteroids;             // 20% energyOre (green glow), 80% materialOre
  void generateAsteroids(int count);    // assigns isEnergyOre flag; energy ores placed randomly
}
```

### PlayerEconomy  (`economy/player_economy.dart`)
```dart
class PlayerEconomy {
  int energyResource;    // processed energy (from energy ore via manufacturing)
  int materialResource;  // processed material (from material ore via manufacturing)
  void addEnergy(int amount);    void spendEnergy(int amount);
  void addMaterial(int amount);  void spendMaterial(int amount);
}
```

### HubPanel  (`hud/hub_panel.dart`)
```dart
class HubPanel {
  static const double dockRadius;     // 100 — must be inside to press E
  static const double promptRadius;   // 250 — shows "Press E to dock"
  bool isOpen;
  void update({InputManager input, Vector2 shipPos, Vector2 mothershipPos, Ship ship, PlayerEconomy economy});
  void render(Renderer renderer, Ship ship, PlayerEconomy economy);
  // Tabs: HubTab { manufacturing, shipUpgrades, baseUpgrades }
}
```

### Mothership  (`entities/mothership.dart`)
```dart
class Mothership extends LivingEntity {
  double health = 1000, maxHealth = 1000, radius = 60;
  // Renders as large dark-blue hexagon with health bar and "MOTHERSHIP" label
  // Static position — does not move
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
`_bullets`, `_drops`, `_mothership`, `_enemyMothership` (after spawn timer), `_playerCollectors`,
`_enemyCollectors`, `_turrets`.

Player Mothership at world position `(300, 0)`. Player presses **E** within 100 units to open the
Mothership panel (Manufacturing / Ship Upgrades / Base Upgrades tabs).

Enemy Mothership spawns at ~`(-3000, 0)` after 180 seconds of game time.

Button rects are rebuilt each `render()` and consumed on the next frame's `update()`.

Respawn state: when player ship is destroyed, `_isRespawning = true`, `_respawnTimer = 3.0`.
After countdown: if `economy.materialResource >= respawnCost` → spawn new ship at Mothership.

---

## Completed Phases

| Phase | Feature |
|-------|---------|
| 0 | Project setup (Flutter, folder structure, engine, entity system) |
| 1 | Start screen (title + START button) |
| 2 | Overworld: ship movement, camera, world boundary |
| 3 | Asteroids + minerals: mine, collect drops |
| 4 | Weapons: fire, bullet physics, asteroid destruction |
| 5 | Thrust animation (flame flicker), mini map layout, touch input support |
| 6 | Hub station dock UI (Store / Repair / Upgrades tabs) |
| 7 | Economy (store exchange rates, repair cost formula) |
| 8 | Upgrade System: all 9 upgrades apply to live ship stats; `energyEfficiencyMultiplier` on Ship; energy depot in Repair tab |
| 9 | Enemy AI & Combat: drive-by patrol/pursue state machine; EnemySpawner; minimap vision persistence (60s) |
| 10 | Kill-quota wave loop: clear enemies → new wave spawns; warp-new-system callback |

---

## Simulation System Design

### Resource Flow

```
Asteroid (energyOre)  ──mine──▶ Cargo ──deposit──▶ Manufacturing ──convert──▶ baseEnergy
Asteroid (materialOre) ──mine──▶ Cargo ──deposit──▶ Manufacturing ──convert──▶ baseMaterial

baseEnergy   → recharge ship energy, power tier-2 upgrades, build collector drones
baseMaterial → rebuild destroyed ship (cost: 50 mat), buy ship upgrades, build turrets
```

### Asteroid Visuals

- **Energy ore** (20% of asteroids): faint green glow (semi-transparent circle at radius+4, pulsing alpha)
- **Material ore** (80% of asteroids): standard brown/grey, no glow

### Manufacturing Conversion Rates

| Input | Output |
|-------|--------|
| 1 energy ore | 5 Energy |
| 1 material ore | 5 Material |

### Ship Energy (replaces Fuel)

Ship has `energy` / `maxEnergy`. Drains on thrust. HUD shows cyan energy bar.
Recharging at Mothership costs base Energy.

### Mothership Panel Tabs

| Tab | Contents |
|-----|---------|
| Manufacturing | Ore-to-resource conversion; ship energy recharge |
| Ship Upgrades | 9 upgrade types (firepower, shields, etc.) priced in Energy + Material |
| Base Upgrades | Respawn cost reduction, max energy expansion, drone slots, turret slots |

### Faction Symmetry

Both player and enemy Motherships follow the same rules:
- Own resource pools
- Spawn and replace combat ships from resources
- Use collector ships to mine asteroids
- Upgrade over time (player manually; enemy on a timer)

### Win / Lose Conditions

- **Win**: Enemy Mothership health reaches 0
- **Lose**: Player Mothership health reaches 0

---

## Next Up

**Phase 11** — Resource system rework: rename ore types (energyOre / materialOre), asteroid green glow, replace ship fuel with Energy, add Energy + Material pools to PlayerEconomy.

**Phase 12** — Mothership entity: rendered hexagon at (300,0), health pool, replaces static hub point; update HubPanel header.

**Phase 13** — Manufacturing panel: Manufacturing tab replaces Store tab; ore → resource conversion; gold economy removed; all upgrade/repair costs switch to Energy + Material pairs; HUD resource display.

**Phase 14** — Ship destruction and respawn: death detection, 3s countdown, Material cost to rebuild, game-over on Mothership destruction, enemy bullets can hit Mothership.

**Phase 15** — Base Upgrade System: new upgrade categories (respawnCost, shipMaxEnergy, collectorDroneSlots, turretSlots); BASE UPGRADES tab in panel.

**Phase 16** — Enemy Mothership: spawns at 180s; 2 collector ships; builds replacement ships from resources; combat ships target player Mothership; victory screen on destruction.

**Phase 17** — Player Automation: buildable collector drones (mine energy ore, deposit into base); defense turrets anchored to Mothership; both gated behind Base Upgrade slots.

**Phase 18** — Enemy AI progression + balance pass: enemy timed upgrades; enemy resource-to-build loop; collectors can be destroyed; full gameplay balance tuning; HUD additions (Mothership health bar, enemy marker on minimap, elapsed game time).
