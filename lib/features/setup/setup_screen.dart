import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_provider.dart';
import '../dashboard/dashboard_screen.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _sellerController = TextEditingController();
  final _boxController = TextEditingController();
  int _step = 0;
  bool _saving = false;

  @override
  void dispose() {
    _sellerController.dispose();
    _boxController.dispose();
    super.dispose();
  }

  Future<void> _finishSetup() async {
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);

    final sellerId = await db.createSeller(name: _sellerController.text.trim());
    final boxId = await db.createBox(boxNumber: _boxController.text.trim());
    await db.createRentalAssignment(sellerId: sellerId, boxId: boxId);

    ref.read(refreshTickProvider.notifier).state++;

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_step) {
      0 => 'Set up your first seller',
      1 => 'Create your first box',
      _ => 'Review your first assignment',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('First Launch Setup')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            if (_step == 0)
              TextField(
                key: const Key('seller-name'),
                controller: _sellerController,
                decoration: const InputDecoration(labelText: 'Seller name'),
              ),
            if (_step == 1)
              TextField(
                key: const Key('box-number'),
                controller: _boxController,
                decoration: const InputDecoration(labelText: 'Box number'),
              ),
            if (_step == 2)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Seller: ${_sellerController.text}'),
                      const SizedBox(height: 8),
                      Text('Box: ${_boxController.text}'),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () {
                      if (_step < 2) {
                        setState(() => _step += 1);
                      } else {
                        _finishSetup();
                      }
                    },
              child: Text(_step < 2 ? 'Next' : 'Finish Setup'),
            ),
          ],
        ),
      ),
    );
  }
}
