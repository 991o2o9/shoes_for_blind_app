import 'package:flutter/material.dart';

import '../services/bluetooth_service.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final ArduinoBluetoothService _btService = ArduinoBluetoothService();
  String _status = 'Готов к калибровке';
  double _normalDistance = 0;
  double _stepDistance = 0;

  void _startCalibration() async {
    setState(() => _status = 'Измерение нормального расстояния...');
    await Future.delayed(const Duration(seconds: 2));
    // Simulate reading normal distance
    _normalDistance = 150.0; // Example value
    setState(
      () => _status =
          'Нормальное расстояние: $_normalDistance см\nПоднимите ногу и нажмите "Измерить подъём"',
    );

    // In real app, send command to Arduino to measure
    await _btService.sendCommand('CALIBRATE_NORMAL');
  }

  void _measureStep() async {
    setState(() => _status = 'Измерение расстояния при подъёме...');
    await Future.delayed(const Duration(seconds: 2));
    _stepDistance = 100.0; // Example value
    setState(
      () => _status =
          'Расстояние при подъёме: $_stepDistance см\nНажмите "Завершить калибровку"',
    );

    // In real app, send command to Arduino to measure
    await _btService.sendCommand('CALIBRATE_STEP');
  }

  void _finishCalibration() async {
    double range = _normalDistance - _stepDistance;
    String sensitivity = range > 30
        ? 'low'
        : range > 15
        ? 'medium'
        : 'high';

    await _btService.sendCommand('SET_DOWN_SENSITIVITY:$sensitivity');
    setState(
      () => _status = 'Калибровка завершена. Чувствительность: $sensitivity',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Калибровка завершена. Чувствительность: $sensitivity'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Калибровка датчиков")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_status, textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startCalibration,
              child: const Text('Начать калибровку'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _measureStep,
              child: const Text('Измерить подъём'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _finishCalibration,
              child: const Text('Завершить калибровку'),
            ),
          ],
        ),
      ),
    );
  }
}
