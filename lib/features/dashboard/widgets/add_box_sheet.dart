import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/database_provider.dart';

class AddBoxSheet extends ConsumerStatefulWidget {
  const AddBoxSheet({super.key});

  @override
  ConsumerState<AddBoxSheet> createState() => _AddBoxSheetState();
}

class _AddBoxSheetState extends ConsumerState<AddBoxSheet> {
  final _formKey = GlobalKey<FormState>();
  final _boxController = TextEditingController();

  @override
  void dispose() {
    _boxController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await ref
          .read(databaseProvider)
          .createBox(boxNumber: _boxController.text.trim());
      ref.read(refreshTickProvider.notifier).state++;
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That box number already exists.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            TextFormField(
              controller: _boxController,
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
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Save Box')),
          ],
        ),
      ),
    );
  }
}
