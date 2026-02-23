import 'input_manager.dart';
import 'renderer.dart';
import 'scene.dart';
import '../scenes/dungeon_scene.dart';
import '../scenes/hub_scene.dart';
import '../scenes/overworld_scene.dart';
import '../scenes/start_scene.dart';

class Game {
  final Renderer     renderer;
  final InputManager inputManager;

  Scene? _currentScene;
  bool   _running = false;

  Game({required this.renderer, required this.inputManager});

  Scene? get currentScene => _currentScene;
  bool   get isRunning    => _running;

  void init() {}

  void start() {
    _running = true;
    changeScene(SceneType.start);
  }

  void update(double deltaTime) => _currentScene?.update(deltaTime);
  void render()                 => _currentScene?.render(renderer);

  void shutdown() {
    _currentScene?.onExit();
    _running = false;
  }

  void changeScene(SceneType type) {
    _currentScene?.onExit();
    _currentScene = _createScene(type);
    _currentScene?.onEnter();
  }

  Scene _createScene(SceneType type) => switch (type) {
    SceneType.start     => StartScene(onChangeScene: changeScene,     inputManager: inputManager),
    SceneType.overworld => OverworldScene(onChangeScene: changeScene, inputManager: inputManager),
    SceneType.dungeon   => DungeonScene(onChangeScene: changeScene,   inputManager: inputManager),
    SceneType.hub       => HubScene(onChangeScene: changeScene,       inputManager: inputManager),
  };
}
