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
      price: (json['price'] ?? 0).toDouble(),
      image: json['image'] ?? '',
      category: json['category'] ?? '',
      isInFavorites: json['isInFavorites'] ?? false,
    );
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
