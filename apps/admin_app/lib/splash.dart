import 'dart:async';
import 'package:flutter/material.dart';

/// Shows the branded splash image briefly at launch, then reveals [child].
/// The child is mounted underneath immediately, so its data loads during the
/// splash and there's no spinner gap once the splash lifts.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child});
  final Widget child;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!_done) const _SplashView(),
      ],
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    // Byline ("by BIKZ.DEV") is baked into the image itself.
    return Scaffold(
      backgroundColor: const Color(0xFF17452F),
      body: SizedBox.expand(
        child: Image.asset('assets/splash_admin.png', fit: BoxFit.cover),
      ),
    );
  }
}
