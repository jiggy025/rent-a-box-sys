import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/seller_ledger_summary.dart';
import '../../providers/seller_providers.dart';
import '../dashboard/widgets/add_seller_sheet.dart';
import 'seller_detail_screen.dart';

class SellersScreen extends ConsumerWidget {
  const SellersScreen({super.key});

  void _openAddSellerSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddSellerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellersAsync = ref.watch(filteredSellerLedgerSummariesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sellers')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSellerSheet(context),
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              key: const Key('seller-search-field'),
              decoration: const InputDecoration(
                hintText: 'Search seller',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  ref.read(sellerSearchProvider.notifier).state = value,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: sellersAsync.when(
                data: (sellers) {
                  if (sellers.isEmpty) {
                    return const Center(child: Text('No sellers yet.'));
                  }

                  return ListView.separated(
                    itemCount: sellers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final summary = sellers[index];
                      return _SellerSummaryCard(
                        summary: summary,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  SellerDetailScreen(sellerId: summary.sellerId),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text(error.toString())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerSummaryCard extends StatelessWidget {
  const _SellerSummaryCard({required this.summary, required this.onTap});

  final SellerLedgerSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFFFFFCF7),
          border: Border.all(color: const Color(0xFFD9C3A2)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 16,
              offset: Offset(0, 8),
              color: Color(0x12000000),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.sellerName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(label: Text(summary.isActive ? 'Active' : 'Inactive')),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currency.format(summary.availableBalance),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${summary.activeBoxesCount} active box${summary.activeBoxesCount == 1 ? '' : 'es'}',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricBlock(
                    label: 'Active Boxes Total',
                    value: currency.format(summary.activeBoxesTotal),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricBlock(
                    label: 'Lifetime Sales',
                    value: currency.format(summary.lifetimeSales),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EBDD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
