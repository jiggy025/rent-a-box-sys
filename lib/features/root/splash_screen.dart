import 'dart:async';

import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';

class EspasyoSplashScreen extends StatefulWidget {
  const EspasyoSplashScreen({super.key});

  @override
  State<EspasyoSplashScreen> createState() => _EspasyoSplashScreenState();
}

class _EspasyoSplashScreenState extends State<EspasyoSplashScreen> {
  static const _transitionDelay = Duration(milliseconds: 1800);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_transitionDelay, _goToDashboard);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goToDashboard() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1E8),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/branding/espasyo.png',
                  width: 240,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                Text(
                  'Espasyo',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6D4321),
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Preparing your dashboard',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF8D6B4A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
