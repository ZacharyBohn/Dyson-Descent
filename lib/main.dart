import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'core/game.dart';
import 'core/input_manager.dart';
import 'core/renderer.dart';

void main() {
  runApp(const StarfallApp());
}

class StarfallApp extends StatelessWidget {
  const StarfallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Starfall – Dyson Descent',
      theme: ThemeData.dark(),
      home: const GameShell(),
    );
  }
}

/// Top-level widget that owns the [Game] instance and drives the game loop.
class GameShell extends StatefulWidget {
  const GameShell({super.key});

  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell>
    with SingleTickerProviderStateMixin {
  late final Renderer _renderer;
  late final InputManager _inputManager;
  late final Game _game;
  late final Ticker _ticker;

  Duration _lastTime = Duration.zero;
  final FocusNode _focusNode = FocusNode();

  // Touch input state
  bool   _isTouchThrusting = false;
  bool   _touchMoved       = false;
  double _touchLastX       = 0;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _renderer = Renderer();
    _inputManager = InputManager();
    _game = Game(renderer: _renderer, inputManager: _inputManager);
    _game.init();
    _game.start();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    // Compute delta time; clamp to 100 ms to survive frame spikes.
    final dt = _lastTime == Duration.zero
        ? 0.0
        : (elapsed - _lastTime).inMicroseconds / 1e6;
    _lastTime = elapsed;

    _game.update(dt.clamp(0.0, 0.1));
    _inputManager.flushFrame();
    setState(() {});
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _ticker.dispose();
    _focusNode.dispose();
    _game.shutdown();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Touch input — raw pointer handlers (touch only, ignores mouse/stylus)
  // ---------------------------------------------------------------------------

  void _onPointerDown(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;
    _touchMoved = false;
    _touchLastX = event.localPosition.dx;
    _holdTimer = Timer(const Duration(milliseconds: 200), () {
      _isTouchThrusting = true;
      _inputManager.onKeyDown(GameKey.thrustForward);
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;
    final dx = event.localPosition.dx - _touchLastX;
    _touchLastX = event.localPosition.dx;
    if (dx.abs() > 1) {
      _touchMoved = true;
      if (dx > 0) {
        _inputManager.onKeyDown(GameKey.rotateRight);
        _inputManager.onKeyUp(GameKey.rotateLeft);
      } else {
        _inputManager.onKeyDown(GameKey.rotateLeft);
        _inputManager.onKeyUp(GameKey.rotateRight);
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;
    _holdTimer?.cancel();
    _holdTimer = null;
    final wasThrusting = _isTouchThrusting;
    if (_isTouchThrusting) {
      _inputManager.onKeyUp(GameKey.thrustForward);
      _isTouchThrusting = false;
    }
    if (!_touchMoved && !wasThrusting) {
      _inputManager.onTouchTap();
    }
    _inputManager.onKeyUp(GameKey.rotateLeft);
    _inputManager.onKeyUp(GameKey.rotateRight);
    _touchMoved = false;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;
    _holdTimer?.cancel();
    _holdTimer = null;
    if (_isTouchThrusting) {
      _inputManager.onKeyUp(GameKey.thrustForward);
      _isTouchThrusting = false;
    }
    _inputManager.onKeyUp(GameKey.rotateLeft);
    _inputManager.onKeyUp(GameKey.rotateRight);
    _touchMoved = false;
  }

  GameKey? _mapKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      return GameKey.rotateLeft;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      return GameKey.rotateRight;
    }
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      return GameKey.thrustForward;
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      return GameKey.thrustBackward;
    }
    if (key == LogicalKeyboardKey.space) {
      return GameKey.fire;
    }
    if (key == LogicalKeyboardKey.keyE) {
      return GameKey.interact;
    }
    return null;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final gameKey = _mapKey(event.logicalKey);
    if (gameKey == null) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      _inputManager.onKeyDown(gameKey);
    } else if (event is KeyUpEvent) {
      _inputManager.onKeyUp(gameKey);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Listener(
          onPointerDown:   _onPointerDown,
          onPointerMove:   _onPointerMove,
          onPointerUp:     _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: GestureDetector(
            onTapUp: (details) {
              _inputManager.onMouseClick(details.localPosition);
            },
            child: SizedBox.expand(
              child: CustomPaint(painter: _GamePainter(_game, _renderer)),
            ),
          ),
        ),
      ),
    );
  }
}

class _GamePainter extends CustomPainter {
  final Game _game;
  final Renderer _renderer;

  _GamePainter(this._game, this._renderer);

  @override
  void paint(Canvas canvas, Size size) {
    _renderer.begin(canvas, size);
    _game.render();
    _renderer.end();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
