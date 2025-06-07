import 'package:flutter/material.dart';
import '../models/checkout.dart';
import '../services/api_service.dart';

class CheckoutProvider with ChangeNotifier {
  CheckoutInfo? _checkoutInfo;
  bool _isLoading = false;
  String? _error;
  int? _currentUserId; // Добавляем отслеживание текущего пользователя
  
  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController zipCodeController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController houseController = TextEditingController();
  
  // Wallet usage
  bool _useWallet = false;
  double _walletAmountToUse = 0.0;
  
  // Getters
  CheckoutInfo? get checkoutInfo => _checkoutInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get useWallet => _useWallet;
  double get walletAmountToUse => _walletAmountToUse;
  
  double get totalAmount {
    if (_checkoutInfo == null) return 0.0;
    return _checkoutInfo!.totalAmount - (_useWallet ? _walletAmountToUse : 0.0);
  }
  
  double get possibleCashback {
    if (_checkoutInfo?.loyaltyProgram == null) return 0.0;
    return _checkoutInfo!.loyaltyProgram!.possibleCashback;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    countryController.dispose();
    cityController.dispose();
    zipCodeController.dispose();
    streetController.dispose();
    houseController.dispose();
    super.dispose();
  }

  // Загрузка информации для оформления заказа
  Future<void> loadCheckoutInfo(BuildContext context) async {
    try {
      print('Загрузка информации для checkout...');
      final info = await ApiService.getCheckoutInfo();
      if (info != null) {
        print('Информация checkout получена: ${info.toString()}');
        
        // Проверяем, сменился ли пользователь
        if (_currentUserId != null && _currentUserId != info.user.id) {
          print('Обнаружена смена пользователя с ${_currentUserId} на ${info.user.id}');
          clear();
        }
        
        // Если данные уже не пусты, очищаем их (случай повторной загрузки)
        if (_checkoutInfo != null) {
          clear();
        }
        
        _currentUserId = info.user.id;
        _isLoading = true;
        _error = null;
        notifyListeners();
        
        _checkoutInfo = info;
        // НЕ предзаполняем имя - пользователь должен ввести его сам
        // Максимальная сумма для использования из кошелька
        if (info.loyaltyProgram != null) {
          _walletAmountToUse = info.loyaltyProgram!.walletBalance > info.totalAmount 
              ? info.totalAmount 
              : info.loyaltyProgram!.walletBalance;
        }
      } else {
        print('Получена null информация для checkout');
        throw Exception('Не удалось загрузить данные для оформления заказа');
      }
    } catch (e) {
      print('Ошибка в loadCheckoutInfo: $e');
      _error = e.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось загрузить данные для оформления заказа'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Переключение использования кошелька
  void toggleWalletUsage(bool value) {
    _useWallet = value;
    if (!value) {
      _walletAmountToUse = 0.0;
    } else if (_checkoutInfo?.loyaltyProgram != null) {
      _walletAmountToUse = _checkoutInfo!.loyaltyProgram!.walletBalance > _checkoutInfo!.totalAmount 
          ? _checkoutInfo!.totalAmount 
          : _checkoutInfo!.loyaltyProgram!.walletBalance;
    }
    notifyListeners();
  }

  // Изменение суммы к списанию из кошелька
  void updateWalletAmount(double amount) {
    if (_checkoutInfo?.loyaltyProgram != null) {
      final maxAmount = _checkoutInfo!.loyaltyProgram!.walletBalance > _checkoutInfo!.totalAmount 
          ? _checkoutInfo!.totalAmount 
          : _checkoutInfo!.loyaltyProgram!.walletBalance;
      
      if (amount <= maxAmount && amount >= 0) {
        _walletAmountToUse = amount;
        notifyListeners();
      }
    }
  }

  // Валидация формы
  String? validateForm() {
    if (nameController.text.trim().isEmpty) {
      return 'Введите имя';
    }
    
    final phoneRegex = RegExp(r'^\+7 \(\d{3}\) \d{3}-\d{2}-\d{2}$');
    if (!phoneRegex.hasMatch(phoneController.text)) {
      return 'Неверный формат телефона. Используйте: +7 (999) 999-99-99';
    }
    
    if (countryController.text.trim().isEmpty) {
      return 'Введите страну';
    }
    
    if (cityController.text.trim().isEmpty) {
      return 'Введите город';
    }
    
    final zipRegex = RegExp(r'^\d{6}$');
    if (!zipRegex.hasMatch(zipCodeController.text)) {
      return 'Почтовый индекс должен содержать 6 цифр';
    }
    
    if (streetController.text.trim().isEmpty) {
      return 'Введите улицу';
    }
    
    if (houseController.text.trim().isEmpty) {
      return 'Введите номер дома';
    }
    
    return null;
  }

  // Создание заказа
  Future<bool> createOrder(BuildContext context) async {
    final validationError = validateForm();
    if (validationError != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final contactData = ContactData(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
      );

      final addressData = AddressData(
        country: countryController.text.trim(),
        city: cityController.text.trim(),
        zipCode: zipCodeController.text.trim(),
        street: streetController.text.trim(),
        house: houseController.text.trim(),
      );

      final request = CreateOrderRequest(
        contactData: contactData,
        address: addressData,
        useWallet: _useWallet,
        walletAmount: _useWallet ? _walletAmountToUse : 0.0,
      );

      final result = await ApiService.createOrderNew(request);
      
      if (result.success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Заказ успешно создан! Номер: ${result.data!.orderId}'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Очищаем данные после успешного создания заказа
        clear();
        return true;
      } else {
        _error = result.error?.message ?? 'Ошибка создания заказа';
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_error!),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      _error = e.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания заказа: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Очистка данных
  void clear() {
    _checkoutInfo = null;
    _error = null;
    _useWallet = false;
    _walletAmountToUse = 0.0;
    _currentUserId = null; // Сбрасываем отслеживание пользователя
    
    nameController.clear();
    phoneController.clear();
    countryController.clear();
    cityController.clear();
    zipCodeController.clear();
    streetController.clear();
    houseController.clear();
    
    notifyListeners();
  }

  // Метод для очистки при смене пользователя (можно вызывать из AuthProvider)
  void clearForUserChange() {
    clear();
  }
}
