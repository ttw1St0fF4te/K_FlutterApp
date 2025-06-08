import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../models/profile.dart';
import 'order_details_screen.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Загружаем данные профиля при первом открытии
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      await profileProvider.loadProfile();
      await profileProvider.loadLoyaltyProgram();
      // Загружаем кошелек только после загрузки программы лояльности
      await profileProvider.loadUserWallet();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        // Определяем количество вкладок в зависимости от доступности кошелька
        final bool walletAvailable = _isWalletAvailable(profileProvider);
        final int tabCount = walletAvailable ? 4 : 3;
        
        // Пересоздаем TabController если количество вкладок изменилось
        if (_tabController.length != tabCount) {
          _tabController.dispose();
          _tabController = TabController(length: tabCount, vsync: this);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Профиль'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                const Tab(icon: Icon(Icons.person), text: 'Контакты'),
                const Tab(icon: Icon(Icons.history), text: 'Заказы'),
                const Tab(icon: Icon(Icons.star), text: 'Лояльность'),
                if (walletAvailable)
                  const Tab(icon: Icon(Icons.wallet), text: 'Кошелек'),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              const ContactDataTab(),
              const OrderHistoryTab(),
              const LoyaltyProgramTab(),
              if (walletAvailable)
                const VirtualWalletTab(),
            ],
          ),
        );
      },
    );
  }

  bool _isWalletAvailable(ProfileProvider profileProvider) {
    // Кошелек доступен только если пользователь участвует в программе лояльности
    // и его уровень не "Нет уровня"
    final loyaltyProgram = profileProvider.loyaltyProgram;
    if (loyaltyProgram == null) return false;
    
    return loyaltyProgram.currentLevel != 'Нет уровня' && 
           loyaltyProgram.currentLevel.isNotEmpty;
  }
}

// Вкладка контактных данных
class ContactDataTab extends StatefulWidget {
  const ContactDataTab({Key? key}) : super(key: key);

  @override
  State<ContactDataTab> createState() => _ContactDataTabState();
}

