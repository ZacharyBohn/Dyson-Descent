import '../entities/enemy_ship.dart';
import '../entities/entity.dart';

class DungeonLayer {
  final int difficultyMultiplier;
  final double extractionCostMultiplier;

  List<EnemyShip> enemies;
  List<Entity> hazards;

  DungeonLayer({
    required this.difficultyMultiplier,
    required this.extractionCostMultiplier,
  })  : enemies = [],
        hazards = [];

  void generate() {
    enemies.clear();
    hazards.clear();
    // Populated by DungeonManager based on dungeon config.
  }

  bool isCleared() => enemies.every((e) => !e.isActive);
}
