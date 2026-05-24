import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.9, -0.9),
          radius: 1.5,
          colors: isDark
              ? const [Color(0xFF153A4C), Color(0xFF0A1620)]
              : const [Color(0xFFD6ECF4), Color(0xFFF7FBFD)],
          stops: const [0.0, 0.78],
        ),
      ),
      child: child,
    );
  }
}
