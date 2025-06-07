class Product {
  final int id;
  final String name;
  final double price;
  final String image;
  final String category;
  bool isInFavorites;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.category,
    this.isInFavorites = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: _parseDouble(json['price']),
      image: json['image'] ?? '',
      category: json['category'] ?? '',
      isInFavorites: json['isInFavorites'] ?? false,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image': image,
      'category': category,
      'isInFavorites': isInFavorites,
    };
  }

  Product copyWith({
    int? id,
    String? name,
    double? price,
    String? image,
    String? category,
    bool? isInFavorites,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      image: image ?? this.image,
      category: category ?? this.category,
      isInFavorites: isInFavorites ?? this.isInFavorites,
    );
  }
}

class ProductsResponse {
  final List<Product> products;
  final int total;
  final int page;
  final int totalPages;

  ProductsResponse({
    required this.products,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    return ProductsResponse(
      products: (json['products'] as List<dynamic>?)
          ?.map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

class ToggleFavoriteRequest {
  final int productId;

  ToggleFavoriteRequest({required this.productId});

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
    };
  }
}

class ToggleFavoriteResponse {
  final String message;
  final bool isInFavorites;

  ToggleFavoriteResponse({
    required this.message,
    required this.isInFavorites,
  });

  factory ToggleFavoriteResponse.fromJson(Map<String, dynamic> json) {
    return ToggleFavoriteResponse(
      message: json['message'] ?? '',
      isInFavorites: json['isInFavorites'] ?? false,
    );
  }
}

class FavoriteItem {
  final int id;
  final Product product;

  FavoriteItem({
    required this.id,
    required this.product,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'] ?? 0,
      product: Product.fromJson(json['product'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
    };
  }
}

class ProductDetails {
  final int id;
  final String name;
  final String description;
  final double price;
  final String image;
  final String category;
  final bool isInCart;
  final bool isInFavorites;
  final double averageRating;
  final int reviewsCount;

  ProductDetails({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.category,
    required this.isInCart,
    required this.isInFavorites,
    required this.averageRating,
    required this.reviewsCount,
  });

  factory ProductDetails.fromJson(Map<String, dynamic> json) {
    return ProductDetails(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: _parseDouble(json['price']),
      image: json['image'] ?? '',
      category: json['category'] ?? '',
      isInCart: json['isInCart'] ?? false,
      isInFavorites: json['isInFavorites'] ?? false,
      averageRating: _parseDouble(json['averageRating']),
      reviewsCount: json['reviewsCount'] ?? 0,
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

class Review {
  final int id;
  final String text;
  final int rating;
  final String date;
  final ReviewUser user;

  Review({
    required this.id,
    required this.text,
    required this.rating,
    required this.date,
    required this.user,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      rating: json['rating'] ?? 0,
      date: json['date'] ?? '',
      user: ReviewUser.fromJson(json['user'] ?? {}),
    );
  }
}

class ReviewUser {
  final String username;

  ReviewUser({required this.username});

  factory ReviewUser.fromJson(Map<String, dynamic> json) {
    return ReviewUser(
      username: json['username'] ?? '',
    );
  }
}

class CreateReviewRequest {
  final int productId;
  final int rating;
  final String text;

  CreateReviewRequest({
    required this.productId,
    required this.rating,
    required this.text,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'rating': rating,
      'text': text,
    };
  }
}

class CreateReviewResponse {
  final String message;
  final Review review;

  CreateReviewResponse({
    required this.message,
    required this.review,
  });

  factory CreateReviewResponse.fromJson(Map<String, dynamic> json) {
    return CreateReviewResponse(
      message: json['message'] ?? '',
      review: Review.fromJson(json['review'] ?? {}),
    );
  }
}

class CartItem {
  final int id;
  final int cartId;
  final int productId;
  final int quantity;
  final Product product;

  CartItem({
    required this.id,
    required this.cartId,
    required this.productId,
    required this.quantity,
    required this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? 0,
      cartId: json['cartId'] ?? 0,
      productId: json['productId'] ?? 0,
      quantity: json['quantity'] ?? 0,
      product: Product.fromJson(json['product'] ?? {}),
    );
  }
}

class Cart {
  final int id;
  final int userId;
  final List<CartItem> cartItems;
  final double totalAmount;

  Cart({
    required this.id,
    required this.userId,
    required this.cartItems,
    required this.totalAmount,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      cartItems: (json['cartItems'] as List<dynamic>?)
          ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      totalAmount: _parseDouble(json['totalAmount']),
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

class AddToCartResponse {
  final String message;
  final CartItem cartItem;

  AddToCartResponse({
    required this.message,
    required this.cartItem,
  });

  factory AddToCartResponse.fromJson(Map<String, dynamic> json) {
    return AddToCartResponse(
      message: json['message'] ?? '',
      cartItem: CartItem.fromJson(json['cartItem'] ?? {}),
    );
  }
}
