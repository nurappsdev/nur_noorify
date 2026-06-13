import 'dart:math' as math;

import 'package:flutter/material.dart';

class MiniCompassMarksPainter extends CustomPainter {
  const MiniCompassMarksPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final majorTickPaint = Paint()
      ..color = isDark ? const Color(0xFF8AA4B8) : const Color(0xFF6A8EA4)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final minorTickPaint = Paint()
      ..color = isDark ? const Color(0xFF9CB3C3) : const Color(0xFF86A5B9)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 36; i++) {
      final angle = (i * 10) * math.pi / 180;
      final major = i % 3 == 0;
      final inner = radius - (major ? 9 : 5);
      final p1 = Offset(
        center.dx + inner * math.sin(angle),
        center.dy - inner * math.cos(angle),
      );
      final p2 = Offset(
        center.dx + (radius - 2) * math.sin(angle),
        center.dy - (radius - 2) * math.cos(angle),
      );
      canvas.drawLine(p1, p2, major ? majorTickPaint : minorTickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MiniCompassMarksPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class MiniQiblaNeedlePainter extends CustomPainter {
  const MiniQiblaNeedlePainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const tipY = 13.0;
    final needleColor = isDark
        ? const Color(0xFF21D6C2)
        : const Color(0xFF1EA8B8);

    final glowPaint = Paint()
      ..color = isDark ? const Color(0x6621D6C2) : const Color(0x551EA8B8)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final linePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, Offset(center.dx, tipY + 10), glowPaint);
    canvas.drawLine(center, Offset(center.dx, tipY + 10), linePaint);

    final arrow = Path()
      ..moveTo(center.dx, tipY)
      ..lineTo(center.dx - 4.8, tipY + 8)
      ..lineTo(center.dx + 4.8, tipY + 8)
      ..close();
    canvas.drawPath(arrow, Paint()..color = needleColor);
  }

  @override
  bool shouldRepaint(covariant MiniQiblaNeedlePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class MiniKaabaMarker extends StatelessWidget {
  const MiniKaabaMarker({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF0F1E2A) : const Color(0xFFEAF3F9),
        border: Border.all(
          color: isDark ? const Color(0x66FFFFFF) : const Color(0xFFBDD2E2),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x5521D6C2) : const Color(0x331EA8B8),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: ClipOval(
        child: Image.asset(
          'assets/kakbah.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.location_on_rounded,
              size: 14,
              color: isDark ? const Color(0xFF21D6C2) : const Color(0xFF1EA8B8),
            );
          },
        ),
      ),
    );
  }
}
