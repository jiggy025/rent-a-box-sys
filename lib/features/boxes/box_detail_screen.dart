import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/app_theme.dart';
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
    final textTheme = Theme.of(context).textTheme;
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
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppColors.vacantSoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.vacant,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (summary != null) ...[
                          Text(
                            'BOX ${summary.boxNumber}',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Vacant',
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.vacant,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          'This box is currently vacant.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => _openOccupySheet(summary),
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Occupy this vacant box'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          final totalAsync = ref.watch(assignmentTotalProvider(assignment.id));
          final entriesAsync = ref.watch(
            assignmentEntriesProvider(assignment.id),
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              // 1. Whose box this is and what it has sold
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (summary != null) ...[
                        Text(
                          'BOX ${summary.boxNumber}',
                          style: textTheme.titleLarge?.copyWith(
                            fontFeatures: tabularFigures,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 18,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                summary.sellerName ?? 'Vacant',
                                style: textTheme.bodyLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                      ],
                      Text('Sales in this box', style: textTheme.bodySmall),
                      const SizedBox(height: 4),
                      totalAsync.when(
                        data: (total) => FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            currency.format(total),
                            style: textTheme.headlineLarge,
                          ),
                        ),
                        loading: () => const SizedBox(height: 40),
                        error: (error, stack) => Text(error.toString()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Log a sale: three fields, top to bottom in the order the cashier asks for them
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Log a sale', style: textTheme.titleMedium),
                        const SizedBox(height: 16),
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
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            prefixText: 'PHP ',
                          ),
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
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => _submit(assignment.id),
                          child: const Text('Add Entry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3. The log itself, newest first as the database returns it
              entriesAsync.when(
                data: (entries) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Sales log', style: textTheme.titleMedium),
                          ),
                          Text(
                            entries.length == 1 ? '1 entry' : '${entries.length} entries',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: entries.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'No sales yet. Log the first one above.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                for (var i = 0; i < entries.length; i++) ...[
                                  if (i > 0) const Divider(indent: 16, endIndent: 16),
                                  ListTile(
                                    title: Text(
                                      entries[i].itemName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodyLarge?.copyWith(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      entries[i].claimerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Text(
                                      currency.format(entries[i].price),
                                      style: textTheme.titleMedium?.copyWith(
                                        fontFeatures: tabularFigures,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text(error.toString()),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
      ),
    );
  }
}
