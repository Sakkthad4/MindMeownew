import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_constants.dart';
import 'ble_protocol.dart';
import 'robot_ble_state.dart';

class RobotBleService extends ChangeNotifier {
  RobotBleService._();

  static final RobotBleService I = RobotBleService._();

  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _events.stream;

  RobotBleStatus status = RobotBleStatus.idle;
  BluetoothAdapterState adapterState = BluetoothAdapterState.unknown;
  List<ScanResult> scanResults = const [];
  String? errorMessage;
  String lastSent = '-';
  String lastReceived = '-';
  bool protocolReady = false;

  bool touchEnabled = true;
  bool touched = false;
  int? touchRaw;
  bool headServoEnabled = false;
  bool tailServoEnabled = false;
  int headAngle = BleConstants.headCenterAngle;
  int tailAngle = BleConstants.tailCenterAngle;
  bool eyesAvailable = false;
  bool eyesEnabled = true;
  String eyeMode = 'normal';

  BluetoothDevice? _device;
  BluetoothCharacteristic? _commandCharacteristic;
  BluetoothCharacteristic? _eventCharacteristic;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _eventSubscription;
  Future<void> _writeQueue = Future<void>.value();
  bool _initialized = false;

  bool get isConnected => status == RobotBleStatus.connected;
  BluetoothDevice? get connectedDevice => _device;
  String get connectedDeviceName {
    final name = _device?.platformName.trim();
    return name == null || name.isEmpty ? BleConstants.deviceName : name;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!await FlutterBluePlus.isSupported) {
      _setError('อุปกรณ์นี้ไม่รองรับ Bluetooth Low Energy');
      return;
    }

