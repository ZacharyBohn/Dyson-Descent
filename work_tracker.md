Work Tracking Document

Project: Starfall – Dyson Descent

Development Approach: Incremental vertical slices. Each phase ends with manual playtesting by the developer before proceeding.

Map assumption: Fixed-size world centered at (0,0).

⸻

Phase 0 — Project Skeleton

- [x] 0.0 Class Layout — All classes laid out into individual files under lib/
- [x] 0.1 Engine Setup
  - [x] Create window
  - [x] Fixed update loop
  - [x] Rendering pipeline
  - [x] Input handling
  - [x] Basic entity system
  - [x] Collision system (circle-based)

Manual Test
  - [x] App runs stable at target FPS
  - [x] Input polling works
  - [x] Objects render at correct coordinates

⸻

Phase 1 — Game Entry & Background

- [x] 1.1 Start Screen — "Start" button centered; clicking transitions to overworld
- [x] 1.2 Space Background — black background; ~300–600 procedural stars; random size/brightness

Manual Test
  - [x] Start button transitions correctly
  - [x] Stars render consistently
  - [x] No performance degradation

⸻

Phase 2 — Player Ship Core Mechanics

- [x] 2.1 Base Ship — triangle/minimal vector sprite; center spawn at (0,0)
- [x] 2.2 Movement System — rotate left/right; thrust forward/backward; momentum physics; friction; max speed cap
- [x] 2.3 Health & Energy — basic numeric properties

Manual Test
  - [x] Movement feels responsive
  - [x] Friction prevents infinite drift
  - [x] No jitter or rotation instability

⸻

Phase 3 — Map & Asteroid Generation

- [x] 3.1 Fixed World Bounds — map radius defined; soft boundary
- [x] 3.2 Asteroid Generation — random positions; size 3–6× ship; random color; random HP; mineral type
- [x] 3.3 Asteroid Data Model — HP, mineral type, mineral quantity drop range

Manual Test
  - [x] Asteroids spawn without overlap at start
  - [x] Collision detection accurate
  - [x] No spawn inside player

⸻

Phase 4 — Combat Core

- [x] 4.1 Shooting — fire button; projectile velocity from ship orientation; fire cooldown
- [x] 4.2 Bullet-Asteroid Interaction — reduce HP; flash red on hit; destroy and drop minerals
- [x] 4.3 Mineral Drops — two types; pickup via collision; add to cargo

Manual Test
  - [x] Flash effect visible
  - [x] Asteroids drop correct minerals
  - [x] Pickup increments cargo
  - [x] No bullet tunneling

⸻

Phase 5 — HUD Adjustments & Touch Input

- [x] 5.1 Mini Map Layout Fix — mute button moved below mini map; consistent spacing; no overlap
- [x] 5.2 Touch Input Support
  - [x] Tap (short press) → Shoot
  - [x] Hold (press > threshold) → Thrust forward
  - [x] Swipe left/right → Rotate ship
  - [x] Tap while interaction available → Trigger interact instead of shoot
  - [x] InputManager and PlayerController updated

Manual Test
  - [x] Mute button renders below mini map
  - [x] Tap fires single shot
  - [x] Holding produces sustained thrust
  - [x] Swiping rotates smoothly
  - [x] Touch + keyboard coexist without conflict

⸻

Phase 6 — Hub Station

- [x] 6.1 Hub Location — fixed location near center; docking zone; UI trigger when near
- [x] 6.2 Hub UI — Store, Upgrade Shop, Repair Shop tabs

Manual Test
  - [x] Hub interaction opens UI
  - [x] No crash on repeated entry

⸻

Phase 7 — Economy

- [x] 7.1 Store — convert minerals → gold; exchange rates; update HUD gold
- [x] 7.2 Repair Shop — restore health; cost scales with missing HP

Manual Test
  - [x] Selling updates gold correctly
  - [x] No negative balances
  - [x] Repair caps at max HP

⸻

Phase 8 — Upgrade System (Foundation)

- [x] Upgrade categories: Firepower, Fire rate, Bullet size, Homing strength,
      Energy efficiency, Cargo capacity, Hull strength, Shield strength, Shield regen
