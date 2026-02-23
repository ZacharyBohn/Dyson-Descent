import '../entities/warp_gate.dart';
import '../math/vector2.dart';

class WarpGateManager {
  final List<WarpGate> gates;

  WarpGateManager() : gates = [];

  void spawnGate(Vector2 position, {required String dungeonId}) {
    final gate = WarpGate(
      id: 'gate_${DateTime.now().microsecondsSinceEpoch}',
      position: position,
      dungeonId: dungeonId,
    );
    gates.add(gate);
  }

  WarpGate? getActiveGate() {
    try {
      return gates.firstWhere((g) => g.isActive);
    } catch (_) {
      return null;
    }
  }

  WarpGate? gateAtPosition(Vector2 position, double touchRadius) {
    try {
      return gates.firstWhere(
        (g) => Vector2.distance(g.position, position) < touchRadius + g.radius,
      );
    } catch (_) {
      return null;
    }
  }
}
