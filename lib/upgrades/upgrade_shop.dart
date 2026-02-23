import '../economy/player_economy.dart';
import '../entities/ship.dart';
import 'upgrade.dart';
import 'upgrade_type.dart';

class UpgradeShop {
  final List<Upgrade> availableUpgrades;

  UpgradeShop() : availableUpgrades = _defaultUpgrades();

  static List<Upgrade> _defaultUpgrades() => [
        Upgrade(type: UpgradeType.firepower, baseCost: 100),
        Upgrade(type: UpgradeType.fireRate, baseCost: 80),
        Upgrade(type: UpgradeType.bulletSize, baseCost: 60),
        Upgrade(type: UpgradeType.homing, baseCost: 150),
        Upgrade(type: UpgradeType.fuelEfficiency, baseCost: 70),
        Upgrade(type: UpgradeType.cargoCapacity, baseCost: 50),
        Upgrade(type: UpgradeType.hullStrength, baseCost: 120),
        Upgrade(type: UpgradeType.shieldStrength, baseCost: 130),
        Upgrade(type: UpgradeType.shieldRegen, baseCost: 110),
      ];

  Upgrade? getUpgrade(UpgradeType type) {
    try {
      return availableUpgrades.firstWhere((u) => u.type == type);
    } catch (_) {
      return null;
    }
  }

  bool purchaseUpgrade(UpgradeType type, PlayerEconomy economy, Ship ship) {
    final upgrade = getUpgrade(type);
    if (upgrade == null || upgrade.isMaxed) return false;

    final cost = upgrade.getCost();
    if (!economy.spendGold(cost)) return false;

    upgrade.apply(ship);
    return true;
  }
}
