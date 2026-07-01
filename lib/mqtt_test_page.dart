import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttSimplePage extends StatefulWidget {
  const MqttSimplePage({super.key});

  @override
  State<MqttSimplePage> createState() => _MqttSimplePageState();
}

class _MqttSimplePageState extends State<MqttSimplePage> {
  final String broker = 'broker.hivemq.com';
  final String topicData = 'mindmeow/esp32/data';
  final String topicCmd  = 'mindmeow/esp32/cmd';

  MqttServerClient? client;
  String status = "Idle";
  int latestValue = 0;

  Future<void> connect() async {
    client = MqttServerClient(broker, 'flutter_${DateTime.now().millisecondsSinceEpoch}');
    client!.keepAlivePeriod = 20;

    try {
      await client!.connect();
      client!.subscribe(topicData, MqttQos.atMostOnce);

      client!.updates!.listen((events) {
        final msg = events.first.payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(msg.payload.message);

        setState(() => latestValue = int.tryParse(payload) ?? 0);
      });

      setState(() => status = "Connected");
    } catch (e) {
      setState(() => status = "Error: $e");
    }
  }

  void sendCmd(String cmd) {
    if (client == null) return;
    final builder = MqttClientPayloadBuilder()..addString(cmd);
    client!.publishMessage(topicCmd, MqttQos.atMostOnce, builder.payload!);
  }

  @override
  void dispose() {
    client?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MQTT Simple Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Status: $status"),
            const SizedBox(height: 20),

            Text(
              "Value from ESP32:",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              "$latestValue",
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: connect,
              child: const Text("Connect MQTT"),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => sendCmd("LED_ON"),
                  child: const Text("LED ON"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => sendCmd("LED_OFF"),
                  child: const Text("LED OFF"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
