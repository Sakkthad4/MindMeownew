import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test22/healthcare/data/cat_bond_store.dart';
import 'package:flutter_test22/providers/cat_state.dart';
import 'package:flutter_test22/services/robot_event_dispatcher.dart';

class _FakeCatBondStore extends CatBondStore {
  int totalXp = 0;

  @override
  Future<void> addXp({required int amount, required String source}) async {
    totalXp += amount;
  }
}

void main() {
  test('head petting remains active after a game has ended', () async {
    final cat = CatState()..endGame();
    final bondStore = _FakeCatBondStore();
    var soundCount = 0;
    final dispatcher = RobotEventDispatcher(
      cat,
      bondStore: bondStore,
      playTouchSound: () async {
        soundCount++;
      },
    );

    await dispatcher.handle(const {'type': 'touch', 'touched': true});
    await dispatcher.handle(const {'type': 'touch', 'touched': true});

    expect(cat.gameActive, isFalse);
    expect(cat.xp, 10);
    expect(bondStore.totalXp, 10);
    expect(soundCount, 1);

    await dispatcher.handle(const {'type': 'touch', 'touched': false});
    await dispatcher.handle(const {'type': 'touch', 'touched': true});

    expect(cat.xp, 20);
    expect(bondStore.totalXp, 20);
    expect(soundCount, 2);
  });
}
