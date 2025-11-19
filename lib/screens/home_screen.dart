import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/bluetooth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ArduinoBluetoothService _btService = ArduinoBluetoothService();
  final ApiService _apiService = ApiService();
  bool _deviceOn = false;
  String _frontDist = 'N/A';
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
    _btService.dataStream.listen(_handleIncomingData);
  }

  Future<void> _initialize() async {
    try {
      final userData = await _apiService.getMe();
      setState(() {
        _isAdmin = userData['user']['role'] == 'admin';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _handleIncomingData(String data) {
    if (data.startsWith('FRONT_DIST:')) {
      setState(() => _frontDist = data.split(':')[1]);
    } else if (data.startsWith('DEVICE:ON')) {
      setState(() => _deviceOn = true);
    } else if (data.startsWith('DEVICE:OFF')) {
      setState(() => _deviceOn = false);
    }
  }

  void _toggleDevice() async {
    try {
      await _apiService.setDevicePower(!_deviceOn);
      setState(() => _deviceOn = !_deviceOn);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  void _testBuzzer() async {
    try {
      await _apiService.setBuzzer(true);
      await Future.delayed(const Duration(seconds: 1));
      await _apiService.setBuzzer(false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Тест звука выполнен')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  void _logout() async {
    await _apiService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Главная"),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => Navigator.pushNamed(context, '/users'),
            ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Large power button
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'Устройство: ${_deviceOn ? 'ВКЛЮЧЕНО' : 'ВЫКЛЮЧЕНО'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: ElevatedButton(
                        onPressed: _toggleDevice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _deviceOn
                              ? Colors.green
                              : Colors.red,
                          shape: const CircleBorder(),
                        ),
                        child: Icon(
                          _deviceOn ? Icons.power_off : Icons.power,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [Text('Передний датчик: $_frontDist см')],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/bluetooth'),
                    child: const Text("Bluetooth"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                    child: const Text("Настройки"),
                  ),
                  ElevatedButton(
                    onPressed: _testBuzzer,
                    child: const Text("Тест звука"),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/calibration'),
                    child: const Text("Калибровка"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
