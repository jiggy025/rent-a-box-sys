import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();
  final _claimerController = TextEditingController();
  final _itemFocusNode = FocusNode();
  final _priceFocusNode = FocusNode();
  final _claimerFocusNode = FocusNode();

  @override
  void dispose() {
    _itemController.dispose();
    _priceController.dispose();
    _claimerController.dispose();
    _itemFocusNode.dispose();
    _priceFocusNode.dispose();
    _claimerFocusNode.dispose();
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

  String _normalizedSingleLine(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(databaseProvider)
        .addLogEntry(
          rentalAssignmentId: assignmentId,
          itemName: _normalizedSingleLine(_itemController.text),
          price: double.parse(_priceController.text.trim()),
          claimerName: _normalizedSingleLine(_claimerController.text),
        );

    _itemController.clear();
    _priceController.clear();
    _claimerController.clear();
    ref.read(refreshTickProvider.notifier).state++;
    _itemFocusNode.requestFocus();
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
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        key: const Key('item-name'),
                        controller: _itemController,
                        focusNode: _itemFocusNode,
                        maxLines: 1,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'[\r\n]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Item name',
                        ),
                        onFieldSubmitted: (_) {
                          _priceFocusNode.requestFocus();
                        },
                        validator: (value) {
                          if (_normalizedSingleLine(value ?? '').isEmpty) {
                            return 'Enter an item name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('item-price'),
                        controller: _priceController,
                        focusNode: _priceFocusNode,
                        maxLines: 1,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        decoration: const InputDecoration(labelText: 'Price'),
                        onFieldSubmitted: (_) {
                          _claimerFocusNode.requestFocus();
                        },
                        validator: (value) {
                          final input = value?.trim() ?? '';
                          if (input.isEmpty) {
                            return 'Enter a price.';
                          }
                          if (double.tryParse(input) == null) {
                            return 'Enter numbers only.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('claimer-name'),
                        controller: _claimerController,
                        focusNode: _claimerFocusNode,
                        maxLines: 1,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'[\r\n]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Claimer name',
                        ),
                        onFieldSubmitted: (_) => _submit(assignment.id),
                        validator: (value) {
                          if (_normalizedSingleLine(value ?? '').isEmpty) {
                            return 'Enter a claimer name.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
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
                          title: Text(
                            entry.itemName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            entry.claimerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
