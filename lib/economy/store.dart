import '../resources/cargo.dart';
import '../resources/mineral_type.dart';
import 'player_economy.dart';

class Store {
  static const int _commonValue = 5;
  static const int _rareValue = 25;

  int getSellValue(MineralType type, int quantity) {
    return switch (type) {
      MineralType.common => _commonValue * quantity,
      MineralType.rare => _rareValue * quantity,
    };
  }

  void sellMinerals(PlayerEconomy economy, Cargo cargo) {
    final commonGold = getSellValue(MineralType.common, cargo.commonCount);
    final rareGold = getSellValue(MineralType.rare, cargo.rareCount);

    economy.addGold(commonGold + rareGold);

    cargo.remove(MineralType.common, cargo.commonCount);
    cargo.remove(MineralType.rare, cargo.rareCount);
  }
}
