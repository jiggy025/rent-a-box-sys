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
    return Scaffold(
      backgroundColor: const Color(0xFFF1E4D2),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: const Color(0xFFF1E4D2),
            child: Image.asset(
              'assets/branding/espasyo.png',
              key: const Key('espasyo-splash-image'),
              fit: BoxFit.contain,
              alignment: Alignment.center,
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    key: const Key('espasyo-splash-loader'),
                    tween: Tween(begin: 0, end: 1),
                    duration: _transitionDelay,
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 5,
                        backgroundColor: const Color(0x40FFFFFF),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF8B5E34),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