- [x] Upgrades stack and affect real stats immediately
- [x] fuelEfficiencyMultiplier on Ship (–10% per level, min 0.10)
- [x] Energy Depot in Repair tab (recharge costs 0.1g/unit)
- [x] Clear UI level indicators

Manual Test
  - [x] Each upgrade visibly changes gameplay
  - [x] Damage scaling verified
  - [x] Shield regen timing measurable

⸻

Phase 9 — Enemy Behavior

- [x] 9.1 Drive-By Combat — enemy maintains offset radius; lateral pass; fires during pass window; separates and re-approaches
- [x] 9.2 No collision suicides; deterministic timing; no tight orbiting
- [x] 9.3 EnemySpawner — spawn groups with circular patrol paths; enemies drop rare minerals on death
- [x] 9.4 Bullet.color + WeaponSystem.fire(bulletColor:) param
- [x] 9.5 Enemy Vision Persistence on Mini Map — visible once seen; remains 60s after last seen; timer resets on re-encounter

Manual Test
  - [x] Enemies do not ram player
  - [x] Clear attack windows; movement readable
  - [x] Enemy appears on minimap when encountered; disappears after 60s unseen

⸻

Phase 10 — Kill-Quota Wave Loop

- [x] 10.1 Clear enemies → new wave spawns near new position
- [x] 10.2 Only one active spawn cycle at a time; old positions remain
- [x] 10.3 Warp-new-system callback wired into hub panel

Manual Test
  - [x] Loop does not soft-lock
  - [x] Enemy count finite
  - [x] Wave respawn works correctly

⸻

Phase 11 — Resource System Rework

- [ ] 11.1 Rename ore types
  - [ ] Change MineralType enum: common → energyOre, rare → materialOre
  - [ ] Update all switch statements and comparisons (mineral_drop.dart, store.dart, hub_panel.dart, world_map.dart)
  - [ ] Rename mineral_type.dart enum and file references to ResourceType (or update in place)

- [ ] 11.2 Asteroid ore ratio and visuals
  - [ ] WorldMap.generateAsteroids(): 80% materialOre, 20% energyOre
  - [ ] Asteroid gets isEnergyOre bool flag from mineralType at construction
  - [ ] Energy ore asteroids render with pulsing green glow (semi-transparent circle at radius+4, alpha from _totalTime)
  - [ ] Material ore asteroids unchanged

- [ ] 11.3 Replace Ship fuel with Ship energy
  - [ ] Rename Ship.fuel → energy, maxFuel → maxEnergy, fuelEfficiencyMultiplier → energyEfficiencyMultiplier
  - [ ] Rename consumeFuel() → consumeEnergy()
  - [ ] Update HUD fuel bar → energy bar (cyan color, label "Energy")
  - [ ] Update HubPanel Repair tab fuel section → energy recharge section
  - [ ] Update repair_shop.dart: calculateRefuelCost → calculateReenergizeCost

- [ ] 11.4 Add Mothership resource pools to economy
  - [ ] PlayerEconomy: add int energyResource, int materialResource
  - [ ] Add addEnergy/spendEnergy/addMaterial/spendMaterial methods
  - [ ] Keep gold temporarily (removed in Phase 13)

Manual Test
  - [ ] ~20% of asteroids spawn with visible green glow; glow pulses
  - [ ] Ship energy bar in HUD replaces fuel bar; depletes on thrust
  - [ ] PlayerEconomy compiles with new fields; no negatives possible

⸻

Phase 12 — Mothership Entity (Player Base)

- [ ] 12.1 Create lib/entities/mothership.dart
  - [ ] Mothership extends LivingEntity
  - [ ] health=1000, maxHealth=1000, radius=60; static (velocity always zero)
  - [ ] render(): large dark-blue hexagon with bright blue outline; "MOTHERSHIP" label; health bar below

- [ ] 12.2 Replace hub point with Mothership in OverworldScene
  - [ ] Remove _hubPos = Vector2(300, 0); add late Mothership _mothership
  - [ ] Initialize _mothership in onEnter() at Vector2(300, 0)
  - [ ] Replace all _hubPos references with _mothership.position
  - [ ] Add _mothership.render(renderer) in world-space render block
  - [ ] Add _mothership.isDead() check → _handleGameOver() stub

