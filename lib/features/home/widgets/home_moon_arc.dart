import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A single twinkling star, with positions expressed as fractions of the
/// painting area so the field scales with the card.
class NightStar {
  const NightStar({
    required this.dxFraction,
    required this.dyFraction,
    required this.radius,
    required this.phase,
  });

  final double dxFraction;
  final double dyFraction;
  final double radius;
  final double phase;
}

/// Nighttime counterpart of [SunArcArea]: a moon rides the Maghrib→Fajr arc
/// over a calm starfield, with the last third of the night highlighted in gold.
class MoonArcArea extends StatefulWidget {
  const MoonArcArea({
    super.key,
    required this.progress,
    required this.isLastThird,
    required this.maghribLabel,
    required this.fajrLabel,
    required this.midnightLabel,
    required this.tahajjudLabel,
    required this.maghribClock,
    required this.fajrClock,
    required this.tahajjudClock,
    this.replayTick = 0,
  });

  final double progress;
  final bool isLastThird;
  final String maghribLabel;
  final String fajrLabel;
  final String midnightLabel;
  final String tahajjudLabel;
  final String maghribClock;
  final String fajrClock;
  final String tahajjudClock;

  /// Bumped by the host whenever the home screen becomes visible again (e.g.
  /// returning from another tab) to replay the Maghrib→now sweep.
  final int replayTick;

  @override
  State<MoonArcArea> createState() => _MoonArcAreaState();
}

