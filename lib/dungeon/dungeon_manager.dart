import 'dungeon.dart';
import 'dungeon_layer.dart';

class DungeonManager {
  Dungeon? activeDungeon;

  bool get isInDungeon => activeDungeon != null;

  void enterDungeon(String dungeonId) {
    activeDungeon = _buildDungeon(dungeonId);
    activeDungeon?.getCurrentLayer()?.generate();
  }

  void exitDungeon({required bool manualExtraction}) {
    activeDungeon = null;
  }

  void update(double deltaTime) {
    final layer = activeDungeon?.getCurrentLayer();
    if (layer == null) return;

    if (layer.isCleared()) {
      activeDungeon?.advanceLayer();
      activeDungeon?.getCurrentLayer()?.generate();
    }
  }

  Dungeon _buildDungeon(String dungeonId) {
    return Dungeon(
      id: dungeonId,
      layers: [
        DungeonLayer(difficultyMultiplier: 1, extractionCostMultiplier: 1.0),
        DungeonLayer(difficultyMultiplier: 2, extractionCostMultiplier: 1.5),
        DungeonLayer(difficultyMultiplier: 3, extractionCostMultiplier: 2.0),
        DungeonLayer(difficultyMultiplier: 4, extractionCostMultiplier: 3.0),
      ],
    );
  }
}
