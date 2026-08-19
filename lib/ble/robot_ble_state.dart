enum RobotBleStatus {
  idle,
  bluetoothOff,
  scanning,
  connecting,
  connected,
  disconnecting,
  error,
}

extension RobotBleStatusLabel on RobotBleStatus {
  String get label {
    switch (this) {
      case RobotBleStatus.idle:
        return 'ยังไม่ได้เชื่อมต่อ';
      case RobotBleStatus.bluetoothOff:
        return 'Bluetooth ปิดอยู่';
      case RobotBleStatus.scanning:
        return 'กำลังค้นหาหุ่นยนต์';
      case RobotBleStatus.connecting:
        return 'กำลังเชื่อมต่อ';
      case RobotBleStatus.connected:
        return 'เชื่อมต่อแล้ว';
      case RobotBleStatus.disconnecting:
        return 'กำลังตัดการเชื่อมต่อ';
      case RobotBleStatus.error:
        return 'เกิดข้อผิดพลาด';
    }
  }
}
