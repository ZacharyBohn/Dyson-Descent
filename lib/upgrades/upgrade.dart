import '../entities/ship.dart';
import 'upgrade_type.dart';

class Upgrade {
  UpgradeType type;
  int level;
  int maxLevel;
  int baseCost;

  Upgrade({
    required this.type,
    this.level = 0,
    this.maxLevel = 5,
    required this.baseCost,
  });

  bool get isMaxed => level >= maxLevel;

  int getCost() => baseCost * (level + 1);

  void apply(Ship ship) {
    switch (type) {
      case UpgradeType.firepower:
        ship.weaponSystem.damageMultiplier += 0.25;
      case UpgradeType.fireRate:
        ship.weaponSystem.fireRate += 0.5;
      case UpgradeType.bulletSize:
        ship.weaponSystem.bulletSize += 2;
      case UpgradeType.homing:
        ship.weaponSystem.homingStrength += 0.2;
      case UpgradeType.fuelEfficiency:
        // Each level cuts fuel consumption by 10% (multiplicative via Ship.consumeFuel).
        ship.fuelEfficiencyMultiplier = (ship.fuelEfficiencyMultiplier - 0.10).clamp(0.10, 1.0);
      case UpgradeType.cargoCapacity:
        ship.cargo.capacity += 20;
      case UpgradeType.hullStrength:
        final bonus = 25.0;
        ship.maxHealth += bonus;
        ship.health += bonus;
      case UpgradeType.shieldStrength:
        ship.shield.maxShieldStrength += 25;
        ship.shield.shieldStrength += 25;
      case UpgradeType.shieldRegen:
        ship.shield.regenerationRate += 5;
    }
    level++;
  }
}
