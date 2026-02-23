Work Tracking Document

Project: Starfall – Dyson Descent

Development Approach: Incremental vertical slices. Each phase ends with manual playtesting by the developer before proceeding.

Map assumption: Fixed-size world centered at (0,0).

⸻

Phase 0 — Project Skeleton

0.0 Class Layout [COMPLETE]
  • All classes laid out into individual files under lib/
  • File structure:
      lib/
        main.dart                        # App entry, GameShell widget
        core/
          game.dart                      # Game (scene manager + loop driver)
          scene.dart                     # Scene abstract + StartScene, OverworldScene, DungeonScene, HubScene
          input_manager.dart             # InputManager + GameKey enum
          renderer.dart                  # Renderer (wraps Flutter Canvas)
        math/
          vector2.dart                   # Vector2
        entities/
          entity.dart                    # Entity (abstract), LivingEntity (abstract)
          ship.dart                      # Ship
          bullet.dart                    # Bullet
          mineral_drop.dart              # MineralDrop
          planet.dart                    # Planet
          enemy_ship.dart                # EnemyShip
          warp_gate.dart                 # WarpGate
          ai_core.dart                   # AICore
        combat/
          weapon_system.dart             # WeaponSystem
          shield.dart                    # Shield
        resources/
          mineral_type.dart              # MineralType enum
          cargo.dart                     # Cargo
        economy/
          player_economy.dart            # PlayerEconomy
          store.dart                     # Store
          repair_shop.dart               # RepairShop
        upgrades/
          upgrade_type.dart              # UpgradeType enum
          upgrade.dart                   # Upgrade
          upgrade_shop.dart              # UpgradeShop
        enemies/
          patrol_path.dart               # PatrolPath
          enemy_spawner.dart             # EnemySpawner
        player/
          player_controller.dart         # PlayerController
        world/
          world_map.dart                 # WorldMap
          warp_gate_manager.dart         # WarpGateManager
        dungeon/
          dungeon.dart                   # Dungeon
          dungeon_layer.dart             # DungeonLayer
          dungeon_manager.dart           # DungeonManager
        hud/
          hud.dart                       # HUD
        collision/
          collision_manager.dart         # CollisionManager

0.1 Engine Setup
  • Create window
  • Fixed update loop
  • Rendering pipeline
  • Input handling
  • Basic entity system
  • Collision system (circle-based for simplicity)

Manual Test
  • App runs stable at target FPS.
  • Input polling works.
  • Objects render at correct coordinates.

⸻

Phase 1 — Game Entry & Background

1.1 Start Screen
  • "Start" button centered.
  • Clicking transitions to main game scene.

1.2 Space Background
  • Black background.
  • Procedurally generate ~300–600 stars.
  • Random size and brightness.
  • Stars remain static (no parallax yet).

Manual Test
  • Start button transitions correctly.
  • Stars render consistently.
  • No performance degradation.

⸻

Phase 2 — Player Ship Core Mechanics

2.1 Base Ship
  • Triangle or minimal vector sprite.
  • Center spawn at (0,0).

2.2 Movement System
  • Rotate left/right.
  • Thrust forward.
  • Thrust backward (weaker than forward).
  • Momentum-based physics.
  • Global friction coefficient (space drag abstraction).

Movement Model:
  • Velocity vector accumulation.
  • Rotation independent from velocity.
  • Cap max speed.

2.3 Health & Fuel
  • Basic numeric properties.
  • No depletion yet.

Manual Test
  • Movement feels responsive.
  • Friction prevents infinite drift.
  • No jitter or rotation instability.

⸻

Phase 3 — Map & Planet Generation

3.1 Fixed World Bounds
  • Define map radius (e.g., 10,000 px).
  • Soft boundary or wrap disabled.

3.2 Planet Generation
  • Random positions.
  • Size: 3–6× ship size.
  • Random color.
  • Random HP.
  • Assign mineral type:
  • Common
  • Rare

3.3 Planet Data Model
  • HP
  • Mineral type
  • Mineral quantity drop range

Manual Test
  • Planets spawn without overlap at start.
  • Collision detection accurate.
  • No spawn inside player.

⸻

Phase 4 — Combat Core

4.1 Shooting
  • Fire button.
  • Projectile velocity based on ship orientation.
  • Fire cooldown timer.

4.2 Bullet-Planet Interaction
  • On collision:
  • Reduce planet HP.
  • Planet flashes red briefly.
  • On HP = 0:
  • Destroy planet.
  • Spawn mineral drops (physics-based float).

4.3 Mineral Drops
  • Two types:
  • Common
  • Rare
  • Pickup via collision.
  • Add to cargo.

Manual Test
  • Flash effect visible.
  • Planets drop correct minerals.
  • Pickup increments cargo.
  • No bullet tunneling issues.

⸻

Phase 5 — HUD

Display:
  • Health
  • Fuel
  • Cargo:
  • Common count
  • Rare count
  • Gold (initialized to 0)

Simple top-left overlay.

Manual Test
  • Values update live.
  • No overlap with gameplay area.
  • Values persist correctly.

⸻

Phase 6 — Warp Gates & Hub

6.1 Warp Gate Spawn Rules
  • Random position.
  • Must be >1000 px from map center.
  • Visible object only (inactive).

6.2 Hub Location
  • Fixed location near center.
  • Docking zone.
  • UI trigger when near hub.

6.3 Hub UI
  • Store
  • Upgrade Shop
  • Repair Shop

