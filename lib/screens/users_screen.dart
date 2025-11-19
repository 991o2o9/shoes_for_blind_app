import 'package:flutter/material.dart';

import '../services/api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  // Функция для форматирования даты из ISO в формат "дд.мм.гггг чч:мм"
  String _formatDate(String? dateString) {
    if (dateString == null || dateString == 'Неизвестно') {
      return 'Неизвестно';
    }

    try {
      // Парсим ISO дату
      DateTime dateTime = DateTime.parse(dateString);

      // Форматируем в нужный формат вручную
      String day = dateTime.day.toString().padLeft(2, '0');
      String month = dateTime.month.toString().padLeft(2, '0');
      String year = dateTime.year.toString();
      String hour = dateTime.hour.toString().padLeft(2, '0');
      String minute = dateTime.minute.toString().padLeft(2, '0');

      return '$day.$month.$year $hour:$minute';
    } catch (e) {
      return 'Неизвестно';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final apiService = ApiService();
      final users = await apiService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки пользователей: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Пользователи")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          ? const Center(child: Text('Нет пользователей'))
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  title: Text(user['login'] ?? 'Неизвестный'),
                  subtitle: Text(
                    'Последний вход: ${_formatDate(user['lastLogin'])}',
                  ),
                  trailing: Text(user['role'] ?? 'user'),
                );
              },
            ),
    );
  }
}
