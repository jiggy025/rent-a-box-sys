import 'package:flutter/material.dart';

import 'app_theme.dart';
import '../features/root/splash_screen.dart';

class RentABoxApp extends StatelessWidget {
  const RentABoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rent-a-Box Ledger',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const EspasyoSplashScreen(),
    );
  }
}
