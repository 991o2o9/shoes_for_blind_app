import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/bluetooth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ArduinoBluetoothService _btService = ArduinoBluetoothService();
  double _frontThreshold = 100.0;
  String _downSensitivity = 'medium';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
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
            _frontThreshold = (doc['frontThreshold'] ?? 100).toDouble();
            _downSensitivity = doc['downSensitivity'] ?? 'medium';
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
        _frontThreshold = (box.get('${currentUser}_frontThreshold') ?? 100)
            .toDouble();
        _downSensitivity =
            box.get('${currentUser}_downSensitivity') ?? 'medium';
      });
    }
  }

  void _updateFrontThreshold(double value) async {
    setState(() => _frontThreshold = value);
    await _btService.sendCommand('SET_FRONT_THRESHOLD:${value.toInt()}');

    try {
      // Try Firebase first
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'frontThreshold': value.toInt()});
        return;
      }
    } catch (e) {
      // Firebase not available, use local storage
    }

    // Fallback to local storage
    var box = await Hive.openBox('users');
    String? currentUser = box.get('current_user');
    if (currentUser != null) {
      await box.put('${currentUser}_frontThreshold', value.toInt());
    }
  }

  void _updateDownSensitivity(String value) async {
    setState(() => _downSensitivity = value);
    await _btService.sendCommand('SET_DOWN_SENSITIVITY:$value');

    try {
      // Try Firebase first
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'downSensitivity': value});
        return;
      }
    } catch (e) {
      // Firebase not available, use local storage
    }

    // Fallback to local storage
    var box = await Hive.openBox('users');
    String? currentUser = box.get('current_user');
    if (currentUser != null) {
      await box.put('${currentUser}_downSensitivity', value);
    }
  }

  void _testVibration() async {
    await _btService.sendCommand('TEST_VIBRATION');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Тест вибрации отправлен')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Настройки")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Порог переднего датчика (см)'),
                    Slider(
                      value: _frontThreshold,
                      min: 10,
                      max: 200,
                      divisions: 19,
                      label: _frontThreshold.toInt().toString(),
                      onChanged: _updateFrontThreshold,
                    ),
                    Text('${_frontThreshold.toInt()} см'),
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
                    const Text('Чувствительность нижнего датчика'),
                    DropdownButton<String>(
                      value: _downSensitivity,
                      items: ['low', 'medium', 'high'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) => _updateDownSensitivity(value!),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testVibration,
              child: const Text('Тест вибрации'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/calibration'),
              child: const Text('Калибровка датчиков'),
            ),
          ],
        ),
      ),
    );
  }
}
