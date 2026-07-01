import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  static final MqttService I = MqttService._();
  MqttService._();

  late MqttServerClient _client;

  Future<void> connect({
    required void Function(Map<String, dynamic> data) onEvent,
  }) async {
    _client = MqttServerClient(
      'broker.hivemq.com',
      'flutter_${DateTime.now().millisecondsSinceEpoch}',
    );

    _client.keepAlivePeriod = 20;
    _client.logging(on: false);

    await _client.connect();

    _client.subscribe('mindmeow/esp32/event', MqttQos.atMostOnce);

    _client.updates!.listen((events) {
      final msg = events.first.payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(msg.payload.message);

      onEvent(jsonDecode(payload));
    });
  }

  void send(Map<String, dynamic> data) {
    final builder = MqttClientPayloadBuilder()
      ..addString(jsonEncode(data));

    _client.publishMessage(
      'mindmeow/esp32/cmd',
      MqttQos.atMostOnce,
      builder.payload!,
    );
  }
}
