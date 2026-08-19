class BleConstants {
  const BleConstants._();

  static const deviceName = 'MINDMEOW_CAT';
  static const serviceUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const commandUuid = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E';
  static const eventUuid = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E';
  static const protocolVersion = 1;

  // Firmware protocol v1 rejects commands larger than 120 UTF-8 bytes.
  static const maxPayloadBytes = 120;

  static const headMinAngle = 60;
  static const headCenterAngle = 90;
  static const headMaxAngle = 120;
  static const tailMinAngle = 50;
  static const tailCenterAngle = 90;
  static const tailMaxAngle = 130;

  static const eyeModes = <String>[
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
  ];
}
