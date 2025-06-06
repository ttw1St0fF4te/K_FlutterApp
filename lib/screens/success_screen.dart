import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Анимированная иконка успеха
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        spreadRadius: 5,
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Заголовок
                Text(
                  'Успешный вход!',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Приветствие пользователя
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Text(
                      'Добро пожаловать, ${authProvider.user?.username}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Сообщение
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.construction,
                        size: 48,
                        color: Colors.orange[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Каталог в разработке',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Скоро здесь будет отображаться каталог товаров. А пока вы можете изучить функции аккаунта.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Информация о пользователе
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Информация об аккаунте:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.blue[600], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'ID: ${authProvider.user?.id}',
                                style: TextStyle(color: Colors.blue[700]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.account_circle, color: Colors.blue[600], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Логин: ${authProvider.user?.username}',
                                style: TextStyle(color: Colors.blue[700]),
                              ),
                            ],
                          ),
                          if (authProvider.user?.email != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.email, color: Colors.blue[600], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Email: ${authProvider.user?.email}',
                                    style: TextStyle(color: Colors.blue[700]),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Кнопка выхода
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      await authProvider.logout();
                      
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Выйти из аккаунта',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
