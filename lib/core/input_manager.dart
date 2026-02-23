import 'dart:ui';

enum GameKey { rotateLeft, rotateRight, thrustForward, thrustBackward, fire, interact }

class InputManager {
  final Set<GameKey> _pressedThisFrame = {};
  final Set<GameKey> _heldKeys = {};
  bool _mouseClickedThisFrame = false;
  Offset? _mouseClickPosition;

  /// Set by the active scene each frame: true when a tap should trigger
  /// [GameKey.interact] instead of [GameKey.fire] (e.g. near hub or warp gate).
  bool interactionAvailable = false;

  void onKeyDown(GameKey key) {
    _pressedThisFrame.add(key);
    _heldKeys.add(key);
  }

  void onKeyUp(GameKey key) {
    _heldKeys.remove(key);
  }

  void onMouseClick(Offset position) {
    _mouseClickedThisFrame = true;
    _mouseClickPosition = position;
  }

  /// Called by the touch layer on a short tap (no drag, before hold threshold).
  /// Emits [GameKey.interact] when [interactionAvailable], otherwise [GameKey.fire].
  void onTouchTap() {
    _pressedThisFrame.add(
      interactionAvailable ? GameKey.interact : GameKey.fire,
    );
  }

  bool isKeyPressed(GameKey key) => _pressedThisFrame.contains(key);

  bool isKeyHeld(GameKey key) => _heldKeys.contains(key);

  bool isMouseClicked() => _mouseClickedThisFrame;

  Offset? get mouseClickPosition => _mouseClickPosition;

  /// Call at end of each frame to clear single-frame events.
  void flushFrame() {
    _pressedThisFrame.clear();
    _mouseClickedThisFrame = false;
    _mouseClickPosition = null;
  }
}
