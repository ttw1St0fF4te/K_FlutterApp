import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/checkout_provider.dart';
import '../providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CheckoutProvider>().loadCheckoutInfo(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оформление заказа'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CheckoutProvider>(
        builder: (context, checkoutProvider, child) {
          if (checkoutProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (checkoutProvider.checkoutInfo == null) {
            return const Center(
              child: Text('Не удалось загрузить данные для оформления заказа'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderSummary(checkoutProvider),
                const SizedBox(height: 24),
                _buildContactForm(checkoutProvider),
                const SizedBox(height: 24),
                _buildAddressForm(checkoutProvider),
                const SizedBox(height: 24),
                _buildWalletSection(checkoutProvider),
                const SizedBox(height: 24),
                _buildTotalSection(checkoutProvider),
                const SizedBox(height: 32),
                _buildCreateOrderButton(checkoutProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderSummary(CheckoutProvider provider) {
    final checkoutInfo = provider.checkoutInfo!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Состав заказа',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...checkoutInfo.cartItems.map((item) => _buildCartItem(item)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Итого:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${checkoutInfo.totalAmount.toStringAsFixed(0)} ₽',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(dynamic item) {
    final price = item.product?.price ?? 0;
    final quantity = item.quantity ?? 0;
    final totalPrice = price * quantity;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.product?.name ?? 'Товар'} x$quantity',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            '${totalPrice.toStringAsFixed(0)} ₽',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm(CheckoutProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Контактные данные',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: provider.nameController,
              decoration: const InputDecoration(
                labelText: 'Имя *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: provider.phoneController,
              decoration: const InputDecoration(
                labelText: 'Телефон *',
                hintText: 'Введите номер телефона',
                helperText: 'Формат: +7 (999) 999-99-99',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                PhoneNumberFormatter(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${provider.checkoutInfo?.user.email ?? ''}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressForm(CheckoutProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Адрес доставки',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: provider.countryController,
              decoration: const InputDecoration(
                labelText: 'Страна *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: provider.cityController,
              decoration: const InputDecoration(
                labelText: 'Город *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: provider.zipCodeController,
              decoration: const InputDecoration(
                labelText: 'Почтовый индекс *',
                hintText: '123456',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: provider.streetController,
              decoration: const InputDecoration(
                labelText: 'Улица *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: provider.houseController,
              decoration: const InputDecoration(
                labelText: 'Дом/квартира *',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSection(CheckoutProvider provider) {
    final loyaltyProgram = provider.checkoutInfo?.loyaltyProgram;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Виртуальный кошелек',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (loyaltyProgram == null) ...[
              // Пользователь не состоит в программе лояльности
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.wallet,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Виртуальный кошелек станет доступен при достижении базового уровня лояльности',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Сумма покупок от 30 000 ₽',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Пользователь в программе лояльности
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Уровень: ${loyaltyProgram.level} (${(loyaltyProgram.cashbackPercent * 100).toInt()}% кэшбек)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet, 
                             color: Colors.green.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Баланс кошелька: ${loyaltyProgram.walletBalance.toStringAsFixed(0)} ₽',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.add_circle, 
                             color: Colors.orange.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Возможно начисление: ${loyaltyProgram.possibleCashback.toStringAsFixed(0)} ₽ (${(loyaltyProgram.cashbackPercent * 100).toInt()}%)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Выбор действия с кошельком
              const Text(
                'Выберите действие:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      title: Row(
                        children: [
                          Icon(Icons.savings, color: Colors.blue.shade600, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Накопить средства')),
                        ],
                      ),
                      subtitle: Text(
                        'Получить кэшбек ${(loyaltyProgram.cashbackPercent * 100).toInt()}% с этого заказа',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: false,
                      groupValue: provider.useWallet,
                      onChanged: (value) {
                        provider.toggleWalletUsage(false);
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<bool>(
                      title: Row(
                        children: [
                          Icon(Icons.payment, color: Colors.green.shade600, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Списать средства')),
                        ],
                      ),
                      subtitle: Text(
                        loyaltyProgram.walletBalance > 0 
                            ? 'Использовать баланс кошелька для оплаты'
                            : 'Недостаточно средств в кошельке',
                        style: TextStyle(
                          fontSize: 12,
                          color: loyaltyProgram.walletBalance > 0 
                              ? Colors.grey.shade600 
                              : Colors.red.shade600,
                        ),
                      ),
                      value: true,
                      groupValue: provider.useWallet,
                      onChanged: loyaltyProgram.walletBalance > 0 
                          ? (value) {
                              provider.toggleWalletUsage(true);
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection(CheckoutProvider provider) {
    final loyaltyProgram = provider.checkoutInfo?.loyaltyProgram;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Стоимость товаров
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Стоимость товаров:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '${provider.checkoutInfo!.totalAmount.toStringAsFixed(0)} ₽',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            
            // Списание из кошелька (если используется)
            if (provider.useWallet && provider.walletAmountToUse > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.remove_circle, color: Colors.red.shade600, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        'Будет списано:',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    ],
                  ),
                  Text(
                    '-${provider.walletAmountToUse.toStringAsFixed(0)} ₽',
                    style: TextStyle(fontSize: 16, color: Colors.red.shade600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            
            // Начисление кэшбека (если не используется кошелек)
            if (!provider.useWallet && loyaltyProgram != null && loyaltyProgram.possibleCashback > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add_circle, color: Colors.green.shade600, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        'Будет начислено:',
                        style: TextStyle(fontSize: 16, color: Colors.green),
                      ),
                    ],
                  ),
                  Text(
                    '+${loyaltyProgram.possibleCashback.toStringAsFixed(0)} ₽',
                    style: TextStyle(fontSize: 16, color: Colors.green.shade600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            
            // Итоговая сумма к оплате
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'К оплате:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${provider.totalAmount.toStringAsFixed(0)} ₽',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateOrderButton(CheckoutProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: provider.isLoading 
            ? null 
            : () async {
                final success = await provider.createOrder(context);
                if (success && context.mounted) {
                  // Очищаем корзину после успешного заказа
                  context.read<CartProvider>().clearCart();
                  // Возвращаемся на главную
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18),
        ),
        child: provider.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Оформить заказ'),
      ),
    );
  }
}

// Форматтер для номера телефона
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Извлекаем только цифры из нового значения
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Если поле пустое, возвращаем пустое значение
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    
    // Если пользователь ввел первую цифру, автоматически добавляем +7
    String formattedText = '+7';
    String workingDigits = digitsOnly;
    
    // Если первая цифра 7, убираем ее (так как +7 уже есть)
    if (workingDigits.startsWith('7')) {
      workingDigits = workingDigits.substring(1);
    }
    
    // Ограничиваем до 10 цифр после +7
    if (workingDigits.length > 10) {
      workingDigits = workingDigits.substring(0, 10);
    }
    
    // Форматируем номер по частям
    if (workingDigits.isNotEmpty) {
      // Первые 3 цифры в скобках: +7 (XXX)
      final areaCode = workingDigits.substring(0, workingDigits.length > 3 ? 3 : workingDigits.length);
      formattedText += ' ($areaCode';
      
      if (workingDigits.length > 3) {
        formattedText += ')';
        
        // Следующие 3 цифры: +7 (XXX) XXX
        final nextThree = workingDigits.substring(3, workingDigits.length > 6 ? 6 : workingDigits.length);
        formattedText += ' $nextThree';
        
        if (workingDigits.length > 6) {
          // Следующие 2 цифры: +7 (XXX) XXX-XX
          final nextTwo = workingDigits.substring(6, workingDigits.length > 8 ? 8 : workingDigits.length);
          formattedText += '-$nextTwo';
          
          if (workingDigits.length > 8) {
            // Последние 2 цифры: +7 (XXX) XXX-XX-XX
            final lastTwo = workingDigits.substring(8);
            formattedText += '-$lastTwo';
          }
        }
      }
    }
    
    // Определяем позицию курсора
    int cursorPosition = formattedText.length;
    
    // Если пользователь удаляет символы, помещаем курсор в правильное место
    if (newValue.selection.baseOffset < oldValue.text.length) {
      // Это операция удаления
      final oldDigits = oldValue.text.replaceAll(RegExp(r'[^\d]'), '');
      final newDigits = digitsOnly;
      
      if (oldDigits.startsWith('7')) {
        final oldWorkingDigits = oldDigits.substring(1);
        final diff = oldWorkingDigits.length - newDigits.length;
        
        if (diff > 0) {
          // Вычисляем позицию курсора на основе количества цифр
          cursorPosition = _calculateCursorPosition(newDigits.length, formattedText);
        }
      }
    }
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
  
  int _calculateCursorPosition(int digitCount, String formattedText) {
    if (digitCount == 0) return 0;
    if (digitCount <= 3) return 4 + digitCount; // +7 (XXX
    if (digitCount <= 6) return 6 + digitCount; // +7 (XXX) XXX
    if (digitCount <= 8) return 7 + digitCount; // +7 (XXX) XXX-XX
    return 8 + digitCount; // +7 (XXX) XXX-XX-XX
  }
}
