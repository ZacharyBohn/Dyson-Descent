Low-Level Design (LLD)

Project: Starfall – Dyson Descent

Scope: Class structure and method signatures only (no implementation detail)

Language-agnostic OOP structure.

⸻

1. Core Engine Layer

1.1 Game

class Game {
    void init();
    void start();
    void update(float deltaTime);
    void render();
    void shutdown();

    void changeScene(SceneType type);
}


⸻

1.2 Scene (Abstract)

abstract class Scene {
    void onEnter();
    void onExit();
    void update(float deltaTime);
    void render();
}

Concrete Scenes

class StartScene extends Scene
class OverworldScene extends Scene
class DungeonScene extends Scene
class HubScene extends Scene


⸻

1.3 InputManager

class InputManager {
    bool isKeyPressed(Key key);
    bool isKeyHeld(Key key);
    bool isMouseClicked();
}


⸻

1.4 Renderer

class Renderer {
    void drawEntity(Entity e);
    void drawText(string text, Vector2 position);
    void drawCircle(Vector2 position, float radius, Color color);
}


⸻

2. Math / Utility

class Vector2 {
    float x;
    float y;

    float length();
    void normalize();
    static float distance(Vector2 a, Vector2 b);
}


⸻

3. Entity System

3.1 Base Entity

abstract class Entity {
    UUID id;
    Vector2 position;
    Vector2 velocity;
    float rotation;
    float radius;
    bool isActive;

    void update(float deltaTime);
    void render(Renderer renderer);
    void onCollision(Entity other);
}


⸻

3.2 LivingEntity

abstract class LivingEntity extends Entity {
    float health;
    float maxHealth;

    void takeDamage(float amount);
    bool isDead();
}


⸻

4. Player & Ship

4.1 Ship

class Ship extends LivingEntity {
    float fuel;
    float maxFuel;

    float thrustPower;
    float reverseThrustPower;
    float rotationSpeed;
    float frictionCoefficient;

    WeaponSystem weaponSystem;
    Shield shield;
    Cargo cargo;

    void rotateLeft(float deltaTime);
    void rotateRight(float deltaTime);
    void thrustForward(float deltaTime);
    void thrustBackward(float deltaTime);
    void applyFriction(float deltaTime);
    void consumeFuel(float amount);
}


⸻

4.2 PlayerController

class PlayerController {
    Ship controlledShip;

    void handleInput(InputManager input, float deltaTime);
}


⸻

5. Combat System

5.1 WeaponSystem

class WeaponSystem {
    float fireRate;
    float damageMultiplier;
    float bulletSize;
    float homingStrength;
    float heat;
    float maxHeat;

    void fire(Vector2 position, float rotation);
    void update(float deltaTime);
}


⸻

5.2 Bullet

class Bullet extends Entity {
    float damage;
    float lifetime;
    float homingStrength;

    void update(float deltaTime);
}


⸻

5.3 Shield

class Shield {
    float shieldStrength;
    float maxShieldStrength;
    float regenerationRate;
    float regenerationDelay;
    float timeSinceHit;

    void absorbDamage(float amount);
    void update(float deltaTime);
}


⸻

6. Resource System

6.1 MineralType

enum MineralType {
    COMMON,
    RARE
}


⸻

6.2 MineralDrop

class MineralDrop extends Entity {
    MineralType type;
    int quantity;

    void collect(Ship ship);
}


⸻

6.3 Cargo

class Cargo {
    int commonCount;
    int rareCount;
    int capacity;

    bool canStore(int amount);
    void add(MineralType type, int amount);
    void remove(MineralType type, int amount);
}


⸻

7. Planets

class Planet extends LivingEntity {
    MineralType mineralType;
    int dropAmount;

    void flashDamage();
    void onDestroyed();
}


⸻

8. Economy

8.1 PlayerEconomy

class PlayerEconomy {
    int gold;

    void addGold(int amount);
    bool spendGold(int amount);
}


⸻

8.2 Store

