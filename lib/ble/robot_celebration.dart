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

  Future<void>? _activeCelebration;

  Future<void> celebrate() {
    final active = _activeCelebration;
    if (active != null) return active;

    late final Future<void> operation;
    operation = _runCelebration().whenComplete(() {
      if (identical(_activeCelebration, operation)) {
        _activeCelebration = null;
      }
    });
    _activeCelebration = operation;
    return operation;
  }

  Future<void> _runCelebration() async {
    final mobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (kIsWeb || !mobilePlatform) return;

    final ble = RobotBleService.I;
    final connected = ble.isConnected || await ble.ensureConnected();
    if (!connected) return;

    final previousEyesEnabled = ble.eyesEnabled;
    final previousEyeMode = BleConstants.eyeModes.contains(ble.eyeMode)
        ? ble.eyeMode
        : 'normal';
    final previousHeadEnabled = ble.headServoEnabled;
    final previousTailEnabled = ble.tailServoEnabled;
    final previousHeadAngle = ble.headAngle;
    final previousTailAngle = ble.tailAngle;

    try {
      await ble.setEyesEnabled(true);
      await ble.setServoEnabled('head', true);
      await ble.setServoEnabled('tail', true);
      await ble.setEyeMode('heart');

      await ble.setServoAngle('head', BleConstants.headMinAngle);
      await ble.wagTail();
      await Future<void>.delayed(const Duration(milliseconds: 650));

      if (!ble.isConnected) return;
      await ble.setServoAngle('head', BleConstants.headMaxAngle);
      await Future<void>.delayed(const Duration(milliseconds: 900));

      if (!ble.isConnected) return;
      await ble.setServoAngle('head', BleConstants.headMinAngle);
      await Future<void>.delayed(const Duration(milliseconds: 900));

      if (!ble.isConnected) return;
      await ble.setServoAngle('head', BleConstants.headCenterAngle);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
    } catch (error, stackTrace) {
      debugPrint('ROBOT CELEBRATION ERROR: $error\n$stackTrace');
    } finally {
      if (ble.isConnected) {
        await _restoreRobot(
          ble,
          eyesEnabled: previousEyesEnabled,
          eyeMode: previousEyeMode,
          headEnabled: previousHeadEnabled,
          tailEnabled: previousTailEnabled,
          headAngle: previousHeadAngle,
          tailAngle: previousTailAngle,
        );
      }
    }
  }

  Future<void> _restoreRobot(
    RobotBleService ble, {
    required bool eyesEnabled,
    required String eyeMode,
    required bool headEnabled,
    required bool tailEnabled,
    required int headAngle,
    required int tailAngle,
  }) async {
    await _ignoreFailure(() => ble.setServoAngle('head', headAngle));
    await _ignoreFailure(() => ble.setServoAngle('tail', tailAngle));
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await _ignoreFailure(() => ble.setEyeMode(eyeMode));
    if (!eyesEnabled) {
      await _ignoreFailure(() => ble.setEyesEnabled(false));
    }
    if (!headEnabled) {
      await _ignoreFailure(() => ble.setServoEnabled('head', false));
    }
    if (!tailEnabled) {
      await _ignoreFailure(() => ble.setServoEnabled('tail', false));
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
