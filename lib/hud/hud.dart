import 'dart:ui';

import '../core/renderer.dart';
import '../economy/player_economy.dart';
import '../entities/ship.dart';
import '../math/vector2.dart';

class HUD {
  static const double _barW = 200;
  static const double _barH = 18;

  void render(Renderer renderer, Ship ship, PlayerEconomy economy) {
    _drawHealthBar(renderer, ship);
    _drawShieldBar(renderer, ship);
    _drawFuelBar(renderer, ship);
    _drawCargo(renderer, ship);
    _drawGold(renderer, economy);
  }

  void _drawHealthBar(Renderer renderer, Ship ship) {
    _drawBar(
      renderer, 10, 10, _barW, _barH,
      ship.health, ship.maxHealth,
      const Color(0xFF22CC44),
      'HP',
    );
  }

  void _drawShieldBar(Renderer renderer, Ship ship) {
    _drawBar(
      renderer, 10, 34, _barW, _barH,
      ship.shield.shieldStrength, ship.shield.maxShieldStrength,
      const Color(0xFF2266FF),
      'SH',
    );
  }

  void _drawFuelBar(Renderer renderer, Ship ship) {
    _drawBar(
      renderer, 10, 58, _barW, _barH,
      ship.fuel, ship.maxFuel,
      const Color(0xFFFF9900),
      'Fuel',
    );
  }

  void _drawCargo(Renderer renderer, Ship ship) {
    _drawBar(
      renderer, 10, 82, _barW, _barH,
      ship.cargo.totalCount.toDouble(), ship.cargo.capacity.toDouble(),
      const Color(0xFF8855BB),
      'Cargo',
    );
  }

  void _drawGold(Renderer renderer, PlayerEconomy economy) {
    const double iconX = 18.0;
    const double iconY = 113.0;
    const double iconR = 7.0;

    // Coin fill
    renderer.canvas.drawCircle(
      const Offset(iconX, iconY),
      iconR,
      Paint()..color = const Color(0xFFFFCC00),
    );
    // Coin rim
    renderer.canvas.drawCircle(
      const Offset(iconX, iconY),
      iconR,
      Paint()
        ..color = const Color(0xFFAA8800)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    renderer.drawText(
      '${economy.gold}g',
      Vector2(30, 106),
    );
  }

  void _drawBar(
    Renderer renderer,
    double x, double y, double w, double h,
    double value, double max,
    Color fillColor,
    String label,
  ) {
    final frac = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    final canvas = renderer.canvas;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(x, y, w, h),
      Paint()..color = const Color(0xFF1A1A1A),
    );

    // Fill
    if (frac > 0) {
      canvas.drawRect(
        Rect.fromLTWH(x, y, w * frac, h),
        Paint()..color = fillColor,
      );
    }

    // Border
    canvas.drawRect(
      Rect.fromLTWH(x, y, w, h),
      Paint()
        ..color = const Color(0xFF888888)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Text inside bar
    renderer.drawText(
      '$label: ${value.toStringAsFixed(0)} / ${max.toStringAsFixed(0)}',
      Vector2(x + 5, y + 2),
      fontSize: 12,
      color: const Color(0xFFFFFFFF),
    );
  }
}
