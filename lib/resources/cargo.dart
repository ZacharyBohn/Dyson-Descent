import 'mineral_type.dart';

class Cargo {
  int commonCount;
  int rareCount;
  int capacity;

  Cargo({this.capacity = 50})
      : commonCount = 0,
        rareCount = 0;

  int get totalCount => commonCount + rareCount;

  bool canStore(int amount) => totalCount + amount <= capacity;

  void add(MineralType type, int amount) {
    if (!canStore(amount)) return;
    switch (type) {
      case MineralType.common:
        commonCount += amount;
      case MineralType.rare:
        rareCount += amount;
    }
  }

  void remove(MineralType type, int amount) {
    switch (type) {
      case MineralType.common:
        commonCount = (commonCount - amount).clamp(0, capacity);
      case MineralType.rare:
        rareCount = (rareCount - amount).clamp(0, capacity);
    }
  }
}
