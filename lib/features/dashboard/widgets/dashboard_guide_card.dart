import 'package:flutter/material.dart';

import '../../../models/dashboard_guide_state.dart';

class DashboardGuideCard extends StatelessWidget {
  const DashboardGuideCard({
    required this.state,
    required this.onOpenHelp,
    super.key,
  });

  static const setupSteps = <String>[
    '1. Add seller',
    '2. Add box',
    '3. Occupy vacant box',
    '4. Tap box to add sales',
    '5. Manage seller payouts',
  ];

  final DashboardGuideState state;
  final VoidCallback onOpenHelp;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: const Color(0xFFFFF8EE),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: state.isSetupComplete
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need a quick refresher?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dashboard setup complete',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _CountChip(label: 'Sellers', value: state.sellerCount),
                      _CountChip(label: 'Boxes', value: state.activeBoxCount),
                      _CountChip(
                        label: 'Assignments',
                        value: state.activeAssignmentCount,
                      ),
                      _CountChip(label: 'Sales', value: state.logEntryCount),
                      _CountChip(
                        label: 'Payouts',
                        value: state.sellerAdjustmentCount,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: onOpenHelp,
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Open help'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get your dashboard ready',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Follow these steps to start tracking sellers, boxes, and payouts from the dashboard.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final step in setupSteps) ...[
                    Text(step, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: onOpenHelp,
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Open help'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7D5BE)),
      ),
      child: Text('$label: $value'),
    );
  }
}
