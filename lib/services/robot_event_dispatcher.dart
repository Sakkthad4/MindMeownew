import '../audio/soundeffect.dart';
import '../healthcare/data/cat_bond_store.dart';
import '../providers/cat_state.dart';

class RobotEventDispatcher {
  RobotEventDispatcher(this.cat, {CatBondStore? bondStore})
    : _bondStore = bondStore ?? CatBondStore();

  final CatState cat;
  final CatBondStore _bondStore;
  bool _lastTouched = false;

  Future<void> handle(Map<String, dynamic> data) async {
    if (data['type'] != 'touch') return;

    final touched = data['touched'] == true;
    final isRisingEdge = !_lastTouched && touched;
    // Update the edge state before awaiting storage/audio so periodic BLE
    // notifications cannot award XP more than once for the same touch.
    _lastTouched = touched;

    if (isRisingEdge && cat.gameActive) {
      const xp = 10;
      cat.addXP(xp);
      await _bondStore.addXp(amount: xp, source: 'ble_touch');
      try {
        await SoundFx.tapFx();
      } catch (_) {
        // A missing/unavailable audio output must not stop touch collection.
      }
    }
  }
}
