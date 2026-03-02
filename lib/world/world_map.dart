import 'dart:math' as math;
import 'dart:ui';

import '../entities/enemy_ship.dart';
import '../entities/planet.dart';
import '../math/vector2.dart';
import '../resources/mineral_type.dart';

class WorldMap {
  final double radius;
  final List<Asteroid> planets;
  final List<EnemyShip> enemies;

  final math.Random _rng;

  WorldMap({this.radius = 10000, int? seed})
      : planets = [],
        enemies = [],
        _rng = math.Random(seed);

  void generateAsteroids(int count) {
    planets.clear();
    for (int i = 0; i < count; i++) {
      final pos = _randomPosition(minDist: 400);
      final type = _rng.nextDouble() < 0.7 ? MineralType.common : MineralType.rare;
      // 3–6× ship radius (ship radius = 12)
      final asteroidRadius = 36.0 + _rng.nextDouble() * 36.0;
      final hp = 50 + _rng.nextInt(150).toDouble();

      planets.add(Asteroid(
        id: 'asteroid_$i',
        position: pos,
        radius: asteroidRadius,
        health: hp,
        maxHealth: hp,
        mineralType: type,
        dropAmount: 3 + _rng.nextInt(8),
        color: _randomAsteroidColor(),
      ));
    }
  }

  // Kept for backwards compatibility; calls generateAsteroids internally.
  void generatePlanets(int count) => generateAsteroids(count);

  Color _randomAsteroidColor() {
    if (_rng.nextBool()) {
      // Brown shades — hue 18–42°, medium saturation, dark-ish value
      final hue = 18.0 + _rng.nextDouble() * 24.0;
      final sat = 0.35 + _rng.nextDouble() * 0.25;
      final val = 0.28 + _rng.nextDouble() * 0.24;
      return _hsvToColor(hue, sat, val);
    } else {
      // Grey shades — near-zero saturation
      final val = 0.25 + _rng.nextDouble() * 0.28;
      final tint = _rng.nextDouble() * 0.06; // tiny warm or cool tint
      return _hsvToColor(0, tint, val);
    }
  }

  Color _hsvToColor(double h, double s, double v) {
    final hi = (h / 60).floor() % 6;
    final f = h / 60 - (h / 60).floor();
    final p = v * (1 - s);
    final q = v * (1 - f * s);
    final t = v * (1 - (1 - f) * s);
    double r, g, b;
    switch (hi) {
      case 0: r = v; g = t; b = p;
      case 1: r = q; g = v; b = p;
      case 2: r = p; g = v; b = t;
      case 3: r = p; g = q; b = v;
      case 4: r = t; g = p; b = v;
      default: r = v; g = p; b = q;
    }
    return Color.fromARGB(255, (r * 255).round(), (g * 255).round(), (b * 255).round());
  }

  Vector2 _randomPosition({double minDist = 0}) {
    Vector2 pos;
    int attempts = 0;
    do {
      final x = (_rng.nextDouble() * 2 - 1) * radius;
      final y = (_rng.nextDouble() * 2 - 1) * radius;
      pos = Vector2(x, y);
      attempts++;
    } while (attempts < 50 &&
        (Vector2.distance(pos, Vector2.zero()) < minDist ||
            _isTooClose(pos, minDist)));
    return pos;
  }

  bool _isTooClose(Vector2 pos, double minDist) {
    for (final planet in planets) {
      if (Vector2.distance(pos, planet.position) < minDist) return true;
    }
    return false;
  }
}
