import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      // Try Firebase first
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _usernameController.text.trim(),
            password: _passwordController.text,
          );

      // Create user document in Firestore with default settings
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'email': _usernameController.text.trim(),
            'frontThreshold': 100,
            'downSensitivity': 'medium',
            'deviceOn': false,
          });
    } catch (e) {
      // Fallback to local storage
      var box = await Hive.openBox('users');
      String username = _usernameController.text.trim();

      // Check if user already exists
      if (box.get('${username}_password') != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пользователь уже существует')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Save user locally
      await box.put('${username}_password', _passwordController.text);
      await box.put('${username}_frontThreshold', 100);
      await box.put('${username}_downSensitivity', 'medium');
      await box.put('${username}_deviceOn', false);
      await box.put('current_user', username);
    }

    Navigator.pushReplacementNamed(context, '/home');
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Регистрация")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Email (username)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Пароль',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _register,
                    child: const Text("Зарегистрироваться"),
                  ),
          ],
        ),
      ),
    );
  }
}
