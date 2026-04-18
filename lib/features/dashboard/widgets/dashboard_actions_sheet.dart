import 'package:flutter/material.dart';

class DashboardActionsSheet extends StatelessWidget {
  const DashboardActionsSheet({
    super.key,
    required this.onAddSeller,
    required this.onAddBox,
    required this.onReassign,
  });

  final VoidCallback onAddSeller;
  final VoidCallback onAddBox;
  final VoidCallback onReassign;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.person_add_alt_1),
            title: const Text('Add Seller'),
            onTap: onAddSeller,
          ),
          ListTile(
            leading: const Icon(Icons.add_box_outlined),
            title: const Text('Add Box'),
            onTap: onAddBox,
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Reassign Box'),
            onTap: onReassign,
          ),
        ],
      ),
    );
  }
}
