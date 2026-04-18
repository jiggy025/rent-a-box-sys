import 'package:flutter/material.dart';

import 'app_theme.dart';

class RentABoxApp extends StatelessWidget {
  const RentABoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rent-a-Box Ledger',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const Scaffold(
        body: Center(
          child: Text('Rent-a-Box Ledger'),
        ),
      ),
    );
  }
}
