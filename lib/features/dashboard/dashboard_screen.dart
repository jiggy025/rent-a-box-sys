import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/dashboard_providers.dart';
import 'widgets/box_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardBoxes = ref.watch(filteredDashboardBoxesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
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