class _MoonArcAreaState extends State<MoonArcArea>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _twinkleController;
  late final List<NightStar> _stars;

  static const Color _silver = Color(0xFFDCE7FF);
  static const Color _silverSoft = Color(0xFF8FA6D6);
  static const Color _indigo = Color(0xFF6E8BD8);
  static const Color _gold = Color(0xFFE9D8A6);

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    // Ease only the sweep's timing; the controller still settles exactly on
    // the true progress (a CurvedAnimation would distort the resting position).
    _progressController.animateTo(
      widget.progress.clamp(0.0, 1.0),
      curve: Curves.easeInOutCubic,
    );
    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    final random = math.Random(7);
    _stars = List<NightStar>.generate(16, (_) {
      return NightStar(
        dxFraction: random.nextDouble(),
        // Keep stars in the upper sky, away from the ground/labels.
        dyFraction: random.nextDouble() * 0.62,
        radius: 0.6 + random.nextDouble() * 1.4,
        phase: random.nextDouble() * math.pi * 2,
      );
    });
  }

  @override
  void didUpdateWidget(MoonArcArea old) {
    super.didUpdateWidget(old);
    if (old.replayTick != widget.replayTick) {
      _replay();
    } else if (!_progressController.isAnimating &&
        old.progress != widget.progress) {
      _progressController.value = widget.progress.clamp(0.0, 1.0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _twinkleController.dispose();
    super.dispose();
  }

  void _replay() {
    _progressController
      ..stop()
      ..value = 0.0
      ..animateTo(
        widget.progress.clamp(0.0, 1.0),
        curve: Curves.easeInOutCubic,
      );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _replay,
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: 2.7,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final cx = w / 2;
            final baseY = h - 6;
            final radius = math.min(w / 2 - 6, h - 14);
            final apexY = baseY - radius;

            return AnimatedBuilder(
              animation: Listenable.merge([
                _progressController,
                _twinkleController,
              ]),
              builder: (context, _) {
                final progress = _progressController.value.clamp(0.0, 1.0);
                final angle = math.pi * (1 - progress);
                final moonDx = cx + radius * math.cos(angle);
                final moonDy = baseY - radius * math.sin(angle);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: MoonArcPainter(
                          progress: progress,
                          twinkle: _twinkleController.value,
                          stars: _stars,
                          silver: _silver,
                          silverSoft: _silverSoft,
                          indigo: _indigo,
                          gold: _gold,
                          isLastThird: widget.isLastThird,
                        ),
                      ),
                    ),
                    Positioned(
                      left: cx,
                      top: apexY - 16.h,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, 0),
                        child: Text(
                          widget.midnightLabel,
                          style: TextStyle(
                            color: _silver,
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: moonDx,
                      top: moonDy,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, -0.5),
                        child: MoonMarker(
                          highlight: widget.isLastThird,
                          gold: _gold,
                          silver: _silver,
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0.32, -0.18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.tahajjudLabel,
                            style: TextStyle(
                              color: widget.isLastThird ? _gold : _silverSoft,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            widget.tahajjudClock,
                            style: TextStyle(
                              color: _silverSoft,
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: -2,
                      bottom: -2,
                      child: MoonEndpoint(
                        icon: Icons.brightness_3_rounded,
                        label: widget.maghribLabel,
                        time: widget.maghribClock,
                        color: _silver,
                        subColor: _silverSoft,
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: MoonEndpoint(
                        icon: Icons.wb_twilight_rounded,
                        label: widget.fajrLabel,
                        time: widget.fajrClock,
                        color: _silver,
                        subColor: _silverSoft,
                        alignRight: true,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class MoonMarker extends StatelessWidget {
  const MoonMarker({
    super.key,
    required this.highlight,
    required this.gold,
    required this.silver,
  });

  final bool highlight;
  final Color gold;
  final Color silver;

  @override
  Widget build(BuildContext context) {
    final base = highlight ? gold : silver;
    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: base,
        boxShadow: [
          BoxShadow(
            color: base.withValues(alpha: highlight ? 0.7 : 0.5),
            blurRadius: (highlight ? 18 : 12).r,
            spreadRadius: (highlight ? 2 : 1).r,
          ),
        ],
      ),
      child: Icon(
        Icons.nightlight_round,
        size: 13.sp,
        color: const Color(0xFF101A36),
      ),
    );
  }
}

class MoonEndpoint extends StatelessWidget {
  const MoonEndpoint({
    super.key,
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
    required this.subColor,
    this.alignRight = false,
  });

  final IconData icon;
  final String label;
  final String time;
  final Color color;
  final Color subColor;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12.sp, color: color),
            SizedBox(width: 3.w),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(
          time,
          style: TextStyle(
            color: subColor,
            fontSize: 9.5.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class MoonArcPainter extends CustomPainter {
  const MoonArcPainter({
    required this.progress,
    required this.twinkle,
    required this.stars,
    required this.silver,
    required this.silverSoft,
    required this.indigo,
    required this.gold,
    required this.isLastThird,
  });

  final double progress;
  final double twinkle;
  final List<NightStar> stars;
  final Color silver;
  final Color silverSoft;
  final Color indigo;
  final Color gold;
  final bool isLastThird;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final radius = math.min(w / 2 - 6, h - 14);
    final baseY = h - 6;
    final center = Offset(cx, baseY);

    // Twinkling stars across the upper sky.
    for (final star in stars) {
      final twinklePhase = math.sin(twinkle * 2 * math.pi + star.phase);
      final alpha = (0.35 + 0.45 * ((twinklePhase + 1) / 2)).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = silver.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(star.dxFraction * w, star.dyFraction * (baseY - 4)),
        star.radius,
        paint,
      );
    }

    // Dashed arc track.
    final dashedTrack = Paint()
      ..color = silverSoft.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    const dashCount = 56;
    for (var i = 0; i < dashCount; i++) {
      if (i.isOdd) continue;
      final t = i / dashCount;
      final angle = math.pi - (math.pi * t);
      final p1 = Offset(
        center.dx + (radius - 2) * math.cos(angle),
        center.dy - (radius - 2) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius + 2) * math.cos(angle),
        center.dy - (radius + 2) * math.sin(angle),
      );
      canvas.drawLine(p1, p2, dashedTrack);
    }

    // Filled arc up to the current night progress.
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final filledSweep = math.pi * progress.clamp(0.0, 1.0);
    final filledPaint = Paint()
      ..shader = LinearGradient(
        colors: [indigo, silver],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, math.pi, filledSweep, false, filledPaint);

    // Ground line.
    final ground = Paint()
      ..color = silverSoft.withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(8, baseY), Offset(w - 8, baseY), ground);

    // Tahajjud onset marker at two-thirds of the night.
    const tahajjudFraction = 2 / 3;
    final tahajjudAngle = math.pi * (1 - tahajjudFraction);
    final tickInner = Offset(
      center.dx + (radius - 5) * math.cos(tahajjudAngle),
      center.dy - (radius - 5) * math.sin(tahajjudAngle),
    );
    final tickOuter = Offset(
      center.dx + (radius + 5) * math.cos(tahajjudAngle),
      center.dy - (radius + 5) * math.sin(tahajjudAngle),
    );
    final tickPaint = Paint()
      ..color = gold.withValues(alpha: isLastThird ? 1 : 0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tickInner, tickOuter, tickPaint);
  }

  @override
  bool shouldRepaint(covariant MoonArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.twinkle != twinkle ||
      oldDelegate.isLastThird != isLastThird;
}
