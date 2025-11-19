import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/bluetooth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ArduinoBluetoothService _btService = ArduinoBluetoothService();
  bool _deviceOn = false;
  String _frontDist = 'N/A';
  String _downDist = 'N/A';

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
    _btService.dataStream.listen(_handleIncomingData);
  }

  void _loadUserSettings() async {
    try {
      // Try Firebase first
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            _deviceOn = doc['deviceOn'] ?? false;
          });
          return;
        }
      }
    } catch (e) {
      // Firebase not available, use local storage
    }

    // Fallback to local storage
    var box = await Hive.openBox('users');
    String? currentUser = box.get('current_user');
    if (currentUser != null) {
      setState(() {
        _deviceOn = box.get('${currentUser}_deviceOn') ?? false;
      });
    }
  }

  void _handleIncomingData(String data) {
    if (data.startsWith('FRONT_DIST:')) {
      setState(() => _frontDist = data.split(':')[1]);
    } else if (data.startsWith('DOWN_DIST:')) {
      setState(() => _downDist = data.split(':')[1]);
    } else if (data.startsWith('DEVICE:ON')) {
      setState(() => _deviceOn = true);
    } else if (data.startsWith('DEVICE:OFF')) {
      setState(() => _deviceOn = false);
    }
  }

  void _toggleDevice() async {
    String command = _deviceOn ? 'TURN_OFF' : 'TURN_ON';
    await _btService.sendCommand(command);
    setState(() => _deviceOn = !_deviceOn);

    try {
      // Try Firebase first
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'deviceOn': _deviceOn});
        return;
      }
    } catch (e) {
      // Firebase not available, use local storage
    }

    // Fallback to local storage
    var box = await Hive.openBox('users');
    String? currentUser = box.get('current_user');
    if (currentUser != null) {
      await box.put('${currentUser}_deviceOn', _deviceOn);
    }
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      // Firebase not available, just clear local user
      var box = await Hive.openBox('users');
      await box.delete('current_user');
    }
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Главная"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Устройство: ${_deviceOn ? 'ВКЛ' : 'ВЫКЛ'}'),
                    Switch(
                      value: _deviceOn,
                      onChanged: (value) => _toggleDevice(),
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
                  children: [
                    Text('Передний датчик: $_frontDist см'),
                    Text('Нижний датчик: $_downDist см'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
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
                    onPressed: () => Navigator.pushNamed(context, '/logs'),
                    child: const Text("Журнал"),
                  ),
                  ElevatedButton(
                    onPressed: () => _btService.sendCommand('TEST_VIBRATION'),
                    child: const Text("Тест вибрации"),
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
