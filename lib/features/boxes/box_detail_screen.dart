import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../dashboard/widgets/reassign_box_sheet.dart';
import '../../models/dashboard_box_summary.dart';
import '../../providers/box_detail_providers.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/database_provider.dart';

class BoxDetailScreen extends ConsumerStatefulWidget {
  const BoxDetailScreen({super.key, required this.boxId});

  final String boxId;

  @override
  ConsumerState<BoxDetailScreen> createState() => _BoxDetailScreenState();
}

class _BoxDetailScreenState extends ConsumerState<BoxDetailScreen> {
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();
  final _claimerController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    _priceController.dispose();
    _claimerController.dispose();
    super.dispose();
  }

  DashboardBoxSummary? _summaryForBox(List<DashboardBoxSummary> rows) {
    for (final row in rows) {
      if (row.boxId == widget.boxId) {
        return row;
      }
    }
    return null;
  }

  void _openOccupySheet(DashboardBoxSummary? summary) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReassignBoxSheet(
        initialBoxId: widget.boxId,
        initialBoxNumber: summary?.boxNumber,
        lockBoxNumber: true,
        title: 'Occupy Box',
        confirmLabel: 'Occupy Box',
      ),
    );
  }

  Future<void> _submit(String assignmentId) async {
    await ref
        .read(databaseProvider)
        .addLogEntry(
          rentalAssignmentId: assignmentId,
          itemName: _itemController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          claimerName: _claimerController.text.trim(),
        );

    _itemController.clear();
    _priceController.clear();
    _claimerController.clear();
    ref.read(refreshTickProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    final assignmentAsync = ref.watch(
      activeAssignmentForBoxProvider(widget.boxId),
    );
    final dashboardAsync = ref.watch(dashboardBoxesProvider);
    final summary = _summaryForBox(
      dashboardAsync.valueOrNull ?? const <DashboardBoxSummary>[],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Box Detail')),
      body: assignmentAsync.when(
        data: (assignment) {
          if (assignment == null) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (summary != null) ...[
                    Text(
                      'BOX ${summary.boxNumber}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vacant',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'This box is currently vacant.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _openOccupySheet(summary),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Occupy this vacant box'),
                  ),
                ],
              ),
            );
          }

          final totalAsync = ref.watch(assignmentTotalProvider(assignment.id));
          final entriesAsync = ref.watch(
            assignmentEntriesProvider(assignment.id),
          );

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (summary != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'BOX ${summary.boxNumber}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(summary.sellerName ?? 'Vacant'),
                  ),
                  const SizedBox(height: 12),
                ],
                totalAsync.when(
                  data: (total) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      currency.format(total),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => Text(error.toString()),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('item-name'),
                  controller: _itemController,
                  decoration: const InputDecoration(labelText: 'Item name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('item-price'),
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('claimer-name'),
                  controller: _claimerController,
                  decoration: const InputDecoration(labelText: 'Claimer name'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _submit(assignment.id),
                  child: const Text('Add Entry'),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: entriesAsync.when(
                    data: (entries) => ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return ListTile(
                          title: Text(entry.itemName),
                          subtitle: Text(entry.claimerName),
                          trailing: Text(currency.format(entry.price)),
                        );
                      },
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Text(error.toString()),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
      ),
    );
  }
}
