import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test22/ble/ble_constants.dart';
import 'package:flutter_test22/ble/ble_protocol.dart';
import 'package:flutter_test22/ble/robot_celebration.dart';
import 'package:flutter_test22/ble/robot_ble_service.dart';

void main() {
  group('MindMeow BLE protocol', () {
    test('encodes servo id as UTF-8 JSON', () {
      final bytes = BleProtocol.encode(const {
        'type': 'servo',
        'id': 'head',
        'angle': 90,
      });

      expect(jsonDecode(utf8.decode(bytes)), const {
        'type': 'servo',
        'id': 'head',
        'angle': 90,
      });
    });

    test('decodes valid event and rejects invalid JSON', () {
      final event = BleProtocol.tryDecode(
        utf8.encode('{"type":"touch","touched":true,"raw":12345}'),
      );

      expect(event?['type'], 'touch');
      expect(event?['touched'], isTrue);
      expect(BleProtocol.tryDecode(utf8.encode('not-json')), isNull);
    });

    test('validates protocol version in pong', () {
      expect(
        BleProtocol.isValidPong(const {
          'type': 'pong',
          'protocol': BleConstants.protocolVersion,
        }),
        isTrue,
      );
      expect(
        BleProtocol.isValidPong(const {'type': 'pong', 'protocol': 999}),
        isFalse,
      );
    });

    test('rejects payloads larger than the command limit', () {
      expect(
        () => BleProtocol.encode({
          'type': 'test',
          'data': 'x' * BleConstants.maxPayloadBytes,
        }),
        throwsA(isA<BleProtocolException>()),
      );
    });

    test('uses the firmware v1 payload limit and eye modes', () {
      expect(BleConstants.maxPayloadBytes, 120);
      expect(BleConstants.eyeModes, const [
        'normal',
        'animation',
        'happy',
        'sad',
        'angry',
        'heart',
        'wink',
        'red',
        'green',
        'blue',
      ]);
    });

    test('applies servo events using the firmware id field', () {
      final ble = RobotBleService.I;

      ble.applyEventForTest(const {
        'type': 'servo',
        'id': 'head',
        'enabled': true,
        'angle': 120,
      });
      ble.applyEventForTest(const {
        'type': 'servo',
        'id': 'tail',
        'enabled': true,
        'angle': 50,
      });

      expect(ble.headServoEnabled, isTrue);
      expect(ble.headAngle, 120);
      expect(ble.tailServoEnabled, isTrue);
      expect(ble.tailAngle, 50);
    });

    test('shows the firmware error code', () {
      final ble = RobotBleService.I;

      ble.applyEventForTest(const {'type': 'error', 'code': 'invalid_command'});

      expect(ble.errorMessage, contains('invalid_command'));
    });

    test('builds exactly one movement set for feature entry', () {
      expect(RobotCelebrationController.servoTargetsForRounds(1), const [
        (head: 60, tail: 50),
        (head: 120, tail: 130),
        (head: 90, tail: 90),
      ]);
    });

    test('builds exactly two movement sets for celebration', () {
      expect(RobotCelebrationController.servoTargetsForRounds(2), const [
        (head: 60, tail: 50),
        (head: 120, tail: 130),
        (head: 60, tail: 50),
        (head: 120, tail: 130),
        (head: 90, tail: 90),
      ]);
    });
  });
}
