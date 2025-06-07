import 'product.dart';

class CheckoutInfo {
  final User user;
  final List<CartItem> cartItems;
  final double totalAmount;
  final LoyaltyProgram? loyaltyProgram;

  CheckoutInfo({
    required this.user,
    required this.cartItems,
    required this.totalAmount,
    this.loyaltyProgram,
  });

  factory CheckoutInfo.fromJson(Map<String, dynamic> json) {
    // Извлекаем cart items из вложенной структуры cart
    List<CartItem> cartItems = [];
    if (json['cart'] != null && json['cart']['cartItems'] != null) {
      cartItems = (json['cart']['cartItems'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList();
    }

    // Создаем пользователя из доступных данных
    User user = User(
      id: json['userId'] ?? 0,
      email: json['userEmail'] ?? '',
      username: json['userEmail'] ?? '', // Временно используем email как username
    );

    // Создаем loyaltyProgram если есть данные
    LoyaltyProgram? loyaltyProgram;
    if (json['loyaltyLevel'] != null && json['canUseWallet'] == true) {
      // Рассчитываем процент кэшбека на основе уровня
      double cashbackPercent = 0.0;
      switch (json['loyaltyLevel']) {
        case 'Базовый':
          cashbackPercent = 0.05; // 5%
          break;
        case 'Серебряный':
          cashbackPercent = 0.10; // 10%
          break;
        case 'Золотой':
          cashbackPercent = 0.15; // 15%
          break;
      }
      
      loyaltyProgram = LoyaltyProgram(
        level: json['loyaltyLevel'],
        cashbackPercent: cashbackPercent,
        walletBalance: (json['walletBalance'] ?? 0).toDouble(),
        possibleCashback: (json['potentialEarnings'] ?? 0).toDouble(),
      );
    }

    return CheckoutInfo(
      user: user,
      cartItems: cartItems,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      loyaltyProgram: loyaltyProgram,
    );
  }
}

class User {
  final int id;
  final String email;
  final String username;

  User({
    required this.id,
    required this.email,
    required this.username,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
    );
  }
}

class LoyaltyProgram {
  final String level;
  final double cashbackPercent;
  final double walletBalance;
  final double possibleCashback;

  LoyaltyProgram({
    required this.level,
    required this.cashbackPercent,
    required this.walletBalance,
    required this.possibleCashback,
  });

  factory LoyaltyProgram.fromJson(Map<String, dynamic> json) {
    return LoyaltyProgram(
      level: json['level'],
      cashbackPercent: json['cashbackPercent'].toDouble(),
      walletBalance: json['walletBalance'].toDouble(),
      possibleCashback: json['possibleCashback'].toDouble(),
    );
  }
}

class ContactData {
  final String name;
  final String phone;

  ContactData({
    required this.name,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
    };
  }
}

class AddressData {
  final String country;
  final String city;
  final String zipCode;
  final String street;
  final String house;

  AddressData({
    required this.country,
    required this.city,
    required this.zipCode,
    required this.street,
    required this.house,
  });

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'city': city,
      'zipCode': zipCode,
      'street': street,
      'house': house,
    };
  }
}

class CreateOrderRequest {
  final ContactData contactData;
  final AddressData address;
  final bool useWallet;
  final double walletAmount;

  CreateOrderRequest({
    required this.contactData,
    required this.address,
    required this.useWallet,
    required this.walletAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerName': contactData.name,
      'customerPhone': contactData.phone,
      'country': address.country,
      'city': address.city,
      'postalCode': address.zipCode,
      'street': address.street,
      'houseNumber': address.house,
      'useWallet': useWallet,
    };
  }
}

class CreatedOrder {
  final bool success;
  final int orderId;
  final String message;

  CreatedOrder({
    required this.success,
    required this.orderId,
    required this.message,
  });

  factory CreatedOrder.fromJson(Map<String, dynamic> json) {
    return CreatedOrder(
      success: json['success'] ?? false,
      orderId: json['orderId'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}