class _ContactDataTabState extends State<ContactDataTab> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      if (profileProvider.userProfile != null) {
        _usernameController.text = profileProvider.userProfile!.username;
        _emailController.text = profileProvider.userProfile!.email;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        // Показываем SnackBar при ошибке
        if (profileProvider.error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(profileProvider.error!),
                backgroundColor: Colors.red,
              ),
            );
            profileProvider.clearError();
          });
        }

        if (profileProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (profileProvider.userProfile == null) {
          return const Center(child: Text('Не удалось загрузить профиль'));
        }

        final user = profileProvider.userProfile!;
        
        // Обновляем поля при загрузке данных
        if (!_isEditing) {
          _usernameController.text = user.username;
          _emailController.text = user.email;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Основная информация',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Имя пользователя',
                            border: OutlineInputBorder(),
                          ),
                          enabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Введите имя пользователя';
                            }
                            if (value.length < 3) {
                              return 'Имя должно содержать минимум 3 символа';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          enabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Введите email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Введите корректный email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        Text('ID: ${user.id}', style: Theme.of(context).textTheme.bodySmall),
                        
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isEditing ? _saveChanges : _toggleEdit,
                                child: Text(_isEditing ? 'Сохранить' : 'Редактировать'),
                              ),
                            ),
                            if (_isEditing) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _cancelEdit,
                                  child: const Text('Отмена'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Кнопка сброса пароля из профиля
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Забыли пароль?',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Мы отправим новый автоматически сгенерированный пароль на ваш email. После получения нового пароля вам потребуется войти в систему заново.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _resetPasswordFromProfile,
                          icon: const Icon(Icons.lock_reset),
                          label: const Text('Сбросить пароль'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (profileProvider.error != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        profileProvider.error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _cancelEdit() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    if (profileProvider.userProfile != null) {
      _usernameController.text = profileProvider.userProfile!.username;
      _emailController.text = profileProvider.userProfile!.email;
    }
    setState(() {
      _isEditing = false;
    });
    profileProvider.clearError();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final request = ProfileRequest(
      username: _usernameController.text,
      email: _emailController.text,
    );

    final success = await profileProvider.updateProfile(request);
    if (success) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль успешно обновлен')),
      );
    }
  }

  Future<void> _resetPasswordFromProfile() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    
    // Проверяем, есть ли email у пользователя
    if (profileProvider.userProfile?.email.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Для смены пароля необходимо указать email в контактных данных'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Показываем диалог предупреждения
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Подтверждение сброса пароля'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Вы действительно хотите сбросить пароль?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.amber.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Важно:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Новый пароль будет отправлен на ваш email\n'
                      '• Вам потребуется войти в систему заново\n'
                      '• Текущий пароль станет недействительным',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Сбросить пароль'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await profileProvider.resetPasswordFromProfile();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Новый пароль отправлен на ваш email. Войдите в систему заново.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Автоматически разлогиниваем пользователя и переводим на главную страницу
        if (context.mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.logout();
          // Переходим к корневому маршруту, где AuthWrapper решит, какой экран показать
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
            (route) => false,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}

// Вкладка истории заказов
class OrderHistoryTab extends StatefulWidget {
  const OrderHistoryTab({Key? key}) : super(key: key);

  @override
  State<OrderHistoryTab> createState() => _OrderHistoryTabState();
}

class _OrderHistoryTabState extends State<OrderHistoryTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      profileProvider.loadOrderHistory(refresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
        if (!profileProvider.loadingMoreOrders && profileProvider.hasMoreOrders) {
          profileProvider.loadOrderHistory();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        if (profileProvider.isLoading && profileProvider.orderHistory.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (profileProvider.orderHistory.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('У вас пока нет заказов'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => profileProvider.loadOrderHistory(refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: profileProvider.orderHistory.length + 
                       (profileProvider.loadingMoreOrders ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == profileProvider.orderHistory.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final order = profileProvider.orderHistory[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Icon(
                      Icons.shopping_bag,
                      color: Colors.white,
                    ),
                  ),
                  title: Text('Заказ #${order.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${order.totalAmount.toStringAsFixed(2)} ₽'),
                      Text(_formatDate(order.createdAt)),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _openOrderDetails(order.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openOrderDetails(int orderId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(orderId: orderId),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// Вкладка программы лояльности
class LoyaltyProgramTab extends StatelessWidget {
  const LoyaltyProgramTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        if (profileProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (profileProvider.loyaltyProgram == null) {
          return const Center(child: Text('Не удалось загрузить программу лояльности'));
        }

        final loyalty = profileProvider.loyaltyProgram!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Ваш текущий уровень',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loyalty.currentLevel,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Кэшбэк: ${loyalty.cashbackPercent.toStringAsFixed(1)}%',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Потрачено всего:'),
                          Text(
                            '${loyalty.totalSpent.toStringAsFixed(2)} ₽',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Баланс кошелька:'),
                          Text(
                            '${loyalty.walletBalance.toStringAsFixed(2)} ₽',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      if (loyalty.progressToNext.isNotEmpty) ...[
                        Text(
                          'Прогресс до следующего уровня:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loyalty.progressToNext,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Как работает программа лояльности',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildInfoItem(
                        icon: Icons.star,
                        title: 'Базовый уровень',
                        description: 'Доступен с суммы покупок от 30 000 ₽. Кэшбэк: 5%',
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildInfoItem(
                        icon: Icons.star_half,
                        title: 'Серебряный уровень',
                        description: 'Доступен с суммы покупок от 60 000 ₽. Кэшбэк: 10%',
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildInfoItem(
                        icon: Icons.star_rate,
                        title: 'Золотой уровень',
                        description: 'Доступен с суммы покупок от 120 000 ₽. Кэшбэк: 15%',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.amber, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Вкладка виртуального кошелька
class VirtualWalletTab extends StatelessWidget {
  const VirtualWalletTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        if (profileProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (profileProvider.userWallet == null) {
          return const Center(child: Text('Не удалось загрузить кошелек'));
        }

        final wallet = profileProvider.userWallet!;

        if (!wallet.isAvailable) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Кошелек недоступен',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Для активации кошелька необходимо\nпотратить минимум 30 000 ₽',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Баланс кошелька',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Theme.of(context).primaryColor,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${wallet.balance.toStringAsFixed(2)} ₽',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Доступно для использования',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Текущий уровень:'),
                          Text(
                            wallet.currentLevel,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Информация о кэшбэке',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      
                      if (profileProvider.loyaltyProgram != null) ...[
                        Text(
                          'Текущий процент кэшбэка: ${profileProvider.loyaltyProgram!.cashbackPercent.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        
                        Text(
                          'Общая сумма покупок: ${profileProvider.loyaltyProgram!.totalSpent.toStringAsFixed(2)} ₽',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Как использовать кошелек',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildInfoItem(
                        icon: Icons.add_circle,
                        title: 'Накопление средств',
                        description: 'Получайте кэшбэк с каждой покупки согласно вашему уровню в программе лояльности',
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildInfoItem(
                        icon: Icons.payment,
                        title: 'Использование средств',
                        description: 'Тратьте накопленные средства при оформлении заказов для получения скидки',
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildInfoItem(
                        icon: Icons.info,
                        title: 'Важно знать',
                        description: 'При использовании средств из кошелька кэшбэк не начисляется',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
