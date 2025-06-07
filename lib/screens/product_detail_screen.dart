import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_detail_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _reviewController = TextEditingController();
  int _selectedRating = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final provider = context.read<ProductDetailProvider>();
    // Очищаем ошибки отзывов перед загрузкой нового товара
    provider.clearReviewErrors();
    provider.loadProductDetails(widget.productId);
    provider.loadReviews(widget.productId);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали товара'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ProductDetailProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final product = provider.productDetails;
          if (product == null) {
            return const Center(child: Text('Товар не найден'));
          }

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductInfo(product),
                  const SizedBox(height: 24),
                  _buildActionButtons(product),
                  const SizedBox(height: 24),
                  _buildReviewForm(),
                  const SizedBox(height: 24),
                  _buildReviewsList(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductInfo(ProductDetails product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.image,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.category,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₽${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              product.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildRatingInfo(product),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingInfo(ProductDetails product) {
    return Row(
      children: [
        _buildStarRating(product.averageRating),
        const SizedBox(width: 8),
        Text(
          '${product.averageRating.toStringAsFixed(1)} (${product.reviewsCount} отзывов)',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStarRating(double rating, {double size = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : index < rating
                  ? Icons.star_half
                  : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }

  Widget _buildActionButtons(ProductDetails product) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAuthenticated = authProvider.user != null;
        
        return Column(
          children: [
            // Кнопка избранного
            SizedBox(
              width: double.infinity,
              child: Consumer<ProductDetailProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton.icon(
                    onPressed: isAuthenticated && !provider.isTogglingFavorite
                        ? () => provider.toggleFavorite(product.id)
                        : null,
                    icon: provider.isTogglingFavorite
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            product.isInFavorites
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: product.isInFavorites ? Colors.red : null,
                          ),
                    label: Text(
                      product.isInFavorites ? 'В избранном' : 'Добавить в избранное',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: product.isInFavorites
                          ? Colors.red.shade50
                          : null,
                      foregroundColor: product.isInFavorites
                          ? Colors.red
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Кнопка корзины
            SizedBox(
              width: double.infinity,
              child: Consumer<ProductDetailProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton.icon(
                    onPressed: isAuthenticated && !provider.isAddingToCart
                        ? () async {
                            if (product.isInCart) {
                              // TODO: Переход к корзине (реализуем позже)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Переход к корзине будет реализован позже'),
                                ),
                              );
                            } else {
                              final success = await provider.addToCart(product.id);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Товар добавлен в корзину'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    icon: provider.isAddingToCart
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            product.isInCart
                                ? Icons.shopping_cart
                                : Icons.add_shopping_cart,
                          ),
                    label: Text(
                      product.isInCart ? 'В корзине' : 'Добавить в корзину',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: product.isInCart
                          ? Colors.green
                          : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  );
                },
              ),
            ),
            if (!isAuthenticated) ...[
              const SizedBox(height: 8),
              Text(
                'Войдите в систему для добавления товаров в избранное и корзину',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildReviewForm() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAuthenticated = authProvider.user != null;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Оставить отзыв',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (!isAuthenticated) ...[
                  Text(
                    'Войдите в систему, чтобы оставить отзыв',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ] else ...[
                  const Text('Рейтинг:'),
                  const SizedBox(height: 8),
                  _buildRatingSelector(),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reviewController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Текст отзыва',
                      hintText: 'Расскажите о вашем опыте использования товара...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<ProductDetailProvider>(
                    builder: (context, provider, child) {
                      if (provider.reviewErrorMessage != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            provider.reviewErrorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Consumer<ProductDetailProvider>(
                      builder: (context, provider, child) {
                        return ElevatedButton(
                          onPressed: provider.isSubmittingReview
                              ? null
                              : () => _submitReview(provider),
                          child: provider.isSubmittingReview
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Оставить отзыв'),
                        );
                      },
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

  Widget _buildRatingSelector() {
    return Row(
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRating = starIndex;
            });
          },
          child: Icon(
            starIndex <= _selectedRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
        );
      }),
    );
  }

  Widget _buildReviewsList(ProductDetailProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Отзывы',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (provider.isLoadingReviews)
          const Center(child: CircularProgressIndicator())
        else if (provider.reviews.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('Отзывов пока нет'),
              ),
            ),
          )
        else
          ...provider.reviews.map((review) => _buildReviewCard(review)),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  review.user.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildStarRating(review.rating.toDouble(), size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.text),
            const SizedBox(height: 8),
            Text(
              _formatDate(review.date),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _submitReview(ProductDetailProvider provider) async {
    final text = _reviewController.text.trim();
    
    if (text.length < 10) {
      // Устанавливаем ошибку через публичный метод
      setState(() {
        // Показываем ошибку через SnackBar
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Отзыв должен содержать минимум 10 символов'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await provider.submitReview(
      widget.productId,
      _selectedRating,
      text,
    );

    if (success) {
      _reviewController.clear();
      setState(() {
        _selectedRating = 5;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Отзыв успешно добавлен'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
