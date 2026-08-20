import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'ble_constants.dart';
import 'robot_ble_service.dart';

/// Runs the same encouraging robot movement once when a result page opens.
class RobotCelebration extends StatefulWidget {
  const RobotCelebration({super.key, required this.child});

  final Widget child;

  @override
  State<RobotCelebration> createState() => _RobotCelebrationState();
}

class _RobotCelebrationState extends State<RobotCelebration> {
  @override
  void initState() {
    super.initState();
    unawaited(RobotCelebrationController.instance.celebrate());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class RobotCelebrationController {
  RobotCelebrationController._();

  static final RobotCelebrationController instance =
      RobotCelebrationController._();

  Future<void> _motionQueue = Future<void>.value();

  Future<void> celebrate() =>
      _enqueue(() => _runMotion(rounds: 2, celebrateWithHeartEyes: true));

  Future<void> greetFeature() =>
      _enqueue(() => _runMotion(rounds: 1, celebrateWithHeartEyes: false));

  Future<void> _enqueue(Future<void> Function() action) {
    final operation = _motionQueue.then((_) => action());
    _motionQueue = operation.catchError((Object error, StackTrace stackTrace) {
      debugPrint('ROBOT MOTION QUEUE ERROR: $error\n$stackTrace');
    });
    return operation;
  }

  @visibleForTesting
  static List<({int head, int tail})> servoTargetsForRounds(int rounds) {
    assert(rounds > 0);
    return <({int head, int tail})>[
      for (var round = 0; round < rounds; round++) ...[
        (head: BleConstants.headMinAngle, tail: BleConstants.tailMinAngle),
        (head: BleConstants.headMaxAngle, tail: BleConstants.tailMaxAngle),
      ],
      (head: BleConstants.headCenterAngle, tail: BleConstants.tailCenterAngle),
    ];
  }

  Future<void> _runMotion({
    required int rounds,
    required bool celebrateWithHeartEyes,
  }) async {
    final mobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (kIsWeb || !mobilePlatform) return;

    final ble = RobotBleService.I;
    final connected = ble.isConnected || await ble.ensureConnected();
    if (!connected) return;

    try {
      await ble.setServoEnabled('head', true);
      await ble.setServoEnabled('tail', true);
      if (celebrateWithHeartEyes) {
        await ble.setEyesEnabled(true);
        await ble.setEyeMode('heart');
      }

      final targets = servoTargetsForRounds(rounds);
      for (var index = 0; index < targets.length; index++) {
        if (!ble.isConnected) return;
        final target = targets[index];
        await ble.setServoAngle('head', target.head);
        await ble.setServoAngle('tail', target.tail);
        await Future<void>.delayed(
          index == targets.length - 1
              ? const Duration(milliseconds: 700)
              : const Duration(milliseconds: 650),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('ROBOT MOTION ERROR: $error\n$stackTrace');
    } finally {
      if (ble.isConnected) {
        // An explicit angle command also cancels a tail wag that may still be
        // active in the firmware. Keep both servos attached at their safe home.
        await _ignoreFailure(
          () => ble.setServoAngle('head', BleConstants.headCenterAngle),
        );
        await _ignoreFailure(
          () => ble.setServoAngle('tail', BleConstants.tailCenterAngle),
        );
        if (celebrateWithHeartEyes) {
          await _ignoreFailure(() => ble.setEyesEnabled(true));
          await _ignoreFailure(() => ble.setEyeMode('normal'));
        }
      }
    }
  }

  Future<void> _ignoreFailure(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // A disconnect during cleanup must not affect the result page.
    }
  }
}
