// Модели для профиля пользователя

class UserProfile {
  final int id;
  final String username;
  final String email;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
    };
  }
}

class ProfileRequest {
  final String username;
  final String email;

  ProfileRequest({
    required this.username,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
    };
  }
}

class ProfileResponse {
  final UserProfile user;

  ProfileResponse({
    required this.user,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      user: UserProfile.fromJson(json['user'] ?? json),
    );
  }
}

class ResetPasswordRequest {
  final String currentPassword;
  final String newPassword;

  ResetPasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
  }
}

class OrderHistoryItem {
  final int id;
  final DateTime createdAt;
  final double totalAmount;
  final String status;

  OrderHistoryItem({
    required this.id,
    required this.createdAt,
    required this.totalAmount,
    required this.status,
  });

  factory OrderHistoryItem.fromJson(Map<String, dynamic> json) {
    return OrderHistoryItem(
      id: json['id'],
      createdAt: DateTime.parse(json['orderDate'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      totalAmount: _parseDouble(json['totalAmount']),
      status: json['status'] ?? 'Оформлен',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class OrderHistoryResponse {
  final List<OrderHistoryItem> orders;
  final bool hasMore;

  OrderHistoryResponse({
    required this.orders,
    required this.hasMore,
  });

  factory OrderHistoryResponse.fromJson(Map<String, dynamic> json) {
    return OrderHistoryResponse(
      orders: (json['orders'] as List)
          .map((item) => OrderHistoryItem.fromJson(item))
          .toList(),
      hasMore: json['hasMore'] ?? false,
    );
  }
}

class OrderDetails {
  final int id;
  final DateTime createdAt;
  final double totalAmount;
  final double finalAmount;
  final double walletUsed;
  final double walletEarned;
  final String status;
  final ContactInfo contactInfo;
  final DeliveryAddress address;
  final List<OrderItemDetails> items;

  OrderDetails({
    required this.id,
    required this.createdAt,
    required this.totalAmount,
    required this.finalAmount,
    required this.walletUsed,
    required this.walletEarned,
    required this.status,
    required this.contactInfo,
    required this.address,
    required this.items,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    return OrderDetails(
      id: json['id'],
      createdAt: DateTime.parse(json['orderDate'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      totalAmount: _parseDouble(json['totalAmount']),
      finalAmount: _parseDouble(json['finalAmount']),
      walletUsed: _parseDouble(json['walletUsed']),
      walletEarned: _parseDouble(json['walletEarned']),
      status: json['status'] ?? 'Оформлен',
      contactInfo: ContactInfo(
        name: json['customerName'] ?? '',
        phone: json['customerPhone'] ?? '',
        email: json['user']?['email'] ?? '',
      ),
      address: DeliveryAddress(
        address: json['deliveryAddress'] ?? '',
        apartment: '',
        entrance: '',
        floor: '',
        comment: '',
      ),
      items: (json['orderItems'] as List?)
          ?.map((item) => OrderItemDetails.fromJson(item))
          .toList() ?? [],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class ContactInfo {
  final String name;
  final String phone;
  final String email;

  ContactInfo({
    required this.name,
    required this.phone,
    required this.email,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class DeliveryAddress {
  final String address;
  final String apartment;
  final String entrance;
  final String floor;
  final String comment;

  DeliveryAddress({
    required this.address,
    required this.apartment,
    required this.entrance,
    required this.floor,
    required this.comment,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      address: json['address'] ?? '',
      apartment: json['apartment'] ?? '',
      entrance: json['entrance'] ?? '',
      floor: json['floor'] ?? '',
      comment: json['comment'] ?? '',
    );
  }
}

class OrderItemDetails {
  final ProductInfo product;
  final int quantity;

  OrderItemDetails({
    required this.product,
    required this.quantity,
  });

  factory OrderItemDetails.fromJson(Map<String, dynamic> json) {
    return OrderItemDetails(
      product: ProductInfo.fromJson(json['product'] ?? {}),
      quantity: json['quantity'] ?? 0,
    );
  }
}

class ProductInfo {
  final int id;
  final String name;
  final double price;
  final String imageUrl;

  ProductInfo({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: json['id'],
      name: json['name'] ?? '',
      price: _parseDouble(json['price']),
      imageUrl: json['image'] ?? json['imageUrl'] ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

// Loyalty Program models
class LoyaltyProgram {
  final String currentLevel;
  final double cashbackPercent; 
  final double totalSpent;
  final String progressToNext;
  final double walletBalance;

  LoyaltyProgram({
    required this.currentLevel,
    required this.cashbackPercent,
    required this.totalSpent,
    required this.progressToNext,
    required this.walletBalance,
  });

  factory LoyaltyProgram.fromJson(Map<String, dynamic> json) {
    return LoyaltyProgram(
      currentLevel: json['currentLevel'] ?? 'Нет уровня',
      cashbackPercent: _parseDouble(json['cashbackPercent']),
      totalSpent: _parseDouble(json['totalSpent']),
      progressToNext: json['progressToNext'] ?? '',
      walletBalance: _parseDouble(json['walletBalance']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class LoyaltyLevel {
  final int id;
  final String name;
  final double minSpent;
  final double cashbackPercentage;

  LoyaltyLevel({
    required this.id,
    required this.name,
    required this.minSpent,
    required this.cashbackPercentage,
  });

  factory LoyaltyLevel.fromJson(Map<String, dynamic> json) {
    return LoyaltyLevel(
      id: json['id'],
      name: json['name'] ?? '',
      minSpent: _parseDouble(json['minSpent']),
      cashbackPercentage: _parseDouble(json['cashbackPercentage']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

// User Wallet models
class UserWallet {
  final double balance;
  final String currentLevel;
  final bool isAvailable;

  UserWallet({
    required this.balance,
    required this.currentLevel,
    required this.isAvailable,
  });

  factory UserWallet.fromJson(Map<String, dynamic> json) {
    return UserWallet(
      balance: _parseDouble(json['balance']),
      currentLevel: json['currentLevel'] ?? '',
      isAvailable: json['isAvailable'] ?? false,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
