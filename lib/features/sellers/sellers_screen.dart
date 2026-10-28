import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/app_theme.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final boxes = summary.activeBoxesCount;

    // Same card language as the dashboard: white card, the balance set large, details quiet below
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      summary.sellerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ActivePill(active: summary.isActive),
                ],
              ),
              const SizedBox(height: 12),
              Text('Available balance', style: textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                currency.format(summary.availableBalance),
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$boxes active box${boxes == 1 ? '' : 'es'}',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  Text('Lifetime Sales', style: textTheme.bodySmall),
                  const SizedBox(width: 8),
                  Text(
                    currency.format(summary.lifetimeSales),
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.ink,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivePill extends StatelessWidget {
  const _ActivePill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? AppColors.vacantSoft : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? AppColors.vacant.withValues(alpha: 0.35) : AppColors.line),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: active ? AppColors.vacant : AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
