import 'dart:convert';

import 'ble_constants.dart';

class BleProtocolException implements Exception {
  const BleProtocolException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BleProtocol {
  const BleProtocol._();

  static List<int> encode(Map<String, dynamic> message) {
    final bytes = utf8.encode(jsonEncode(message));
    if (bytes.length > BleConstants.maxPayloadBytes) {
      throw const BleProtocolException('ข้อความ BLE ยาวเกิน 120 bytes');
    }
    return bytes;
  }

  static Map<String, dynamic>? tryDecode(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  static bool isValidPong(Map<String, dynamic> message) {
    return message['type'] == 'pong' &&
        message['protocol'] == BleConstants.protocolVersion;
  }
}