Manual Test
  • Gates spawn correctly at valid distance.
  • Hub interaction opens UI.
  • No crash on repeated entry.

⸻

Phase 7 — Economy

7.1 Store
  • Convert minerals → gold.
  • Define exchange rates.
  • Update HUD gold.

7.2 Repair Shop
  • Restore health.
  • Cost scales with missing HP.

Manual Test
  • Selling updates gold correctly.
  • No negative balances.
  • Repair caps at max HP.

⸻

Phase 8 — Upgrade System (Foundation)

Create upgrade framework:

Upgrade Categories:
  • Firepower (damage multiplier)
  • Fire rate
  • Bullet size
  • Homing strength
  • Fuel efficiency
  • Cargo capacity
  • Hull strength
  • Shield strength
  • Shield regeneration speed

Implementation Requirements:
  • Upgrades stack.
  • Persistent across sessions (optional).
  • Affect real stats immediately.
  • Clear UI indicators for levels.

Manual Test
  • Each upgrade visibly changes gameplay.
  • Damage scaling verified numerically.
  • Shield regen timing measurable.

⸻

Phase 9 — Enemy Ships (Open World)

9.1 Spawn System
  • Finite count per cycle.
  • Random roaming behavior.
  • Aggro radius.

9.2 Combat Behavior
  • Predictable movement patterns.
  • Deterministic attack intervals.
  • No randomness in firing spread.

9.3 Enemy Death
  • Drop small gold.
  • Drop small chance of rare mineral.

Manual Test
  • Enemies pursue reliably.
  • No infinite spawn.
  • Combat fair and readable.

⸻

Phase 10 — Warp Gate Loop

10.1 Clear Condition
  • When all enemies defeated:
  • Spawn new warp gate.
  • Spawn new enemy group near gate.

10.2 Gate Activation Logic
  • Gates remain in world.
  • Only one active spawn cycle at a time.

Gameplay Loop:
Clear enemies → New gate appears → Clear gate enemies → Repeat.

Manual Test
  • Loop does not soft-lock.
  • Enemy count finite.
  • Old gates remain persistent.

⸻

Phase 11 — Dungeon Framework

11.1 Dungeon Scene System
  • Separate scene type.
  • Layer-based structure.
  • Entry from selected warp gate.

11.2 Radial Map Generation
  • Circular map.
  • Concentric zones.
  • Entry checkpoint per layer.

Manual Test
  • Can enter and exit dungeon safely.
  • No data corruption on transition.

⸻

Phase 12–15 — Dungeon Layers

Layer 1 – Collector Array
  • Open layout.
  • Patrol drones on fixed paths.
  • Basic hazards.

Layer 2 – Industrial Ring
  • Corridors.
  • Moving hazards.
  • Tighter patrol overlaps.

Layer 3 – Containment Lattice
  • Radiation zones.
  • Gravity distortion (mild ship pull effects).
  • Coordinated drone formations.

Layer 4 – Core
  • AI chamber.
  • Elite constructs.
  • Boss encounter.

Each layer:
  • Entry checkpoint.
  • Extraction cost scaling.
  • Loot tier scaling.

Manual Test per Layer
  • Patrol paths consistent.
  • Attack timing predictable.
  • Extraction returns correctly to hub.
  • Difficulty escalates logically.

⸻

Phase 16 — Four Unique Dungeons

Design 4 Dyson spheres with variations:
  • Sphere A: Balanced.
  • Sphere B: Dense hazards.
  • Sphere C: Heavy enemy density.
  • Sphere D: Environmental distortion emphasis.

Layer parameters adjustable:
  • Enemy count.
  • Hazard density.
  • Extraction cost multiplier.
  • Loot multiplier.

Manual Test
  • Parameter tuning works without code changes.
  • Each dungeon feels distinct.

⸻

Phase 17 — Full Gameplay Loop Test

Validate:
  1. Mine planets.
  2. Sell minerals.
  3. Buy upgrades.
  4. Clear enemy cycles.
  5. Enter dungeon.
  6. Descend layers.
  7. Extract.
  8. Repeat progression.

Check For:
  • Economic balance.
  • Upgrade scaling.
  • Difficulty ramp.
  • Performance stability.
  • Memory leaks.
  • Edge-case crashes (fuel 0, max cargo, etc.).

⸻

Critical Attention Areas
  1. Collision Accuracy – prevent tunneling.
  2. Upgrade Scaling – avoid exponential breakage.
  3. Extraction Logic – avoid duplication exploits.
  4. Spawn Logic – no overlapping entities.
  5. Heat & shield timing precision.
  6. Deterministic AI behavior consistency.

⸻

Completion Definition

Game is considered playable when:
  • Full open-world loop functions.
  • All 4 dungeons fully implemented.
  • All 4 layers per dungeon implemented.
  • All upgrades functional.
  • No soft locks.
  • Balance pass complete.

⸻

This roadmap ensures:
  • Every mechanic is tested in isolation.
  • Core loop validated before dungeon complexity.
  • Systems layered without destabilizing prior work.

⸻

Implementation Notes (Dart/Flutter specifics)
  • float → double in Dart.
  • UUID → String (no external package needed for skeleton).
  • Key enum → GameKey enum (avoids conflict with Flutter's Key type).
  • Renderer wraps Flutter's dart:ui Canvas; passed into render() calls.
  • Game loop will use Flutter's Ticker (SchedulerBinding) in Phase 0.1.
  • SceneType enum added to scene.dart to support Game.changeScene().
