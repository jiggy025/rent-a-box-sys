import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/app_database.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/seller_providers.dart';

class ReassignBoxSheet extends ConsumerStatefulWidget {
  const ReassignBoxSheet({
    super.key,
    this.initialBoxId,
    this.initialBoxNumber,
    this.lockBoxNumber = false,
    this.title = 'Reassign Box',
    this.confirmLabel = 'Confirm Reassignment',
  });

  final String? initialBoxId;
  final String? initialBoxNumber;
  final bool lockBoxNumber;
  final String title;
  final String confirmLabel;

  @override
  ConsumerState<ReassignBoxSheet> createState() => _ReassignBoxSheetState();
}

class _ReassignBoxSheetState extends ConsumerState<ReassignBoxSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _boxNumberController = TextEditingController(
    text: widget.initialBoxNumber ?? '',
  );
  String? _selectedSellerId;

  @override
  void dispose() {
    _boxNumberController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final sellerId = _selectedSellerId;
    if (sellerId == null) {
      return;
    }

    final db = ref.read(databaseProvider);
    final boxId =
        widget.initialBoxId ??
        (await db.boxByNumber(_boxNumberController.text.trim()))?.id;

    if (boxId == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Box not found.')));
      return;
    }

    await db.reassignBox(boxId: boxId, nextSellerId: sellerId);
    ref.read(refreshTickProvider.notifier).state++;
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildSellerDropdown(List<Seller> sellers) {
    if (sellers.isEmpty) {
      return const Text('Add a seller first before assigning this box.');
    }

    return DropdownButtonFormField<String>(
      key: const Key('reassign-seller-dropdown'),
      initialValue: _selectedSellerId,
      decoration: const InputDecoration(labelText: 'Seller'),
      items: [
        for (final seller in sellers)
          DropdownMenuItem<String>(
            value: seller.id,
            child: Text(
              seller.isActive ? seller.name : '${seller.name} (inactive)',
            ),
          ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedSellerId = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Select a seller.';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sellersAsync = ref.watch(allSellersProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: sellersAsync.when(
        data: (sellers) => Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (widget.lockBoxNumber && widget.initialBoxNumber != null) ...[
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Box number'),
                  child: Text(widget.initialBoxNumber!),
                ),
                const SizedBox(height: 12),
              ] else ...[
                TextFormField(
                  key: const Key('reassign-box-number'),
                  controller: _boxNumberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Box number'),
                  validator: (value) {
                    final input = value?.trim() ?? '';
                    if (input.isEmpty || !RegExp(r'^\d+$').hasMatch(input)) {
                      return 'Enter a numeric box number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],
              _buildSellerDropdown(sellers),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: sellers.isEmpty ? null : _confirm,
                child: Text(widget.confirmLabel),
              ),
            ],
          ),
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(error.toString()),
        ),
      ),
    );
  }
}
