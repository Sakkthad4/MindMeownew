import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttTouchData {
  final int? value;      // topic .../touch/value
  final bool? touched;   // topic .../touch/state
  const MqttTouchData({this.value, this.touched});

  MqttTouchData copyWith({int? value, bool? touched}) =>
      MqttTouchData(
        value: value ?? this.value,
        touched: touched ?? this.touched,
      );
}

class MqttTouchService {
  final String brokerHost;
  final int port;
  final String clientId;

  final String topicValue;
  final String topicState;

  late final MqttServerClient _client;

  final _controller = StreamController<MqttTouchData>.broadcast();
  Stream<MqttTouchData> get stream => _controller.stream;

  MqttTouchData _latest = const MqttTouchData();

  MqttTouchService({
    required this.brokerHost,
    this.port = 1883,
    required this.clientId,
    required this.topicValue,
    required this.topicState,
  }) {
    _client = MqttServerClient(brokerHost, clientId);
    _client.port = port;
    _client.keepAlivePeriod = 20;
    _client.autoReconnect = true;
    _client.resubscribeOnAutoReconnect = true;
    _client.logging(on: false);
  }

  Future<void> connect() async {
    _client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    try {
      await _client.connect();
    } catch (e) {
      _client.disconnect();
      rethrow;
    }

    if (_client.connectionStatus?.state != MqttConnectionState.connected) {
      _client.disconnect();
      throw StateError('MQTT connection failed: ${_client.connectionStatus}');
    }

    _client.subscribe(topicValue, MqttQos.atLeastOnce);
    _client.subscribe(topicState, MqttQos.atLeastOnce);

    _client.updates?.listen((events) {
      for (final event in events) {
        final rec = event.payload as MqttPublishMessage;
        final topic = event.topic;
        final payloadBytes = rec.payload.message;
        final msg = MqttPublishPayload.bytesToStringAsString(payloadBytes).trim();

        _handleMessage(topic, msg);
      }
    });
  }

  void _handleMessage(String topic, String msg) {
    if (topic == topicValue) {
      final v = int.tryParse(msg);
      if (v != null) {
        _latest = _latest.copyWith(value: v);
        _controller.add(_latest);
      }
      return;
    }

    if (topic == topicState) {
      final touched = msg == '1' || msg.toLowerCase() == 'true';
      _latest = _latest.copyWith(touched: touched);
      _controller.add(_latest);
      return;
    }
  }

  void dispose() {
    _controller.close();
    _client.disconnect();
  }
}
