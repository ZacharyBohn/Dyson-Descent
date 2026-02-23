import '../entities/ship.dart';
import 'player_economy.dart';

class RepairShop {
  static const double _costPerHp   = 2;
  // 1 gold per 10 fuel units; full 1000-unit tank = 100g
  static const double _costPerFuel = 0.1;

  int calculateRepairCost(Ship ship) {
    final missingHp = ship.maxHealth - ship.health;
    return (missingHp * _costPerHp).ceil();
  }

  void repairShip(Ship ship, PlayerEconomy economy) {
    final cost = calculateRepairCost(ship);
    if (cost <= 0) return;
    if (economy.spendGold(cost)) {
      ship.health = ship.maxHealth;
    }
  }

  int calculateRefuelCost(Ship ship) {
    final missingFuel = ship.maxFuel - ship.fuel;
    return (missingFuel * _costPerFuel).ceil();
  }

  void refuelShip(Ship ship, PlayerEconomy economy) {
    final cost = calculateRefuelCost(ship);
    if (cost <= 0) return;
    if (economy.spendGold(cost)) {
      ship.fuel = ship.maxFuel;
    }
  }
}
