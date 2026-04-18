import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/dashboard_providers.dart';
import 'widgets/add_box_sheet.dart';
import 'widgets/add_seller_sheet.dart';
import 'widgets/box_card.dart';
import 'widgets/dashboard_actions_sheet.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardBoxes = ref.watch(filteredDashboardBoxesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
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
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search box or seller',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  ref.read(dashboardSearchProvider.notifier).state = value,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: dashboardBoxes.when(
                data: (rows) => GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.84,
                  ),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final summary = rows[index];
                    return BoxCard(
                      summary: summary,
                      onTap: () {},
                      onSellerTap: () {},
                    );
                  },
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
