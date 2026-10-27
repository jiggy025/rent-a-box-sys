import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/app_theme.dart';
import '../../models/dashboard_box_summary.dart';
import '../backups/backup_settings_screen.dart';
import '../boxes/box_detail_screen.dart';
import '../sellers/seller_detail_screen.dart';
import '../sellers/sellers_screen.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/database_provider.dart';
import 'widgets/add_box_sheet.dart';
import 'widgets/add_seller_sheet.dart';
import 'widgets/box_card.dart';
import 'widgets/dashboard_actions_sheet.dart';
import 'widgets/dashboard_guide_card.dart';
import 'widgets/dashboard_help_sheet.dart';
import 'widgets/reassign_box_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _openSheet(BuildContext context, Widget child) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => child,
    );
  }

  void _openHelpSheet(BuildContext context) {
    _openSheet(context, const DashboardHelpSheet());
  }

  Future<void> _dismissRefresher(WidgetRef ref) {
    return ref.read(databaseProvider).setDashboardRefresherDismissed(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardBoxes = ref.watch(filteredDashboardBoxesProvider);
    final allBoxes = ref.watch(dashboardBoxesProvider);
    final guideState = ref.watch(dashboardGuideStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BackupSettingsScreen()),
              );
            },
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: 'Backups',
          ),
          IconButton(
            onPressed: () => _openHelpSheet(context),
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SellersScreen()));
            },
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'Sellers',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _openSheet(
            context,
            DashboardActionsSheet(
              onAddSeller: () {
                Navigator.of(context).pop();
                _openSheet(context, const AddSellerSheet());
              },
              onAddBox: () {
                Navigator.of(context).pop();
                _openSheet(context, const AddBoxSheet());
              },
              onReassign: () {
                Navigator.of(context).pop();
                _openSheet(context, const ReassignBoxSheet());
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            guideState.when(
              data: (state) => state.showAnyGuideCard
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DashboardGuideCard(
                        state: state,
                        onOpenHelp: () => _openHelpSheet(context),
                        onDismissRefresher: () => _dismissRefresher(ref),
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search box number or seller',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  ref.read(dashboardSearchProvider.notifier).state = value,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: dashboardBoxes.when(
                data: (rows) => CustomScrollView(
                  slivers: [
                    // The day at a glance, from every box (not just the ones the search shows)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _DashboardSummary(
                          boxes: allBoxes.valueOrNull ?? rows,
                        ),
                      ),
                    ),
                    SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.08,
                  ),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final summary = rows[index];
                    return BoxCard(
                      summary: summary,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                BoxDetailScreen(boxId: summary.boxId),
                          ),
                        );
                      },
                      onSellerTap: () {
                        final sellerId = summary.sellerId;
                        if (sellerId == null) {
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SellerDetailScreen(sellerId: sellerId),
                          ),
                        );
                      },
                    );
                  },
                ),
                    // Room under the last row so the add button never covers a box
                    const SliverToBoxAdapter(child: SizedBox(height: 88)),
                  ],
                ),
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

/// Three numbers a cashier checks first: how many boxes are taken, how many are free,
/// and what the occupied boxes have sold so far.
class _DashboardSummary extends StatelessWidget {
  const _DashboardSummary({required this.boxes});

  final List<DashboardBoxSummary> boxes;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    var occupied = 0;
    var sales = 0.0;
    for (final box in boxes) {
      if (!box.isVacant) {
        occupied++;
        sales += box.total;
      }
    }
    final free = boxes.length - occupied;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(child: _Stat(label: 'Occupied', value: '$occupied of ${boxes.length}')),
            const _StatDivider(),
            Expanded(
              child: _Stat(label: 'Free', value: '$free', valueColor: free > 0 ? AppColors.vacant : null),
            ),
            const _StatDivider(),
            Expanded(flex: 2, child: _Stat(label: 'Sales in boxes', value: currency.format(sales))),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: tabularFigures,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: AppColors.line,
    );
  }
}
