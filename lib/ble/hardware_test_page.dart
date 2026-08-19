import 'package:flutter/material.dart';

import 'ble_constants.dart';
import 'robot_ble_service.dart';
import 'robot_ble_state.dart';

class HardwareTestPage extends StatefulWidget {
  const HardwareTestPage({super.key});

  @override
  State<HardwareTestPage> createState() => _HardwareTestPageState();
}

class _HardwareTestPageState extends State<HardwareTestPage> {
  final RobotBleService ble = RobotBleService.I;

  @override
  void initState() {
    super.initState();
    ble.initialize();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hardware Test'),
        actions: [
          IconButton(
            tooltip: 'อ่านสถานะล่าสุด',
            onPressed: ble.isConnected ? () => _run(ble.requestStatus) : null,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: AnimatedBuilder(
        animation: ble,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _ConnectionCard(ble: ble, run: _run),
              const SizedBox(height: 16),
              _TouchCard(ble: ble, run: _run),
              const SizedBox(height: 16),
              _ServoCard(
                title: 'เซอร์โวหัว MG996R',
                icon: Icons.pets,
                connected: ble.isConnected,
                enabled: ble.headServoEnabled,
                angle: ble.headAngle,
                minAngle: BleConstants.headMinAngle,
                centerAngle: BleConstants.headCenterAngle,
                maxAngle: BleConstants.headMaxAngle,
                onEnabled: (value) =>
                    _run(() => ble.setServoEnabled('head', value)),
                onAngle: (angle) =>
                    _run(() => ble.setServoAngle('head', angle)),
              ),
              const SizedBox(height: 16),
              _ServoCard(
                title: 'เซอร์โวหาง MG90S',
                icon: Icons.waves,
                connected: ble.isConnected,
                enabled: ble.tailServoEnabled,
                angle: ble.tailAngle,
                minAngle: BleConstants.tailMinAngle,
                centerAngle: BleConstants.tailCenterAngle,
                maxAngle: BleConstants.tailMaxAngle,
                onEnabled: (value) =>
                    _run(() => ble.setServoEnabled('tail', value)),
                onAngle: (angle) =>
                    _run(() => ble.setServoAngle('tail', angle)),
                onExtraTest: () => _run(ble.wagTail),
              ),
              const SizedBox(height: 16),
              _EyesCard(ble: ble, run: _run),
              const SizedBox(height: 16),
              _LogCard(ble: ble),
            ],
          );
        },
      ),
    );
  }
}

