import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  @override
  Widget build(BuildContext context) {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null)
        return const Scaffold(
          body: Center(child: Text('Пользователь не авторизован')),
        );

      return Scaffold(
        appBar: AppBar(title: const Text("Журнал событий")),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('logs')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Нет событий'));
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var doc = snapshot.data!.docs[index];
                var data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(data['event'] ?? 'Неизвестное событие'),
                  subtitle: Text(data['timestamp']?.toDate().toString() ?? ''),
                );
              },
            );
          },
        ),
      );
    } catch (e) {
      // Firebase not available
      return Scaffold(
        appBar: AppBar(title: const Text("Журнал событий")),
        body: const Center(
          child: Text('Журнал событий недоступен без подключения к Firebase'),
        ),
      );
    }
  }
}
