import 'dart:math' as math;
import 'dart:ui';

import '../core/renderer.dart';
import '../resources/mineral_type.dart';
import 'entity.dart';

class Asteroid extends LivingEntity {
  MineralType mineralType;
  int dropAmount;
  Color color;

  bool _isFlashing = false;
  double _flashTimer = 0;
  static const double _flashDuration = 0.15;

  late final List<Offset> _craterOffsets;
  late final List<double> _craterRadii;

  Asteroid({
    required super.id,
    required super.position,
    super.radius = 40,
    super.health = 100,
    super.maxHealth = 100,
    required this.mineralType,
    required this.dropAmount,
    required this.color,
  }) {
    final rng = math.Random(id.hashCode);
    final craterCount = 6 + rng.nextInt(4); // 6–9 craters per asteroid
    _craterOffsets = [];
    _craterRadii = [];
    for (int i = 0; i < craterCount; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final dist = rng.nextDouble() * radius * 0.45;
      _craterOffsets.add(Offset(math.cos(angle) * dist, math.sin(angle) * dist));
      _craterRadii.add(radius * 0.12 + rng.nextDouble() * radius * 0.21);
    }
  }

  bool get isFlashing => _isFlashing;

  void flashDamage() {
    _isFlashing = true;
    _flashTimer = _flashDuration;
  }

  void onDestroyed() {
    isActive = false;
  }

  @override
  void takeDamage(double amount) {
    health = (health - amount).clamp(0.0, maxHealth);
    flashDamage();
    if (isDead()) onDestroyed();
  }

  @override
  void update(double deltaTime) {
    if (_isFlashing) {
      _flashTimer -= deltaTime;
      if (_flashTimer <= 0) _isFlashing = false;
    }
  }

  @override
  void render(Renderer renderer) {
    if (_isFlashing) {
      renderer.drawCircle(position, radius, const Color(0xFFFF3333));
      return;
    }

    // Base body
    renderer.drawCircle(position, radius, color);

    // Dark crater spots
    final cx = position.x;
    final cy = position.y;
    final craterColor = Color.fromARGB(
      180,
      ((color.r * 255.0).round().clamp(0, 255) * 0.38).round(),
      ((color.g * 255.0).round().clamp(0, 255) * 0.38).round(),
      ((color.b * 255.0).round().clamp(0, 255) * 0.38).round(),
    );
    for (int i = 0; i < _craterOffsets.length; i++) {
      renderer.canvas.drawCircle(
        Offset(cx + _craterOffsets[i].dx, cy + _craterOffsets[i].dy),
        _craterRadii[i],
        Paint()..color = craterColor,
      );
    }

    // Subtle rim
    renderer.canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = const Color(0x22FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  void onCollision(Entity other) {}
}

// Backwards-compat alias so any code still using the name `Planet` compiles.
typedef Planet = Asteroid;
