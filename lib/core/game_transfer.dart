/// Lightweight static bag for passing data between scene transitions.
///
/// The departing scene writes the fields it wants to hand off;
/// the arriving scene reads and clears them in onEnter().
class GameTransfer {
  /// ID of the warp gate / dungeon being entered.
  static String? dungeonId;

  static void clear() {
    dungeonId = null;
  }
}