- [ ] 12.3 Dock interaction and panel label
  - [ ] Pass mothership position to HubPanel.update()
  - [ ] HubPanel header text: "MOTHERSHIP" (was "STARFALL HUB")

- [ ] 12.4 Mothership on minimap
  - [ ] Update minimap to render player Mothership as a distinct marker

Manual Test
  - [ ] Mothership renders as hexagonal structure; health bar visible
  - [ ] Docking prompt triggers correctly at 250 units; docking at 100 units
  - [ ] Minimap shows Mothership marker

⸻

Phase 13 — Manufacturing Panel & Resource Economy

- [ ] 13.1 Remove gold economy; switch all costs to Energy + Material
  - [ ] Remove gold from PlayerEconomy (or zero and stop displaying)
  - [ ] Upgrade costs: add int energyCost, int materialCost to Upgrade class
  - [ ] UpgradeShop.purchaseUpgrade() deducts energyCost + materialCost
  - [ ] RepairShop.repairShip() costs Material; reEnergizeShip() costs base Energy

- [ ] 13.2 Manufacturing tab in HubPanel
  - [ ] Replace HubTab.store with HubTab.manufacturing
  - [ ] _renderManufacturing(): show ore counts in cargo; show conversion rates (1 ore → 5 resource)
  - [ ] "PROCESS ALL" button: loops cargo, calls economy.addEnergy/addMaterial, clears cargo

- [ ] 13.3 HUD resource display
  - [ ] Remove gold display from HUD
  - [ ] Add "E: N" (cyan) and "M: N" (orange) resource counters

- [ ] 13.4 Upgrades tab cost display
  - [ ] Show "Ne / Nm" resource cost per upgrade row
  - [ ] Affordability check uses both energyResource and materialResource

Manual Test
  - [ ] Collecting energy ore then docking shows count in Manufacturing tab
  - [ ] "PROCESS ALL" converts to correct resource amounts
  - [ ] HUD shows Energy and Material resource values
  - [ ] Upgrade costs display as pairs; purchase deducts correctly
  - [ ] Zero-resource states handled without negatives

⸻

Phase 14 — Ship Destruction and Respawn

- [ ] 14.1 Player death detection in OverworldScene.update()
  - [ ] if (_ship.isDead()) → _handlePlayerDeath()
  - [ ] _handlePlayerDeath(): set ship inactive; show "SHIP DESTROYED" notification; start _respawnTimer = 3.0
  - [ ] During countdown: input disabled; "Respawning in Xs..." text shown

- [ ] 14.2 Respawn cost and logic
  - [ ] Respawn material cost: 50 (constant; upgradeable via Phase 15)
  - [ ] After countdown: if materialResource >= respawnCost → spend → spawn new Ship at mothership.position + offset
  - [ ] If insufficient material: show "Insufficient Material — waiting..." until available

- [ ] 14.3 Game-over condition — Mothership destroyed
  - [ ] if (_mothership.isDead()): show "MOTHERSHIP DESTROYED — GAME OVER" overlay
  - [ ] "RESTART" button → SceneType.start

- [ ] 14.4 Mothership takes enemy damage
  - [ ] _checkEnemyBulletMothershipCollisions()
  - [ ] _checkEnemyRamMothershipCollisions(double dt)

Manual Test
  - [ ] Ship destroyed: 3s countdown shown, then new ship spawns consuming 50 Material
  - [ ] Zero Material: warning shown; waits until resources available
  - [ ] Mothership health depletes from stray enemy fire
  - [ ] Mothership destroyed → Game Over screen; Restart resets cleanly

⸻

Phase 15 — Base Upgrade System

- [ ] 15.1 New upgrade categories in UpgradeType
  - [ ] respawnCost: each level −10 Material from respawn cost (min 10)
  - [ ] shipMaxEnergy: each level +200 to Ship.maxEnergy
  - [ ] collectorDroneSlots: each level +1 drone slot (max 4)
  - [ ] turretSlots: each level +1 turret slot (max 4)