class Store {
    int getSellValue(MineralType type, int quantity);
    void sellMinerals(PlayerEconomy economy, Cargo cargo);
}


⸻

8.3 RepairShop

class RepairShop {
    int calculateRepairCost(Ship ship);
    void repairShip(Ship ship, PlayerEconomy economy);
}


⸻

9. Upgrade System

9.1 UpgradeType

enum UpgradeType {
    FIREPOWER,
    FIRE_RATE,
    BULLET_SIZE,
    HOMING,
    FUEL_EFFICIENCY,
    CARGO_CAPACITY,
    HULL_STRENGTH,
    SHIELD_STRENGTH,
    SHIELD_REGEN
}


⸻

9.2 Upgrade

class Upgrade {
    UpgradeType type;
    int level;
    int maxLevel;
    int baseCost;

    int getCost();
    void apply(Ship ship);
}


⸻

9.3 UpgradeShop

class UpgradeShop {
    List<Upgrade> availableUpgrades;

    bool purchaseUpgrade(UpgradeType type, PlayerEconomy economy, Ship ship);
}


⸻

10. Enemies

10.1 EnemyShip

class EnemyShip extends LivingEntity {
    float detectionRadius;
    PatrolPath patrolPath;
    WeaponSystem weaponSystem;

    void updateAI(Ship player, float deltaTime);
}


⸻

10.2 PatrolPath

class PatrolPath {
    List<Vector2> waypoints;
    int currentIndex;
    float moveSpeed;

    Vector2 getNextTarget();
    void advance();
}


⸻

10.3 EnemySpawner

class EnemySpawner {
    int maxEnemies;
    List<EnemyShip> activeEnemies;

    void spawnGroup(Vector2 position, int count);
    bool allEnemiesDefeated();
}


⸻

11. Warp Gates

class WarpGate extends Entity {
    bool isActive;
    UUID dungeonId;

    void activate();
    void deactivate();
}


⸻

11.1 WarpGateManager

class WarpGateManager {
    List<WarpGate> gates;

    void spawnGate(Vector2 position);
    WarpGate getActiveGate();
}


⸻

12. Dungeon System

12.1 Dungeon

class Dungeon {
    UUID id;
    List<DungeonLayer> layers;
    int currentLayerIndex;

    DungeonLayer getCurrentLayer();
    void advanceLayer();
}


⸻

12.2 DungeonLayer

class DungeonLayer {
    int difficultyMultiplier;
    float extractionCostMultiplier;

    List<EnemyShip> enemies;
    List<Entity> hazards;

    void generate();
    bool isCleared();
}


⸻

12.3 DungeonManager

class DungeonManager {
    Dungeon activeDungeon;

    void enterDungeon(UUID dungeonId);
    void exitDungeon(bool manualExtraction);
    void update(float deltaTime);
}


⸻

13. AI Core (Final Layer)

class AICore extends LivingEntity {
    void initializePhase(int phase);
    void updateAI(Ship player, float deltaTime);
}


⸻

14. Map System

class WorldMap {
    float radius;
    List<Planet> planets;
    List<EnemyShip> enemies;
    List<WarpGate> gates;

    void generatePlanets(int count);
    void generateWarpGates(int count);
}


⸻

15. HUD

class HUD {
    void render(Ship ship, PlayerEconomy economy);
}


⸻

16. Collision System

class CollisionManager {
    void detectCollisions(List<Entity> entities);
}


⸻

17. Game Flow Summary

High-level object ownership:
	•	Game
	•	Current Scene
	•	OverworldScene
	•	WorldMap
	•	PlayerController
	•	EnemySpawner
	•	WarpGateManager
	•	DungeonScene
	•	DungeonManager
	•	PlayerController
	•	HubScene
	•	Store
	•	UpgradeShop
	•	RepairShop

⸻

This LLD supports:
	•	Open-world loop.
	•	Deterministic enemy patrol logic.
	•	Upgrade scaling.
	•	Multi-dungeon layered design.
	•	Resource economy.
	•	Extract-or-die run system.
	•	Expandable AI core phases.