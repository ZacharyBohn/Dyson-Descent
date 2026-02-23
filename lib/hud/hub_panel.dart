import 'dart:ui';

import '../core/input_manager.dart';
import '../core/renderer.dart';
import '../economy/player_economy.dart';
import '../economy/repair_shop.dart';
import '../economy/store.dart';
import '../entities/ship.dart';
import '../math/vector2.dart';
import '../upgrades/upgrade_shop.dart';
import '../upgrades/upgrade_type.dart';

enum HubTab { store, repair, upgrades }

/// Owns hub station overlay state, interaction, and rendering.
///
/// Services (Store, RepairShop, UpgradeShop) live here so upgrade levels
/// persist across hub visits within a session.
///
/// Usage in OverworldScene:
///   update() → hubPanel.update(input:, shipPos:, hubPos:, ship:, economy:)
///   render() → if (hubPanel.isOpen) hubPanel.render(renderer, ship, economy)
class HubPanel {
  // World-space constants
  static const double dockRadius   = 100.0;
  static const double promptRadius = dockRadius * 2.5;

  final Store        _store        = Store();
  final RepairShop   _repairShop   = RepairShop();
  final UpgradeShop  _upgradeShop  = UpgradeShop();

  bool   isOpen    = false;
  HubTab _activeTab = HubTab.store;

  /// Called when the player activates the warp drive. Assign in OverworldScene.
  void Function()? onWarpNewSystem;

  // Warp drive cooldown (30 minutes)
  static const Duration _warpCooldown = Duration(minutes: 30);
  DateTime? _lastWarpTime;

  bool get _canWarp {
    if (_lastWarpTime == null) return true;
    return DateTime.now().difference(_lastWarpTime!) >= _warpCooldown;
  }

  Duration get _warpCooldownRemaining {
    if (_canWarp) return Duration.zero;
    return _warpCooldown - DateTime.now().difference(_lastWarpTime!);
  }

  // Button rects rebuilt each render(), read back during next-frame update().
  Rect _closeRect        = Rect.zero;
  Rect _tabStoreRect     = Rect.zero;
  Rect _tabRepairRect    = Rect.zero;
  Rect _tabUpgradesRect  = Rect.zero;
  Rect _actionBtnRect    = Rect.zero;
  Rect _refuelBtnRect    = Rect.zero;
  Rect _warpBtnRect      = Rect.zero;
  final List<Rect> _upgradeRects = List.filled(9, Rect.zero);

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  void update({
    required InputManager  input,
    required Vector2       shipPos,
    required Vector2       hubPos,
    required Ship          ship,
    required PlayerEconomy economy,
  }) {
    final nearHub = Vector2.distance(shipPos, hubPos) < dockRadius;

    if (input.isKeyPressed(GameKey.interact)) {
      if (isOpen) {
        isOpen = false;
      } else if (nearHub) {
        isOpen    = true;
        _activeTab = HubTab.store;
      }
    }

    if (isOpen && input.isMouseClicked()) {
      final pos = input.mouseClickPosition;
      if (pos != null) _handleClick(pos, ship: ship, economy: economy);
    }
  }

  void _handleClick(Offset pos, {required Ship ship, required PlayerEconomy economy}) {
    if (_closeRect.contains(pos))        { isOpen = false; return; }
    if (_tabStoreRect.contains(pos))     { _activeTab = HubTab.store;    return; }
    if (_tabRepairRect.contains(pos))    { _activeTab = HubTab.repair;   return; }
    if (_tabUpgradesRect.contains(pos))  { _activeTab = HubTab.upgrades; return; }

    if (_warpBtnRect != Rect.zero && _warpBtnRect.contains(pos)) {
      if (_canWarp) {
        _lastWarpTime = DateTime.now();
        isOpen = false;
        onWarpNewSystem?.call();
      }
      return;
    }

    switch (_activeTab) {
      case HubTab.store:
        if (_actionBtnRect.contains(pos)) _store.sellMinerals(economy, ship.cargo);
      case HubTab.repair:
        if (_actionBtnRect.contains(pos)) _repairShop.repairShip(ship, economy);
        if (_refuelBtnRect.contains(pos)) _repairShop.refuelShip(ship, economy);
      case HubTab.upgrades:
        for (int i = 0; i < _upgradeRects.length; i++) {
          if (_upgradeRects[i] != Rect.zero && _upgradeRects[i].contains(pos)) {
            _upgradeShop.purchaseUpgrade(
                _upgradeShop.availableUpgrades[i].type, economy, ship);
            break;
          }
        }
    }
  }

