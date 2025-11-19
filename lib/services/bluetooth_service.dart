import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

class ArduinoBluetoothService {
  fbp.BluetoothDevice? connectedDevice;
  fbp.BluetoothCharacteristic? _txCharacteristic;
  fbp.BluetoothCharacteristic? _rxCharacteristic;
  StreamSubscription? _dataSubscription;

  final StreamController<String> _dataController =
      StreamController<String>.broadcast();
  final StreamController<fbp.BluetoothDevice?> _deviceController =
      StreamController<fbp.BluetoothDevice?>.broadcast();

  Stream<String> get dataStream => _dataController.stream;
  Stream<fbp.BluetoothDevice?> get deviceStream => _deviceController.stream;

  // Получаем список устройств
  Future<List<fbp.BluetoothDevice>> getDevices() async {
    List<fbp.BluetoothDevice> devices = [];
    try {
      // Start scanning
      await fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

      // Listen for scan results
      await for (final result in fbp.FlutterBluePlus.scanResults) {
        for (final device in result) {
          if (!devices.any((d) => d.remoteId == device.device.remoteId)) {
            devices.add(device.device);
          }
        }
        break; // Take first batch
      }

      await fbp.FlutterBluePlus.stopScan();
    } catch (e) {
      print('Error scanning: $e');
    }
    return devices;
  }

  // Подключение к устройству
  Future<bool> connect(fbp.BluetoothDevice device) async {
    try {
      await device.connect();
      connectedDevice = device;
      _deviceController.add(device);

      // Discover services
      List<fbp.BluetoothService> services = await device.discoverServices();

      // Find serial service (usually 00001101-0000-1000-8000-00805F9B34FB for SPP)
      for (fbp.BluetoothService service in services) {
        if (service.uuid.toString() == '00001101-0000-1000-8000-00805F9B34FB' ||
            service.uuid.toString().toLowerCase().contains('serial')) {
          for (fbp.BluetoothCharacteristic characteristic
              in service.characteristics) {
            if (characteristic.properties.write) {
              _txCharacteristic = characteristic;
            }
            if (characteristic.properties.notify) {
              _rxCharacteristic = characteristic;
              await _rxCharacteristic!.setNotifyValue(true);
              _dataSubscription = _rxCharacteristic!.value.listen((data) {
                String message = utf8.decode(data).trim();
                _dataController.add(message);
                _processMessage(message);
              });
            }
          }
          break;
        }
      }

      return true;
    } catch (e) {
      print('Connection error: $e');
      return false;
    }
  }

  // Отключение
  Future<void> disconnect() async {
    await _dataSubscription?.cancel();
    await connectedDevice?.disconnect();
    connectedDevice = null;
    _txCharacteristic = null;
    _rxCharacteristic = null;
    _deviceController.add(null);
  }

  // Отправка команды
  Future<void> sendCommand(String command) async {
    if (_txCharacteristic != null) {
      await _txCharacteristic!.write(utf8.encode(command + '\n'));
    }
  }

  void _processMessage(String message) async {
    // Process incoming messages from Arduino
    if (message.startsWith('FRONT_DIST:')) {
      double dist = double.tryParse(message.split(':')[1]) ?? 0;
      if (dist < 10) {
        await sendCommand('ALERT_MODE');
      }
    }
  }

  void dispose() {
    _dataSubscription?.cancel();
    _deviceController.close();
    _dataController.close();
  }
}
