import 'dungeon_layer.dart';

class Dungeon {
  final String id;
  final List<DungeonLayer> layers;
  int currentLayerIndex;

  Dungeon({
    required this.id,
    required this.layers,
  }) : currentLayerIndex = 0;

  bool get hasLayers => layers.isNotEmpty;

  DungeonLayer? getCurrentLayer() {
    if (!hasLayers || currentLayerIndex >= layers.length) return null;
    return layers[currentLayerIndex];
  }

  bool get isComplete => currentLayerIndex >= layers.length;

  void advanceLayer() {
    if (currentLayerIndex < layers.length) {
      currentLayerIndex++;
    }
  }
}
