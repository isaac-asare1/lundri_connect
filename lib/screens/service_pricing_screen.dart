import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../widgets/custom_button.dart';

class ServicePricingScreen extends StatefulWidget {
  const ServicePricingScreen({super.key});

  @override
  State<ServicePricingScreen> createState() => _ServicePricingScreenState();
}

class _ServicePricingScreenState extends State<ServicePricingScreen> {
  final List<_PricingItem> _items = [
    _PricingItem(name: 'Wash & Fold', price: '15.00'),
    _PricingItem(name: 'Wash & Iron', price: '20.00'),
    _PricingItem(name: 'Express Clean', price: '25.00'),
    _PricingItem(name: 'Stain Removal', price: '30.00'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Pricing')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          const Text(
            'Set the prices for each laundry service.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ..._items.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Price per load / service'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.softPink,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'GHS ${item.price}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Save Pricing',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Service pricing saved'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PricingItem {
  final String name;
  final String price;

  _PricingItem({required this.name, required this.price});
}
