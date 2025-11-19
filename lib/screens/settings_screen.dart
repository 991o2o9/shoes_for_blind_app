import 'package:flutter/material.dart';

import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  double _frontThreshold = 100.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // For now, use default values since we removed user-specific settings
      // In a real app, you might want to store this in the backend
      setState(() {
        _frontThreshold = 100.0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _updateFrontThreshold(double value) async {
    setState(() => _frontThreshold = value);
    // Here you would send the command to Arduino via Bluetooth
    // For now, just update the local state
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
