import '../economy/player_economy.dart';
import '../entities/ship.dart';

/// Lightweight static bag for passing data between scene transitions.
///
/// The departing scene writes the fields it wants to hand off;
/// the arriving scene reads and clears them in onEnter().
class GameTransfer {
  /// Player ship — carried across scene transitions.
  static Ship? ship;

  /// Player economy — carried alongside the ship.
  static PlayerEconomy? economy;

  static void clear() {
    ship    = null;
    economy = null;
  }
}
