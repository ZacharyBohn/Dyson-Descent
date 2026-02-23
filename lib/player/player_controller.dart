import '../core/input_manager.dart';
import '../entities/bullet.dart';
import '../entities/ship.dart';

class PlayerController {
  final Ship controlledShip;

  PlayerController({required this.controlledShip});

  /// Handles player input and returns a [Bullet] if one was fired this frame.
  Bullet? handleInput(InputManager input, double deltaTime) {
    controlledShip.isThrustingForward = false;

    if (input.isKeyHeld(GameKey.rotateLeft)) {
      controlledShip.rotateLeft(deltaTime);
    }
    if (input.isKeyHeld(GameKey.rotateRight)) {
      controlledShip.rotateRight(deltaTime);
    }
    if (input.isKeyHeld(GameKey.thrustForward)) {
      controlledShip.thrustForward(deltaTime);
    }
    if (input.isKeyHeld(GameKey.thrustBackward)) {
      controlledShip.thrustBackward(deltaTime);
    }
    if (input.isKeyHeld(GameKey.fire)) {
      return controlledShip.weaponSystem.fire(
        controlledShip.position,
        controlledShip.rotation,
      );
    }
    return null;
  }
}
