import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/bluetooth_screen.dart';
import 'screens/calibration_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/logs_screen.dart';
import 'screens/register_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Try to initialize Firebase
  bool firebaseAvailable = true;
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase initialization failed: $e');
    firebaseAvailable = false;
  }

  runApp(MyApp(firebaseAvailable: firebaseAvailable));
}

class MyApp extends StatelessWidget {
  final bool firebaseAvailable;

  const MyApp({super.key, required this.firebaseAvailable});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arduino Bluetooth App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<bool>(
        future: _checkAuthentication(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.data == true) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const HomeScreen(),
        '/bluetooth': (_) => const BluetoothScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/logs': (_) => const LogsScreen(),
        '/calibration': (_) => const CalibrationScreen(),
      },
    );
  }

  Future<bool> _checkAuthentication() async {
    // Check Firebase auth first if available
    if (firebaseAvailable) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) return true;
      } catch (e) {
        // Firebase not working, fall back to local
      }
    }

    // Check local storage
    try {
      var box = await Hive.openBox('users');
      String? currentUser = box.get('current_user');
      return currentUser != null;
    } catch (e) {
      return false;
    }
  }
}
