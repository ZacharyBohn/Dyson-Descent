import 'input_manager.dart';
import 'renderer.dart';

enum SceneType { start, overworld, dungeon, hub }

abstract class Scene {
  final void Function(SceneType) onChangeScene;
  final InputManager inputManager;

  Scene({required this.onChangeScene, required this.inputManager});

  void onEnter() {}
  void onExit()  {}
  void update(double deltaTime);
  void render(Renderer renderer);
}
