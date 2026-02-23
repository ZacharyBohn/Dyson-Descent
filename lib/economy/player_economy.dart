class PlayerEconomy {
  int gold;

  PlayerEconomy({this.gold = 0});

  void addGold(int amount) {
    gold += amount;
  }

  bool spendGold(int amount) {
    if (gold < amount) return false;
    gold -= amount;
    return true;
  }
}
