import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/app_theme.dart';
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
    final textTheme = Theme.of(context).textTheme;
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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              // 1. The money: what can be paid out now, and everything sold to date
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(summary.sellerName, style: textTheme.titleLarge),
                      const SizedBox(height: 20),
                      Text('Available Balance', style: textTheme.bodySmall),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          currency.format(summary.availableBalance),
                          key: const Key('seller-available-balance-value'),
                          style: textTheme.headlineLarge,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('Lifetime Sales', style: textTheme.bodyMedium),
                            ),
                            Text(
                              currency.format(summary.lifetimeSales),
                              style: textTheme.titleMedium?.copyWith(
                                fontFeatures: tabularFigures,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Actions: paying out is the everyday one, so it is the one filled button
              FilledButton.icon(
                onPressed: () => _openAdjustmentSheet(
                  context,
                  SellerAdjustmentType.cashOut,
                ),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Cash Out'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _openAdjustmentSheet(
                        context,
                        SellerAdjustmentType.manualDeduction,
                      ),
                      child: const Text('Manual Deduction'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                      onPressed: () => _confirmMarkInactive(context, ref),
                      child: const Text('Mark Inactive'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 3. Records
              _SectionCard(
                title: 'Active Boxes',
                child: activeBoxesAsync.when(
                  data: (boxes) {
                    if (boxes.isEmpty) {
                      return const _EmptyRow('No active boxes.');
                    }
                    return _Rows(
                      children: [
                        for (final box in boxes)
                          ListTile(
                            title: Text('Box ${box.boxNumber}'),
                            subtitle: const Text('Currently occupied'),
                            trailing: _Money(currency.format(box.total)),
                          ),
                      ],
                    );
                  },
                  loading: () => const _LoadingRow(),
                  error: (error, stack) => _EmptyRow(error.toString()),
                ),
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Transaction History',
                child: transactionsAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return const _EmptyRow('No transactions yet.');
                    }
                    return _Rows(
                      children: [
                        for (final entry in transactions)
                          ListTile(
                            title: Text(entry.title),
                            subtitle: Text(_transactionSubtitle(entry)),
                            trailing: _Money(
                              '${entry.amount >= 0 ? '+' : '-'}${currency.format(entry.amount.abs())}',
                              color: entry.amount >= 0 ? AppColors.vacant : AppColors.ink,
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const _LoadingRow(),
                  error: (error, stack) => _EmptyRow(error.toString()),
                ),
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Assignment History',
                child: historyAsync.when(
                  data: (history) {
                    if (history.isEmpty) {
                      return const _EmptyRow('No assignment history yet.');
                    }
                    return _Rows(
                      children: [
                        for (final record in history)
                          _HistoryTile(
                            record: record,
                            currency: currency,
                          ),
                      ],
                    );
                  },
                  loading: () => const _LoadingRow(),
                  error: (error, stack) => _EmptyRow(error.toString()),
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

/// A titled group of records: the title sits above a white card of rows.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Card(child: child),
      ],
    );
  }
}

/// List rows separated by inset hairlines, the way a receipt separates lines.
class _Rows extends StatelessWidget {
  const _Rows({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(indent: 16, endIndent: 16),
          children[i],
        ],
      ],
    );
  }
}

class _Money extends StatelessWidget {
  const _Money(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFeatures: tabularFigures,
            color: color,
          ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
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
      title: Text('Box ${record.boxNumber}'),
      subtitle: Text(record.isActive ? 'Active assignment' : 'Past assignment'),
      trailing: _Money(currency.format(record.total)),
    );
  }
}
