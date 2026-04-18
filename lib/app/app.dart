import 'package:flutter/material.dart';

import '../features/root/root_gate.dart';
import 'app_theme.dart';

class RentABoxApp extends StatelessWidget {
  const RentABoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rent-a-Box Ledger',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const RootGate(),
    );
  }
}
