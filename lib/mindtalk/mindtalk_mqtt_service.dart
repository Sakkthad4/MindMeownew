import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  MqttService._();
  static final MqttService I = MqttService._();

  final String broker = 'broker.hivemq.com';
  final String cmdTopic = 'mindmeow/esp32/cmd';

  late MqttServerClient _client;
  bool _connected = false;

  Future<void> connect() async {
    _client = MqttServerClient(
      broker,
      'flutter_${DateTime.now().millisecondsSinceEpoch}',
    );
    _client.keepAlivePeriod = 20;

    await _client.connect();
    _connected = true;
  }

  void send(Map<String, dynamic> data) {
    if (!_connected) return;

    final builder = MqttClientPayloadBuilder()
      ..addString(jsonEncode(data));

    _client.publishMessage(
      cmdTopic,
      MqttQos.atMostOnce,
      builder.payload!,
    );
  }
}