- [ ] 15.2 Base Upgrades tab in HubPanel
  - [ ] Add HubTab.baseUpgrades
  - [ ] _renderBaseUpgrades(): list base-level upgrades with resource costs
  - [ ] Rename existing Upgrades tab to "SHIP UPGRADES"

- [ ] 15.3 Apply base upgrade effects
  - [ ] respawnCost: OverworldScene reads level to compute actual cost
  - [ ] shipMaxEnergy: Upgrade.apply() adds to ship.maxEnergy on purchase
  - [ ] collectorDroneSlots / turretSlots: store level; gate BUILD buttons in Phase 17

Manual Test
  - [ ] BASE tab visible in panel
  - [ ] Purchasing respawnCost upgrade reduces Material cost on next death
  - [ ] Purchasing shipMaxEnergy upgrade increases energy bar length
  - [ ] Drone/turret slot upgrades purchase cleanly (no effect until Phase 17)

⸻

Phase 16 — Enemy Mothership

- [ ] 16.1 Create lib/entities/enemy_mothership.dart
  - [ ] EnemyMothership extends LivingEntity
  - [ ] health=800, maxHealth=800, radius=60; static position
  - [ ] Internal _energyResource=200, _materialResource=200
  - [ ] render(): dark-red hexagon with red outline; "ENEMY MOTHERSHIP" label; health bar

- [ ] 16.2 Spawn trigger
  - [ ] OverworldScene: track _gameTimer; at 180s → instantiate EnemyMothership at Vector2(-3000, 0)
  - [ ] Spawn 2 CollectorShip(isEnemy: true) near enemy Mothership

- [ ] 16.3 Create lib/entities/collector_ship.dart
  - [ ] CollectorShip extends LivingEntity; bool isEnemy; health=40
  - [ ] Behavior: fly to nearest ore asteroid → hover 1.5s (mining) → fly back to owning Mothership → deposit ore
  - [ ] render(): small diamond; blue tint if player-owned, red tint if enemy-owned
  - [ ] On death: drops 1–3 material ore at location

- [ ] 16.4 Enemy Mothership builds replacement combat ships
  - [ ] When an enemy combat ship is killed: if _materialResource >= 50 → deduct → spawn replacement after 5s

- [ ] 16.5 Enemy combat ships can target player Mothership
  - [ ] Add Vector2? targetOverride to EnemyShip.updateAI()
  - [ ] When enemy ship within 600 units of player Mothership and player ship is far: switch to attacking Mothership

- [ ] 16.6 Victory condition
  - [ ] if (_enemyMothership.isDead()): show "ENEMY MOTHERSHIP DESTROYED — VICTORY!" overlay
  - [ ] "PLAY AGAIN" → SceneType.start

Manual Test
  - [ ] Game runs 3 minutes; Enemy Mothership appears at far edge
  - [ ] Enemy collectors mine asteroids, return to enemy Mothership
  - [ ] Enemy combat ships switch target to player Mothership when player is distant
  - [ ] Enemy rebuilds a combat ship after one is destroyed (if resources available)
  - [ ] Destroying Enemy Mothership shows victory screen
  - [ ] Player Mothership destroyed shows game over screen

⸻

Phase 17 — Player Automation (Drones and Turrets)

- [ ] 17.1 Player collector drones
  - [ ] Reuse CollectorShip with isEnemy=false
  - [ ] OverworldScene tracks _playerCollectors list
  - [ ] "BUILD COLLECTOR DRONE" button in Manufacturing tab (visible if collectorDroneSlots > 0)
  - [ ] Cost: 30 Energy + 80 Material; cap at upgrade level
  - [ ] Player drones mine energy ore asteroids; deposit into economy.energyResource

- [ ] 17.2 Defense turrets
  - [ ] Create lib/entities/turret.dart: Turret extends Entity
  - [ ] Anchored to Mothership at N/E/S/W positions (radius+20)
  - [ ] Finds nearest enemy within range=500; rotates toward it; fires once per 2.0s
  - [ ] render(): small filled square with aim-direction line
  - [ ] "BUILD TURRET" button in Base Upgrades tab (visible if turretSlots > 0)
  - [ ] Cost: 20 Energy + 120 Material; max 4 turrets