typedef _RunAction = Future<void> Function(Future<void> Function());

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.ble, required this.run});

  final RobotBleService ble;
  final _RunAction run;

  @override
  Widget build(BuildContext context) {
    final connected = ble.isConnected;
    final busy =
        ble.status == RobotBleStatus.connecting ||
        ble.status == RobotBleStatus.disconnecting;
    final color = connected ? Colors.green : Colors.orange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bluetooth, color: color, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ble.status.label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        connected
                            ? ble.connectedDeviceName
                            : 'เป้าหมาย: ${BleConstants.deviceName}',
                      ),
                    ],
                  ),
                ),
                if (connected)
                  FilledButton.tonalIcon(
                    onPressed: busy ? null : () => run(ble.disconnect),
                    icon: const Icon(Icons.link_off),
                    label: const Text('Disconnect'),
                  )
                else
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : ble.status == RobotBleStatus.scanning
                        ? () => run(ble.stopScan)
                        : () => run(ble.startScan),
                    icon: Icon(
                      ble.status == RobotBleStatus.scanning
                          ? Icons.stop
                          : Icons.search,
                    ),
                    label: Text(
                      ble.status == RobotBleStatus.scanning
                          ? 'หยุดค้นหา'
                          : 'Scan',
                    ),
                  ),
              ],
            ),
            if (ble.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                ble.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  avatar: Icon(
                    ble.protocolReady ? Icons.check_circle : Icons.sync,
                    color: ble.protocolReady ? Colors.green : Colors.grey,
                  ),
                  label: Text(
                    ble.protocolReady
                        ? 'Protocol พร้อมใช้งาน'
                        : 'ยังไม่ได้รับ pong',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: connected ? () => run(ble.ping) : null,
                  icon: const Icon(Icons.network_ping),
                  label: const Text('Test ping'),
                ),
              ],
            ),
            if (!connected && ble.scanResults.isNotEmpty) ...[
              const Divider(height: 30),
              ...ble.scanResults.map(
                (result) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.pets)),
                  title: Text(
                    result.advertisementData.advName.isEmpty
                        ? result.device.platformName
                        : result.advertisementData.advName,
                  ),
                  subtitle: Text('RSSI ${result.rssi} dBm'),
                  trailing: FilledButton(
                    onPressed: busy
                        ? null
                        : () => run(() => ble.connect(result)),
                    child: const Text('Connect'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TouchCard extends StatelessWidget {
  const _TouchCard({required this.ble, required this.run});

  final RobotBleService ble;
  final _RunAction run;

  @override
  Widget build(BuildContext context) {
    final active = ble.isConnected && ble.touchEnabled && ble.touched;
    return Card(
      color: active ? Colors.green.shade50 : null,
      child: SwitchListTile(
        secondary: Icon(
          Icons.touch_app,
          size: 38,
          color: active ? Colors.green : Colors.grey,
        ),
        title: const Text('Touch sensor ลูบหัว'),
        subtitle: Text(
          '${ble.touched ? "กำลังแตะ" : "ไม่ได้แตะ"}'
          '  •  Raw: ${ble.touchRaw ?? "-"}',
        ),
        value: ble.touchEnabled,
        onChanged: ble.isConnected
            ? (value) => run(() => ble.setTouchEnabled(value))
            : null,
      ),
    );
  }
}

class _ServoCard extends StatelessWidget {
  const _ServoCard({
    required this.title,
    required this.icon,
    required this.connected,
    required this.enabled,
    required this.angle,
    required this.minAngle,
    required this.centerAngle,
    required this.maxAngle,
    required this.onEnabled,
    required this.onAngle,
    this.onExtraTest,
  });

  final String title;
  final IconData icon;
  final bool connected;
  final bool enabled;
  final int angle;
  final int minAngle;
  final int centerAngle;
  final int maxAngle;
  final ValueChanged<bool> onEnabled;
  final ValueChanged<int> onAngle;
  final VoidCallback? onExtraTest;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Text('Enable'),
                Switch(value: enabled, onChanged: connected ? onEnabled : null),
              ],
            ),
            Text('ตำแหน่งล่าสุด: $angle°'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final value in [minAngle, centerAngle, maxAngle])
                  OutlinedButton(
                    onPressed: connected && enabled
                        ? () => onAngle(value)
                        : null,
                    child: Text(
                      value == centerAngle ? 'กลาง $value°' : '$value°',
                    ),
                  ),
                if (onExtraTest != null)
                  FilledButton.tonalIcon(
                    onPressed: connected && enabled ? onExtraTest : null,
                    icon: const Icon(Icons.multiple_stop),
                    label: const Text('Wag'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EyesCard extends StatelessWidget {
  const _EyesCard({required this.ble, required this.run});

  final RobotBleService ble;
  final _RunAction run;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.visibility, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'จอ TFT ดวงตา 2 จอ',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Text('Enable'),
                Switch(
                  value: ble.eyesEnabled,
                  onChanged: ble.isConnected
                      ? (value) => run(() => ble.setEyesEnabled(value))
                      : null,
                ),
              ],
            ),
            Text('โหมดล่าสุด: ${ble.eyeMode}'),
            if (ble.isConnected && !ble.eyesAvailable)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Firmware แจ้งว่าจอดวงตายังไม่พร้อม',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final mode in BleConstants.eyeModes)
                  OutlinedButton(
                    onPressed: ble.isConnected && ble.eyesEnabled
                        ? () => run(() => ble.setEyeMode(mode))
                        : null,
                    child: Text(mode),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.ble});

  final RobotBleService ble;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BLE Data', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            SelectableText('ส่งล่าสุด: ${ble.lastSent}'),
            const SizedBox(height: 6),
            SelectableText('รับล่าสุด: ${ble.lastReceived}'),
          ],
        ),
      ),
    );
  }
}
