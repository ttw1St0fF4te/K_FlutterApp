class User {
  final int id;
  final String username;
  final String? email;
  final int? userRoleId;
  final String? loyaltyLevel;
  final double? totalSpent;
  final double? walletBalance;
  final UserRole? userRole;

  User({
    required this.id,
    required this.username,
    this.email,
    this.userRoleId,
    this.loyaltyLevel,
    this.totalSpent,
    this.walletBalance,
    this.userRole,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      userRoleId: json['userRoleId'],
      loyaltyLevel: json['loyaltyLevel'],
      totalSpent: _parseDouble(json['totalSpent']),
      walletBalance: _parseDouble(json['walletBalance']),
      userRole: json['userRole'] != null ? UserRole.fromJson(json['userRole']) : null,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'userRoleId': userRoleId,
      'loyaltyLevel': loyaltyLevel,
      'totalSpent': totalSpent,
      'walletBalance': walletBalance,
      'userRole': userRole?.toJson(),
    };
  }
}

class UserRole {
  final int id;
  final String role;

  UserRole({
    required this.id,
    required this.role,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['id'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
    };
  }
}
