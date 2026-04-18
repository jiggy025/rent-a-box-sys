import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/dashboard_box_summary.dart';

class BoxCard extends StatelessWidget {
  const BoxCard({
    super.key,
    required this.summary,
    required this.onTap,
    required this.onSellerTap,
  });

  final DashboardBoxSummary summary;
  final VoidCallback onTap;
  final VoidCallback onSellerTap;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₱ ', decimalDigits: 2);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFCF7), Color(0xFFF1E5D4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: const Color(0xFFD9C3A2)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 18,
              offset: Offset(0, 8),
              color: Color(0x14000000),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -10,
              right: -10,
              child: Transform.rotate(
                angle: 0.7,
                child: Container(
                  width: 52,
                  height: 52,
                  color: const Color(0xFFE4B171),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BOX ${summary.boxNumber}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(summary.isVacant ? 'Vacant' : 'Occupied'),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: summary.sellerId == null ? null : onSellerTap,
                  child: Text(
                    summary.sellerName ?? 'Vacant',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currency.format(summary.total),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
