import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../models/profile.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailsScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  OrderDetails? _orderDetails;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final details = await profileProvider.getOrderDetails(widget.orderId);
      
      setState(() {
        _orderDetails = details;
        _isLoading = false;
        _error = details == null ? 'Не удалось загрузить детали заказа' : null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Ошибка загрузки: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Заказ #${widget.orderId}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadOrderDetails();
              },
              child: const Text('Попробовать снова'),
            ),
          ],
        ),
      );
    }

    if (_orderDetails == null) {
      return const Center(child: Text('Заказ не найден'));
    }

    final order = _orderDetails!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Основная информация о заказе
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Информация о заказе',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow('Номер заказа', '#${order.id}'),
                  _buildInfoRow('Дата заказа', _formatDate(order.createdAt)),
                  
                  const Divider(),
                  
                  _buildInfoRow('Сумма товаров', '${order.totalAmount.toStringAsFixed(2)} ₽'),
                  if (order.walletUsed > 0)
                    _buildInfoRow('Использовано из кошелька', '-${order.walletUsed.toStringAsFixed(2)} ₽',
                                 valueColor: Colors.green),
                  if (order.walletEarned > 0)
                    _buildInfoRow('Кэшбэк начислен', '+${order.walletEarned.toStringAsFixed(2)} ₽',
                                 valueColor: Colors.blue),
                  
                  const Divider(),
                  
                  _buildInfoRow('Итого к оплате', '${order.finalAmount.toStringAsFixed(2)} ₽',
                               valueBold: true),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Контактная информация
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Контактная информация',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow('Имя', order.contactInfo.name),
                  _buildInfoRow('Телефон', order.contactInfo.phone),
                  _buildInfoRow('Email', order.contactInfo.email),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Адрес доставки
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Адрес доставки',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow('Адрес', order.address.address),
                  if (order.address.apartment.isNotEmpty)
                    _buildInfoRow('Квартира', order.address.apartment),
                  if (order.address.entrance.isNotEmpty)
                    _buildInfoRow('Подъезд', order.address.entrance),
                  if (order.address.floor.isNotEmpty)
                    _buildInfoRow('Этаж', order.address.floor),
                  if (order.address.comment.isNotEmpty)
                    _buildInfoRow('Комментарий', order.address.comment),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Товары в заказе
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Товары (${order.items.length})',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: item.product.imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.product.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.image_not_supported),
                                  ),
                                )
                              : const Icon(Icons.image_not_supported),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.product.price.toStringAsFixed(2)} ₽ × ${item.quantity}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Итого: ${(item.product.price * item.quantity).toStringAsFixed(2)} ₽',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: valueColor,
                fontWeight: valueBold ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