- [ ] 17.3 Drone/turret slot gating
  - [ ] BUILD buttons disabled when slot cap reached
  - [ ] Slots from Phase 15 upgrades now actually gate the buttons

Manual Test
  - [ ] After buying drone slot upgrade, BUILD button appears; drone spawns and mines independently
  - [ ] Drone returns to Mothership; Energy resource pool increases
  - [ ] After buying turret slot, BUILD button appears; turret renders at Mothership
  - [ ] Turret rotates toward nearest enemy; fires and deals damage
  - [ ] Multiple turrets aim independently
  - [ ] Drone and turret counts capped at slot limits

⸻

Phase 18 — Enemy Progression & Balance Pass

- [ ] 18.1 Enemy upgrade timer in EnemyMothership.update()
  - [ ] t=270s: enemy combat ships gain +20 HP
  - [ ] t=360s: enemy adds 3rd collector ship
  - [ ] t=450s: enemy combat ships gain +10% fire rate
  - [ ] t=540s: enemy adds 2 more combat ships

- [ ] 18.2 Enemy resource-to-build loop
  - [ ] When _materialResource >= 150 and below combat ship cap → spend 50 → build 1 ship
  - [ ] Destroying enemy collectors slows enemy production (strategic pressure)

- [ ] 18.3 Collector ships can be targeted and destroyed
  - [ ] CollectorShip health=40; flees when shot (no combat AI)
  - [ ] Enemy Mothership replaces destroyed collectors: 20 Material, 10s delay

- [ ] 18.4 Full balance pass
  - [ ] Tune: asteroid count, ore ratios, conversion rates, upgrade costs, respawn cost, enemy HP scaling, collector mining rate, turret fire rate
  - [ ] Verify: neither side wins trivially in <3min; player mining window meaningful; enemy pressure escalates gradually

- [ ] 18.5 HUD and minimap additions
  - [ ] Enemy Mothership: always-visible large red square on minimap
  - [ ] Player Mothership health bar added to HUD (bottom, orange-red)
  - [ ] Elapsed game time display (top-center, small) so player anticipates enemy escalation

Manual Test
  - [ ] Full session: 0–3min mining; 3min enemy arrives; 4.5min enemy upgrade; etc.
  - [ ] Game winnable but requires active play; passive drone-only strategy fails
  - [ ] All HUD additions render without overlap
  - [ ] No crashes over a 10-minute session
  - [ ] Memory stable (no inactive entity accumulation)

⸻

Critical Attention Areas

  1. Resource Balance — ensure mining rate, conversion, and upgrade costs create meaningful decisions without trivial snowball.
  2. Mothership Targeting — enemy ships switching to attack Mothership must feel intentional, not random.
  3. Respawn Gate — zero-material respawn block must not soft-lock; automation from Phase 17 must be able to unblock it.
  4. Collector Pathfinding — simple seek behavior must not cause collectors to cluster on one asteroid or get stuck at world edge.
  5. Collision Accuracy — Mothership is large (radius=60); bullet and ram checks must not miss at high ship speeds.
  6. Enemy Escalation Timing — upgrades at 270/360/450/540s must be tunable without recompile (constants in EnemyMothership).
  7. Entity Lifecycle — destroyed ships, spent drones, and replaced collectors must be removed from lists to prevent memory growth.

⸻

Completion Definition

Game is considered playable when:
  • Full simulation loop functions: mine → process → upgrade → defend.
  • Enemy Mothership spawns, builds a fleet, and mounts an attack on the player Mothership.
  • Both win condition (enemy destroyed) and lose condition (player Mothership destroyed) trigger correctly.
  • Player automation (drones + turrets) noticeably changes the mid-game resource curve.
  • No soft locks (zero-resource respawn handled; enemy ship rebuild handled).
  • Balance pass complete: games last 8–15 minutes with active play.

⸻

Implementation Notes (Dart/Flutter specifics)
  • float → double in Dart.
  • UUID → String (no external package needed for skeleton).
  • Key enum → GameKey enum (avoids conflict with Flutter's Key type).
  • Renderer wraps Flutter's dart:ui Canvas; passed into render() calls.
  • Game loop uses Flutter's Ticker (SchedulerBinding).
  • SceneType enum in scene.dart: { start, overworld }.
