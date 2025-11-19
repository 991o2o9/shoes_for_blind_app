import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

import '../services/bluetooth_service.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final ArduinoBluetoothService _btService = ArduinoBluetoothService();
  List<fbp.BluetoothDevice> _devices = [];
  fbp.BluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _btService.deviceStream.listen((device) {
      setState(() {
        _connectedDevice = device;
      });
    });
  }

  void _loadDevices() async {
    var devices = await _btService.getDevices();
    setState(() {
      _devices = devices;
    });
  }

  void _connect(fbp.BluetoothDevice device) async {
    bool success = await _btService.connect(device);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? "Подключено к ${device.name}" : "Не удалось подключиться",
        ),
      ),
    );
  }

  void _disconnect() async {
    await _btService.disconnect();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Отключено")));
  }

  void _sendTestCommand() async {
    await _btService.sendCommand("TURN_ON");
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Команда отправлена")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _connectedDevice == null
                ? const Text("Нет подключенных устройств")
                : Text("Подключено к: ${_connectedDevice!.name}"),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (_, index) {
                  final device = _devices[index];
                  return ListTile(
                    title: Text(device.name ?? "Unknown"),
                    subtitle: Text(device.remoteId.str),
                    trailing: _connectedDevice == device
                        ? ElevatedButton(
                            onPressed: _disconnect,
                            child: const Text("Отключить"),
                          )
                        : ElevatedButton(
                            onPressed: () => _connect(device),
                            child: const Text("Подключить"),
                          ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _sendTestCommand,
              child: const Text("Тест команды"),
            ),
          ],
        ),
      ),
    );
  }
}