    adapterState = FlutterBluePlus.adapterStateNow;
    _adapterSubscription = FlutterBluePlus.adapterState.listen((state) {
      adapterState = state;
      if (state != BluetoothAdapterState.on && !isConnected) {
        status = RobotBleStatus.bluetoothOff;
      } else if (state == BluetoothAdapterState.on &&
          status == RobotBleStatus.bluetoothOff) {
        status = RobotBleStatus.idle;
      }
      notifyListeners();
    });

    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      scanResults = results.where(_isMindMeow).toList(growable: false);
      notifyListeners();
    }, onError: (Object error) => _setError('ค้นหา BLE ไม่สำเร็จ: $error'));
  }

  bool _isMindMeow(ScanResult result) {
    final advertisedName = result.advertisementData.advName.trim();
    final advertisesService = result.advertisementData.serviceUuids.any(
      (uuid) =>
          uuid.toString().toLowerCase() ==
          BleConstants.serviceUuid.toLowerCase(),
    );
    return advertisedName == BleConstants.deviceName ||
        result.device.platformName == BleConstants.deviceName ||
        advertisesService;
  }

  Future<void> startScan() async {
    await initialize();
    errorMessage = null;

    if (adapterState != BluetoothAdapterState.on) {
      status = RobotBleStatus.bluetoothOff;
      notifyListeners();
      return;
    }

    status = RobotBleStatus.scanning;
    scanResults = const [];
    notifyListeners();

    try {
      await FlutterBluePlus.stopScan();
      await FlutterBluePlus.startScan(
        withServices: [Guid(BleConstants.serviceUuid)],
        timeout: const Duration(seconds: 10),
      );
      await FlutterBluePlus.isScanning.where((value) => !value).first;
      if (status == RobotBleStatus.scanning) {
        status = RobotBleStatus.idle;
        notifyListeners();
      }
    } catch (error) {
      _setError('ค้นหาหุ่นยนต์ไม่สำเร็จ: $error');
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    if (status == RobotBleStatus.scanning) {
      status = RobotBleStatus.idle;
      notifyListeners();
    }
  }

  Future<void> connect(ScanResult result) async {
    await stopScan();
    await _clearConnection(disconnect: true);

    status = RobotBleStatus.connecting;
    errorMessage = null;
    notifyListeners();

    final device = result.device;
    _device = device;

    try {
      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 15),
      );
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected &&
            status != RobotBleStatus.disconnecting) {
          _handleUnexpectedDisconnect();
        }
      });

      final services = await device.discoverServices();
      _findCharacteristics(services);

      final eventCharacteristic = _eventCharacteristic!;
      await _eventSubscription?.cancel();
      _eventSubscription = eventCharacteristic.onValueReceived.listen(
        _handleIncomingValue,
      );
      await eventCharacteristic.setNotifyValue(true);

      status = RobotBleStatus.connected;
      notifyListeners();
      await ping();
      await requestStatus();
    } catch (error) {
      await _clearConnection(disconnect: true);
      _setError('เชื่อมต่อหุ่นยนต์ไม่สำเร็จ: $error');
    }
  }

  void _findCharacteristics(List<BluetoothService> services) {
    final serviceUuid = BleConstants.serviceUuid.toLowerCase();
    final commandUuid = BleConstants.commandUuid.toLowerCase();
    final eventUuid = BleConstants.eventUuid.toLowerCase();

    BluetoothService? robotService;
    for (final service in services) {
      if (service.uuid.toString().toLowerCase() == serviceUuid) {
        robotService = service;
        break;
      }
    }
    if (robotService == null) {
      throw StateError('ไม่พบ MindMeow BLE service');
    }

    for (final characteristic in robotService.characteristics) {
      final uuid = characteristic.uuid.toString().toLowerCase();
      if (uuid == commandUuid) _commandCharacteristic = characteristic;
      if (uuid == eventUuid) _eventCharacteristic = characteristic;
    }
    if (_commandCharacteristic == null || _eventCharacteristic == null) {
      throw StateError('พบ service แต่ไม่พบ command/event characteristic');
    }
  }

  void _handleIncomingValue(List<int> bytes) {
    lastReceived = utf8.decode(bytes, allowMalformed: true);
    final message = BleProtocol.tryDecode(bytes);
    if (message == null) {
      errorMessage = 'ได้รับ JSON ที่อ่านไม่ได้จากหุ่นยนต์';
      notifyListeners();
      return;
    }

    _applyEvent(message);
    _events.add(message);
    notifyListeners();
  }

  void _applyEvent(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'pong':
        protocolReady = BleProtocol.isValidPong(message);
        if (!protocolReady) {
          errorMessage = 'Protocol ของหุ่นยนต์ไม่ตรงกับแอป';
        }
      case 'error':
        errorMessage =
            'หุ่นยนต์แจ้งข้อผิดพลาด: '
            '${message['code'] ?? message['message'] ?? '-'}';
      case 'touch':
        touched = message['touched'] == true;
        touchRaw = (message['raw'] as num?)?.toInt();
        touchEnabled = message['enabled'] as bool? ?? touchEnabled;
      case 'servo':
        final id = message['id'];
        final enabled = message['enabled'] as bool?;
        final angle = (message['angle'] as num?)?.toInt();
        if (id == 'head') {
          if (enabled != null) headServoEnabled = enabled;
          if (angle != null) headAngle = angle;
        } else if (id == 'tail') {
          if (enabled != null) tailServoEnabled = enabled;
          if (angle != null) tailAngle = angle;
        }
      case 'eyes':
        eyesAvailable = message['available'] as bool? ?? eyesAvailable;
        eyesEnabled = message['enabled'] as bool? ?? eyesEnabled;
        eyeMode = message['mode'] as String? ?? eyeMode;
      case 'status':
        touchEnabled = message['touchEnabled'] as bool? ?? touchEnabled;
        touched = message['touched'] as bool? ?? touched;
        touchRaw = (message['touchRaw'] as num?)?.toInt() ?? touchRaw;
        headServoEnabled = message['headEnabled'] as bool? ?? headServoEnabled;
        tailServoEnabled = message['tailEnabled'] as bool? ?? tailServoEnabled;
        headAngle = (message['headAngle'] as num?)?.toInt() ?? headAngle;
        tailAngle = (message['tailAngle'] as num?)?.toInt() ?? tailAngle;
        eyesAvailable = message['eyesAvailable'] as bool? ?? eyesAvailable;
        eyesEnabled = message['eyesEnabled'] as bool? ?? eyesEnabled;
        eyeMode = message['eyeMode'] as String? ?? eyeMode;
    }
  }

  Future<void> send(Map<String, dynamic> message) {
    final operation = _writeQueue.then((_) async {
      final characteristic = _commandCharacteristic;
      if (!isConnected || characteristic == null) {
        throw const BleProtocolException('ยังไม่ได้เชื่อมต่อหุ่นยนต์');
      }
      final bytes = BleProtocol.encode(message);
      lastSent = utf8.decode(bytes);
      notifyListeners();
      await characteristic.write(bytes, withoutResponse: false);
    });
    _writeQueue = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> ping() => send(const {'type': 'ping'});

  Future<void> requestStatus() => send(const {'type': 'status_get'});

  Future<void> setTouchEnabled(bool enabled) =>
      send({'type': 'touch', 'enabled': enabled});

  Future<void> setServoEnabled(String id, bool enabled) {
    _validateServoId(id);
    return send({'type': 'servo', 'id': id, 'enabled': enabled});
  }

  Future<void> setServoAngle(String id, int angle) {
    _validateServoId(id);
    final minAngle = id == 'head'
        ? BleConstants.headMinAngle
        : BleConstants.tailMinAngle;
    final maxAngle = id == 'head'
        ? BleConstants.headMaxAngle
        : BleConstants.tailMaxAngle;
    return send({
      'type': 'servo',
      'id': id,
      'angle': angle.clamp(minAngle, maxAngle),
    });
  }

  Future<void> wagTail() =>
      send(const {'type': 'servo', 'id': 'tail', 'action': 'wag'});

  void _validateServoId(String id) {
    if (id != 'head' && id != 'tail') {
      throw BleProtocolException('ไม่รองรับเซอร์โว: $id');
    }
  }

  Future<void> setEyesEnabled(bool enabled) =>
      send({'type': 'eyes', 'enabled': enabled});

  Future<void> setEyeMode(String mode) {
    if (!BleConstants.eyeModes.contains(mode)) {
      throw BleProtocolException('ไม่รองรับโหมดตา: $mode');
    }
    return send({'type': 'eyes', 'action': 'test', 'mode': mode});
  }

  Future<void> disconnect() async {
    status = RobotBleStatus.disconnecting;
    notifyListeners();
    await _clearConnection(disconnect: true);
    status = adapterState == BluetoothAdapterState.on
        ? RobotBleStatus.idle
        : RobotBleStatus.bluetoothOff;
    notifyListeners();
  }

  Future<void> _handleUnexpectedDisconnect() async {
    await _clearConnection(disconnect: false);
    status = adapterState == BluetoothAdapterState.on
        ? RobotBleStatus.idle
        : RobotBleStatus.bluetoothOff;
    errorMessage = 'การเชื่อมต่อกับหุ่นยนต์ถูกตัด';
    notifyListeners();
  }

  Future<void> _clearConnection({required bool disconnect}) async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _commandCharacteristic = null;
    _eventCharacteristic = null;
    protocolReady = false;

    final device = _device;
    _device = null;
    if (disconnect && device != null) {
      try {
        await device.disconnect();
      } catch (_) {
        // The platform may already have completed the disconnection.
      }
    }
  }

  void _setError(String message) {
    errorMessage = message;
    status = RobotBleStatus.error;
    notifyListeners();
  }

  @visibleForTesting
  void applyEventForTest(Map<String, dynamic> message) => _applyEvent(message);

  @override
  void dispose() {
    unawaited(_adapterSubscription?.cancel());
    unawaited(_scanSubscription?.cancel());
    unawaited(_eventSubscription?.cancel());
    unawaited(_connectionSubscription?.cancel());
    super.dispose();
  }
}
