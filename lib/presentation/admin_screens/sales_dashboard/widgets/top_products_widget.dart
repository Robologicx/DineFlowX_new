// widgets/top_products_widget.dart
import 'package:flutter/material.dart';
import 'package:hotel_management_system/core/utils/currency_formatter.dart';
import 'package:hotel_management_system/data/models/sales_model_and_management.dart';

class TopProductsWidget extends StatelessWidget {
  final List<ProductSales> topProducts;
  final int maxProducts;
  final String currencyCode;

  const TopProductsWidget({
    super.key,
    required this.topProducts,
    this.maxProducts = 5,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final displayProducts = topProducts.take(maxProducts).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Top Selling Products',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full products report
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (displayProducts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No product data available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayProducts.length,
                separatorBuilder: (context, index) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final product = displayProducts[index];
                  return _buildProductItem(context, product, index + 1);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    ProductSales product,
    int rank,
  ) {
    final rankColor = rank == 1
        ? Colors.amber
        : rank == 2
        ? Colors.grey[400]
        : rank == 3
        ? Colors.brown[300]
        : Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        // Rank Badge
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: rankColor?.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: rankColor ?? Colors.grey, width: 2),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: rankColor,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Product Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.productName,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.shopping_cart,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${product.quantitySold} sold',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Revenue
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.formatAmount(
                product.revenue,
                currencyCode: currencyCode,
              ),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${CurrencyFormatter.formatAmount((product.revenue / product.quantitySold), currencyCode: currencyCode)}/item',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
