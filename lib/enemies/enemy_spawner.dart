import '../entities/enemy_ship.dart';
import '../math/vector2.dart';

class EnemySpawner {
  int maxEnemies;
  final List<EnemyShip> activeEnemies;

  EnemySpawner({this.maxEnemies = 10}) : activeEnemies = [];

  int get aliveCount => activeEnemies.where((e) => e.isActive).length;

  void spawnGroup(Vector2 position, int count) {
    final toSpawn = count.clamp(0, maxEnemies - aliveCount);
    for (int i = 0; i < toSpawn; i++) {
      final offset = Vector2(
        (i % 3 - 1) * 60.0,
        (i ~/ 3 - 1) * 60.0,
      );
      final enemy = EnemyShip(
        id: 'enemy_${DateTime.now().microsecondsSinceEpoch}_$i',
        position: position + offset,
      );
      activeEnemies.add(enemy);
    }
  }

  bool allEnemiesDefeated() => activeEnemies.every((e) => !e.isActive);

  void removeDefeated() {
    activeEnemies.removeWhere((e) => !e.isActive);
  }
}