  // ---------------------------------------------------------------------------
  // Render – call only when isOpen
  // ---------------------------------------------------------------------------

  void render(Renderer renderer, Ship ship, PlayerEconomy economy) {
    final w = renderer.size.width;
    final h = renderer.size.height;

    const pw = 560.0;
    const ph = 500.0;
    final px = (w - pw) / 2;
    final py = (h - ph) / 2;
    final panelRect = Rect.fromLTWH(px, py, pw, ph);

    // Dimmed backdrop
    renderer.canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0x88000000),
    );

    // Panel background + border
    renderer.canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(8)),
      Paint()..color = const Color(0xFF0A1A2A),
    );
    renderer.canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(8)),
      Paint()
        ..color = const Color(0xFF335577)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Header
    renderer.drawText('STARFALL HUB', Vector2(px + 16, py + 10),
        color: const Color(0xFF88CCFF), fontSize: 18);
    _closeRect = _drawBtn(renderer, 'CLOSE', Offset(px + pw - 74, py + 8), 66, 26);

    // Tab bar
    renderer.canvas.drawRect(
      Rect.fromLTWH(px, py + 42, pw, 36),
      Paint()..color = const Color(0xFF081422),
    );
    final tabW = pw / 3;
    _tabStoreRect    = _drawTab(renderer, 'STORE',    Offset(px,           py + 42), tabW, 36, _activeTab == HubTab.store);
    _tabRepairRect   = _drawTab(renderer, 'REPAIR',   Offset(px + tabW,    py + 42), tabW, 36, _activeTab == HubTab.repair);
    _tabUpgradesRect = _drawTab(renderer, 'UPGRADES', Offset(px + 2*tabW,  py + 42), tabW, 36, _activeTab == HubTab.upgrades);

    // Content area
    final cl = px + 16;
    final ct = py + 88.0;
    final cw = pw - 32;

    switch (_activeTab) {
      case HubTab.store:    _renderStore(renderer, cl, ct, cw, ship, economy);
      case HubTab.repair:   _renderRepair(renderer, cl, ct, cw, ship, economy);
      case HubTab.upgrades: _renderUpgrades(renderer, cl, ct, cw, ship, economy);
    }

    _renderWarpFooter(renderer, px, py, pw);
  }

  // ---------------------------------------------------------------------------
  // Tab content
  // ---------------------------------------------------------------------------

  void _renderStore(
      Renderer renderer, double cl, double ct, double cw, Ship ship, PlayerEconomy economy) {
    final common    = ship.cargo.commonCount;
    final rare      = ship.cargo.rareCount;
    final commonVal = common * 5;
    final rareVal   = rare * 25;
    final total     = commonVal + rareVal;

    renderer.drawText('MINERAL EXCHANGE', Vector2(cl, ct),
        color: const Color(0xFF88CCFF), fontSize: 14);
    renderer.drawText('Common:  $common × 5g  =  ${commonVal}g', Vector2(cl, ct + 34), fontSize: 13);
    renderer.drawText('Rare:    $rare × 25g  =  ${rareVal}g',    Vector2(cl, ct + 58), fontSize: 13);

    renderer.canvas.drawLine(Offset(cl, ct + 84), Offset(cl + cw, ct + 84),
        Paint()..color = const Color(0xFF335577)..strokeWidth = 1);

    renderer.drawText('Total value:  ${total}g', Vector2(cl, ct + 92),
        color: const Color(0xFFFFDD66), fontSize: 14);

    final canSell = total > 0;
    _actionBtnRect = _drawBtn(renderer, 'SELL ALL', Offset(cl, ct + 124), 130, 36, enabled: canSell);
    if (!canSell) {
      renderer.drawText('No minerals in cargo.', Vector2(cl + 142, ct + 134),
          color: const Color(0xFF556677), fontSize: 12);
    }
  }

  void _renderRepair(
      Renderer renderer, double cl, double ct, double cw, Ship ship, PlayerEconomy economy) {
    final hp    = ship.health;
    final maxHp = ship.maxHealth;
    final repairCost = _repairShop.calculateRepairCost(ship);
    final gold  = economy.gold;

    // --- Hull repair ---
    renderer.drawText('REPAIR DOCK', Vector2(cl, ct),
        color: const Color(0xFF88CCFF), fontSize: 14);
    renderer.drawText(
        'Hull:  ${hp.toStringAsFixed(0)} / ${maxHp.toStringAsFixed(0)} HP',
        Vector2(cl, ct + 28), fontSize: 13);

    final barW   = cw * 0.55;
    final hpRatio = (hp / maxHp).clamp(0.0, 1.0);
    renderer.canvas.drawRect(Rect.fromLTWH(cl, ct + 50, barW, 12),
        Paint()..color = const Color(0xFF1A2A3A));
    renderer.canvas.drawRect(Rect.fromLTWH(cl, ct + 50, barW * hpRatio, 12),
        Paint()..color = _hpBarColor(hpRatio));
    renderer.canvas.drawRect(Rect.fromLTWH(cl, ct + 50, barW, 12),
        Paint()..color = const Color(0xFF335577)..style = PaintingStyle.stroke..strokeWidth = 1);

    renderer.drawText('Repair cost:  ${repairCost}g   •   Gold:  ${gold}g',
        Vector2(cl, ct + 70), fontSize: 12);

    if (repairCost <= 0) {
      renderer.drawText('Hull is at full integrity.', Vector2(cl, ct + 92),
          color: const Color(0xFF55CC55), fontSize: 12);
      _actionBtnRect = Rect.zero;
    } else {
      final canAfford = gold >= repairCost;
      _actionBtnRect = _drawBtn(
          renderer, 'REPAIR  (${repairCost}g)', Offset(cl, ct + 88), 190, 30, enabled: canAfford);
      if (!canAfford) {
        renderer.drawText('Insufficient gold.', Vector2(cl + 202, ct + 96),
            color: const Color(0xFFAA4444), fontSize: 11);
      }
    }

    // --- Separator ---
    const sepY = 130.0;
    renderer.canvas.drawLine(Offset(cl, ct + sepY), Offset(cl + cw, ct + sepY),
        Paint()..color = const Color(0xFF335577)..strokeWidth = 1);

    // --- Fuel depot ---
    final fuel    = ship.fuel;
    final maxFuel = ship.maxFuel;
    final refuelCost = _repairShop.calculateRefuelCost(ship);
    final effPct  = ((1.0 - ship.fuelEfficiencyMultiplier) * 100).round();

    renderer.drawText('FUEL DEPOT', Vector2(cl, ct + sepY + 10),
        color: const Color(0xFF88CCFF), fontSize: 14);
    renderer.drawText(
        'Fuel:  ${fuel.toStringAsFixed(0)} / ${maxFuel.toStringAsFixed(0)}  '
        '${effPct > 0 ? "  ($effPct% efficient)" : ""}',
        Vector2(cl, ct + sepY + 36), fontSize: 13);

    final fuelRatio = (fuel / maxFuel).clamp(0.0, 1.0);
    renderer.canvas.drawRect(Rect.fromLTWH(cl, ct + sepY + 58, barW, 12),
        Paint()..color = const Color(0xFF1A2A3A));
    renderer.canvas.drawRect(Rect.fromLTWH(cl, ct + sepY + 58, barW * fuelRatio, 12),
        Paint()..color = const Color(0xFFFF9900));
    renderer.canvas.drawRect(Rect.fromLTWH(cl, ct + sepY + 58, barW, 12),
        Paint()..color = const Color(0xFF335577)..style = PaintingStyle.stroke..strokeWidth = 1);

    renderer.drawText('Refuel cost:  ${refuelCost}g   •   Gold:  ${gold}g',
        Vector2(cl, ct + sepY + 78), fontSize: 12);

    if (refuelCost <= 0) {
      renderer.drawText('Tank is full.', Vector2(cl, ct + sepY + 98),
          color: const Color(0xFF55CC55), fontSize: 12);
      _refuelBtnRect = Rect.zero;
    } else {
      final canAfford = gold >= refuelCost;
      _refuelBtnRect = _drawBtn(
          renderer, 'REFUEL  (${refuelCost}g)', Offset(cl, ct + sepY + 96), 190, 30, enabled: canAfford);
      if (!canAfford) {
        renderer.drawText('Insufficient gold.', Vector2(cl + 202, ct + sepY + 104),
            color: const Color(0xFFAA4444), fontSize: 11);
      }
    }
  }

  void _renderUpgrades(
      Renderer renderer, double cl, double ct, double cw, Ship ship, PlayerEconomy economy) {
    renderer.drawText('UPGRADE BAY', Vector2(cl, ct),
        color: const Color(0xFF88CCFF), fontSize: 14);

    final upgrades = _upgradeShop.availableUpgrades;
    for (int i = 0; i < upgrades.length && i < 9; i++) {
      final u    = upgrades[i];
      final rowY = ct + 30 + i * 34.0;

      renderer.drawText(_upgradeName(u.type), Vector2(cl, rowY + 2), fontSize: 12);

      // Level pips
      for (int lv = 0; lv < u.maxLevel; lv++) {
        final filled = lv < u.level;
        final pipX   = cl + 138 + lv * 17.0;
        renderer.canvas.drawRect(Rect.fromLTWH(pipX, rowY + 3, 13, 12),
            Paint()..color = filled ? const Color(0xFF4499CC) : const Color(0xFF1A2A3A));
        renderer.canvas.drawRect(Rect.fromLTWH(pipX, rowY + 3, 13, 12),
            Paint()..color = const Color(0xFF335577)..style = PaintingStyle.stroke..strokeWidth = 1);
      }

      renderer.drawText('Lv${u.level}', Vector2(cl + 232, rowY + 2),
          color: const Color(0xFF88AACC), fontSize: 11);

      if (u.isMaxed) {
        renderer.drawText('MAX', Vector2(cl + cw - 90, rowY + 2),
            color: const Color(0xFF55CC55), fontSize: 11);
        _upgradeRects[i] = Rect.zero;
      } else {
        final cost      = u.getCost();
        final canAfford = economy.gold >= cost;
        renderer.drawText('${cost}g', Vector2(cl + cw - 134, rowY + 2),
            color: canAfford ? const Color(0xFFFFDD66) : const Color(0xFF775533), fontSize: 11);
        _upgradeRects[i] = _drawBtn(
            renderer, 'BUY', Offset(cl + cw - 52, rowY - 1), 48, 26, enabled: canAfford);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Warp footer – drawn at bottom of panel regardless of active tab
  // ---------------------------------------------------------------------------

  void _renderWarpFooter(Renderer renderer, double px, double py, double pw) {
    const footerY = 446.0; // distance from panel top where footer begins
    final fy = py + footerY;
    final cl = px + 16;

    // Separator
    renderer.canvas.drawLine(
      Offset(px + 8, fy),
      Offset(px + pw - 8, fy),
      Paint()..color = const Color(0xFF335577)..strokeWidth = 1,
    );

    // Label
    renderer.drawText('WARP DRIVE', Vector2(cl, fy + 12),
        color: const Color(0xFF88CCFF), fontSize: 13);

    final remaining = _warpCooldownRemaining;
    if (remaining > Duration.zero) {
      // Show cooldown countdown
      final mins = remaining.inMinutes;
      final secs = remaining.inSeconds % 60;
      final pad  = secs.toString().padLeft(2, '0');
      renderer.drawText('Cooldown: ${mins}m ${pad}s', Vector2(cl + 118, fy + 12),
          color: const Color(0xFF775533), fontSize: 12);
      _warpBtnRect = Rect.zero;
    } else {
      // Show active button
      _warpBtnRect = _drawBtn(
        renderer,
        'WARP TO NEW SYSTEM',
        Offset(cl + 118, fy + 8),
        196, 28,
        enabled: true,
        color: const Color(0xFF1A3A1A),
        borderColor: const Color(0xFF44AA44),
        textColor: const Color(0xFFAAFFAA),
      );
    }

    renderer.drawText(
      'Resets the asteroid field.  Once per 30 min.',
      Vector2(cl, fy + 36),
      color: const Color(0xFF446655),
      fontSize: 11,
    );
  }

  // ---------------------------------------------------------------------------
  // Drawing primitives
  // ---------------------------------------------------------------------------

  Color _hpBarColor(double ratio) {
    if (ratio > 0.6) return const Color(0xFF44CC44);
    if (ratio > 0.3) return const Color(0xFFCCAA22);
    return const Color(0xFFCC3333);
  }

  String _upgradeName(UpgradeType type) => switch (type) {
    UpgradeType.firepower      => 'Firepower',
    UpgradeType.fireRate       => 'Fire Rate',
    UpgradeType.bulletSize     => 'Bullet Size',
    UpgradeType.homing         => 'Homing',
    UpgradeType.fuelEfficiency => 'Fuel Efficiency',
    UpgradeType.cargoCapacity  => 'Cargo Capacity',
    UpgradeType.hullStrength   => 'Hull Strength',
    UpgradeType.shieldStrength => 'Shield Strength',
    UpgradeType.shieldRegen    => 'Shield Regen',
  };

  /// Draws a labelled button and returns its [Rect] for hit-testing.
  Rect _drawBtn(
    Renderer renderer,
    String label,
    Offset topLeft,
    double btnW,
    double btnH, {
    bool enabled = true,
    Color? color,
    Color? borderColor,
    Color? textColor,
  }) {
    final rect = Rect.fromLTWH(topLeft.dx, topLeft.dy, btnW, btnH);
    renderer.canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = color ?? (enabled ? const Color(0xFF12304A) : const Color(0xFF0A1A28)));
    renderer.canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()
          ..color = borderColor ?? (enabled ? const Color(0xFF4488CC) : const Color(0xFF2A3A4A))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    renderer.drawText(label,
        Vector2(topLeft.dx + 8, topLeft.dy + (btnH - 14) / 2),
        color: textColor ?? (enabled ? const Color(0xFFCCEEFF) : const Color(0xFF446677)),
        fontSize: 12);
    return rect;
  }

  /// Draws a tab and returns its [Rect] for hit-testing.
  Rect _drawTab(
    Renderer renderer,
    String label,
    Offset topLeft,
    double tabW,
    double tabH,
    bool active,
  ) {
    final rect = Rect.fromLTWH(topLeft.dx, topLeft.dy, tabW, tabH);
    renderer.canvas.drawRect(rect,
        Paint()..color = active ? const Color(0xFF0F2030) : const Color(0xFF060E18));
    // Right separator
    renderer.canvas.drawLine(
        Offset(topLeft.dx + tabW, topLeft.dy), Offset(topLeft.dx + tabW, topLeft.dy + tabH),
        Paint()..color = const Color(0xFF223344)..strokeWidth = 1);
    // Active indicator line on top
    if (active) {
      renderer.canvas.drawLine(
          Offset(topLeft.dx + 2, topLeft.dy + 1), Offset(topLeft.dx + tabW - 2, topLeft.dy + 1),
          Paint()..color = const Color(0xFF4488CC)..strokeWidth = 2);
    }
    final textX = topLeft.dx + (tabW - label.length * 7.2) / 2;
    final textY = topLeft.dy + (tabH - 14) / 2;
    renderer.drawText(label, Vector2(textX, textY),
        color: active ? const Color(0xFFCCEEFF) : const Color(0xFF668899), fontSize: 13);
    return rect;
  }
}
