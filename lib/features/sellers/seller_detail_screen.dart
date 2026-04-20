import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/seller_adjustment_type.dart';
import '../../models/seller_history_record.dart';
import '../../models/seller_transaction_record.dart';
import '../../providers/database_provider.dart';
import '../../providers/seller_providers.dart';

class SellerDetailScreen extends ConsumerWidget {
  const SellerDetailScreen({super.key, required this.sellerId});

  final String sellerId;

  Future<void> _openAdjustmentSheet(
    BuildContext context,
    SellerAdjustmentType type,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SellerAdjustmentSheet(
        sellerId: sellerId,
        type: type,
      ),
    );
  }

  Future<void> _confirmMarkInactive(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark seller inactive?'),
        content: const Text(
          'This will close all active boxes for this seller and make them vacant.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(databaseProvider).markSellerInactive(sellerId);
    ref.read(refreshTickProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    final summaryAsync = ref.watch(sellerLedgerSummaryProvider(sellerId));
    final activeBoxesAsync = ref.watch(sellerActiveBoxesProvider(sellerId));
    final transactionsAsync = ref.watch(sellerTransactionHistoryProvider(sellerId));
    final historyAsync = ref.watch(sellerHistoryProvider(sellerId));

    return Scaffold(
      appBar: AppBar(
        title: Text(summaryAsync.valueOrNull?.sellerName ?? 'Seller Detail'),
      ),
      body: summaryAsync.when(
        data: (summary) {
          if (summary == null) {
            return const Center(child: Text('Seller not found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                summary.sellerName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryPanel(
                    label: 'Available Balance',
                    value: currency.format(summary.availableBalance),
                    valueKey: const Key('seller-available-balance-value'),
                  ),
                  _SummaryPanel(
                    label: 'Lifetime Sales',
                    value: currency.format(summary.lifetimeSales),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    onPressed: () => _openAdjustmentSheet(
                      context,
                      SellerAdjustmentType.cashOut,
                    ),
                    child: const Text('Cash Out'),
                  ),
                  OutlinedButton(
                    onPressed: () => _openAdjustmentSheet(
                      context,
                      SellerAdjustmentType.manualDeduction,
                    ),
                    child: const Text('Manual Deduction'),
                  ),
                  OutlinedButton(
                    onPressed: () => _confirmMarkInactive(context, ref),
                    child: const Text('Mark Inactive'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionCard(
                title: 'Active Boxes',
                child: activeBoxesAsync.when(
                  data: (boxes) {
                    if (boxes.isEmpty) {
                      return const Text('No active boxes.');
                    }

                    return Column(
                      children: [
                        for (final box in boxes)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Box ${box.boxNumber}'),
                            subtitle: const Text('Currently occupied'),
                            trailing: Text(currency.format(box.total)),
                          ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text(error.toString()),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Transaction History',
                child: transactionsAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return const Text('No transactions yet.');
                    }

                    return Column(
                      children: [
                        for (final entry in transactions)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(entry.title),
                            subtitle: Text(_transactionSubtitle(entry)),
                            trailing: Text(
                              '${entry.amount >= 0 ? '+' : '-'}${currency.format(entry.amount.abs())}',
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text(error.toString()),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Assignment History',
                child: historyAsync.when(
                  data: (history) {
                    if (history.isEmpty) {
                      return const Text('No assignment history yet.');
                    }

                    return Column(
                      children: [
                        for (final record in history)
                          _HistoryTile(
                            record: record,
                            currency: currency,
                          ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text(error.toString()),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
      ),
    );
  }

  String _transactionSubtitle(SellerTransactionRecord entry) {
    final details = <String>[];
    if (entry.boxNumber != null) {
      details.add('Box ${entry.boxNumber}');
    }
    if (entry.detail != null && entry.detail!.trim().isNotEmpty) {
      details.add(entry.detail!.trim());
    }
    if (details.isEmpty) {
      return 'Recorded transaction';
    }
    return details.join(' • ');
  }
}

class SellerAdjustmentSheet extends ConsumerStatefulWidget {
  const SellerAdjustmentSheet({
    super.key,
    required this.sellerId,
    required this.type,
  });

  final String sellerId;
  final SellerAdjustmentType type;

  @override
  ConsumerState<SellerAdjustmentSheet> createState() =>
      _SellerAdjustmentSheetState();
}

class _SellerAdjustmentSheetState extends ConsumerState<SellerAdjustmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  bool get _requiresReason =>
      widget.type == SellerAdjustmentType.manualDeduction;

  String get _title => widget.type == SellerAdjustmentType.cashOut
      ? 'Cash Out'
      : 'Manual Deduction';

  String get _confirmLabel => widget.type == SellerAdjustmentType.cashOut
      ? 'Confirm Cash Out'
      : 'Confirm Deduction';

  Future<void> _submit(double availableBalance) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    if (amount > availableBalance) {
      return;
    }

    await ref.read(databaseProvider).createSellerAdjustment(
          sellerId: widget.sellerId,
          type: widget.type,
          amount: amount,
          reason: _reasonController.text.trim(),
        );
    ref.read(refreshTickProvider.notifier).state++;
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(sellerLedgerSummaryProvider(widget.sellerId));

    return summaryAsync.when(
      data: (summary) {
        final availableBalance = summary?.availableBalance ?? 0;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Available balance: ${NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2).format(availableBalance)}',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('seller-adjustment-amount'),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(labelText: 'Amount'),
                  validator: (value) {
                    final input = value?.trim() ?? '';
                    if (input.isEmpty) {
                      return 'Enter an amount.';
                    }
                    final amount = double.tryParse(input);
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount.';
                    }
                    if (amount > availableBalance) {
                      return 'Amount exceeds available balance.';
                    }
                    return null;
                  },
                ),
                if (_requiresReason) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('seller-adjustment-reason'),
                    controller: _reasonController,
                    decoration: const InputDecoration(labelText: 'Reason'),
                    validator: (value) {
                      if (!_requiresReason) {
                        return null;
                      }
                      if ((value ?? '').trim().isEmpty) {
                        return 'Enter a reason.';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _submit(availableBalance),
                  child: Text(_confirmLabel),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(error.toString()),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.label,
    required this.value,
    this.valueKey,
  });

  final String label;
  final String value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD9C3A2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                value,
                key: valueKey,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9C3A2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record, required this.currency});

  final SellerHistoryRecord record;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('Box ${record.boxNumber}'),
      subtitle: Text(record.isActive ? 'Active assignment' : 'Past assignment'),
      trailing: Text(currency.format(record.total)),
    );
  }
}
