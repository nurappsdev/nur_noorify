import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Daytime sun-path arc for the home hero card. A sun rides the Fajr→Maghrib
/// arc with shoulder labels and endpoint clocks, all supplied via constructor
/// so the widget stays free of screen state.
class SunArcArea extends StatefulWidget {
  const SunArcArea({
    super.key,
    required this.currentProgress,
    required this.isBangla,
    required this.accentStrong,
    required this.accentSoft,
    required this.accentGold,
    required this.trackColor,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.leadingTitle,
    required this.leadingTimeLabel,
    required this.trailingTitle,
    required this.trailingTimeLabel,
    required this.sunriseClockText,
    required this.sunsetClockText,
    required this.middayTimeLabel,
  });

  final double currentProgress;
  final bool isBangla;
  final Color accentStrong;
  final Color accentSoft;
  final Color accentGold;
  final Color trackColor;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final String leadingTitle;
  final String leadingTimeLabel;
  final String trailingTitle;
  final String trailingTimeLabel;
  final String sunriseClockText;
  final String sunsetClockText;
  final String middayTimeLabel;

  @override
  State<SunArcArea> createState() => _SunArcAreaState();
}

class _SunArcAreaState extends State<SunArcArea>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.value = widget.currentProgress.clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(SunArcArea old) {
    super.didUpdateWidget(old);
    if (!_controller.isAnimating &&
        old.currentProgress != widget.currentProgress) {
      _controller.value = widget.currentProgress.clamp(0.0, 1.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _replay() {
    _controller.stop();
    _controller.value = 0.0;
    _controller.animateTo(widget.currentProgress.clamp(0.0, 1.0));
  }

  double _sunIconScale(double progress) {
    // Sun appears largest near the apex (midday), smaller near the horizon.
    final fromCenter = (progress - 0.5).abs() * 2; // 0 at apex, 1 at edges
    return 1.0 + (1.0 - fromCenter) * 0.55;
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
              animation: _animation,
              builder: (context, _) {
                final progress = _animation.value.clamp(0.0, 1.0);
                final angle = math.pi * (1 - progress);
                final sunDx = cx + radius * math.cos(angle);
                final sunDy = baseY - radius * math.sin(angle);
                final iconScale = _sunIconScale(progress);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: SunArcPainter(
                          progress: progress,
                          accentStrong: widget.accentStrong,
                          accentSoft: widget.accentSoft,
                          accentGold: widget.accentGold,
                          trackColor: widget.trackColor,
                          isDark: widget.isDark,
                        ),
                      ),
                    ),
                    Positioned(
                      left: cx,
                      top: apexY - 16,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, 0),
                        child: Text(
                          widget.middayTimeLabel,
                          style: TextStyle(
                            color: widget.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: sunDx,
                      top: sunDy,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, -0.5),
                        child: SunIconMarker(
                          color: widget.accentGold,
                          scale: iconScale,
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(-0.55, -0.15),
                      child: ArcLabel(
                        title: widget.leadingTitle,
                        time: widget.leadingTimeLabel,
                        titleColor: widget.textPrimary,
                        timeColor: widget.textSecondary,
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0.55, -0.15),
                      child: ArcLabel(
                        title: widget.trailingTitle,
                        time: widget.trailingTimeLabel,
                        titleColor: widget.textPrimary,
                        timeColor: widget.textSecondary,
                        trailing: Icon(
                          Icons.check_circle_rounded,
                          size: 11,
                          color: widget.accentStrong,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -2,
                      bottom: -2,
                      child: ArcEndpoint(
                        icon: Icons.wb_twilight_rounded,
                        time: widget.sunriseClockText,
                        iconColor: widget.accentGold,
                        textColor: widget.textSecondary,
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: ArcEndpoint(
                        icon: Icons.wb_sunny_rounded,
                        time: widget.sunsetClockText,
                        iconColor: widget.accentGold,
                        textColor: widget.textSecondary,
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

class SunIconMarker extends StatelessWidget {
  const SunIconMarker({super.key, required this.color, this.scale = 1.0});

  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final iconSize = 13.0 * scale;
    final glowBlur = 10.0 + (scale - 1.0) * 14.0;
    final glowSpread = 0.6 + (scale - 1.0) * 1.0;
    return Container(
      width: iconSize + 6,
      height: iconSize + 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.55),
            blurRadius: glowBlur,
            spreadRadius: glowSpread,
          ),
        ],
      ),
      child: Icon(
        Icons.wb_sunny_rounded,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }
}

class ArcLabel extends StatelessWidget {
  const ArcLabel({
    super.key,
    required this.title,
    required this.time,
    required this.titleColor,
    required this.timeColor,
    this.trailing,
  });

  final String title;
  final String time;
  final Color titleColor;
  final Color timeColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 3),
              trailing!,
            ],
          ],
        ),
        const SizedBox(height: 1),
        Text(
          time,
          style: TextStyle(
            color: timeColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class ArcEndpoint extends StatelessWidget {
  const ArcEndpoint({
    super.key,
    required this.icon,
    required this.time,
    required this.iconColor,
    required this.textColor,
    this.alignRight = false,
  });

  final IconData icon;
  final String time;
  final Color iconColor;
  final Color textColor;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final children = [
      Icon(icon, size: 12, color: iconColor),
      const SizedBox(width: 3),
      Text(
        time,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: alignRight ? children.reversed.toList() : children,
    );
  }
}

class SunArcPainter extends CustomPainter {
  const SunArcPainter({
    required this.progress,
    required this.accentStrong,
    required this.accentSoft,
    required this.accentGold,
    required this.trackColor,
    required this.isDark,
  });

  final double progress;
  final Color accentStrong;
  final Color accentSoft;
  final Color accentGold;
  final Color trackColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final radius = math.min(w / 2 - 8, h - 18);
    final baseY = h - 8;
    final center = Offset(cx, baseY);

    final dashedTrack = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final dashCount = 56;
    for (var i = 0; i < dashCount; i++) {
      final t = i / dashCount;
      final angle = math.pi - (math.pi * t);
      final inner = radius - 2;
      final outer = radius + 2;
      final p1 = Offset(
        center.dx + inner * math.cos(angle),
        center.dy - inner * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + outer * math.cos(angle),
        center.dy - outer * math.sin(angle),
      );
      if (i % 2 == 0) {
        canvas.drawLine(p1, p2, dashedTrack);
      }
    }

    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final filledSweep = math.pi * progress.clamp(0.0, 1.0);
    final filledPaint = Paint()
      ..shader = LinearGradient(
        colors: [accentSoft, accentStrong],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, math.pi, filledSweep, false, filledPaint);

    final ground = Paint()
      ..color = trackColor
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(8, baseY),
      Offset(w - 8, baseY),
      ground,
    );

    final mosqueColor = (isDark ? Colors.white : const Color(0xFF1F4E66))
        .withValues(alpha: isDark ? 0.06 : 0.07);
    final mosquePaint = Paint()..color = mosqueColor;
    final domeRadius = radius * 0.32;
    final domeCenter = Offset(cx, baseY - domeRadius * 0.55);
    final domePath = Path()
      ..moveTo(domeCenter.dx - domeRadius, baseY)
      ..lineTo(domeCenter.dx - domeRadius, domeCenter.dy)
      ..arcToPoint(
        Offset(domeCenter.dx + domeRadius, domeCenter.dy),
        radius: Radius.circular(domeRadius),
      )
      ..lineTo(domeCenter.dx + domeRadius, baseY)
      ..close();
    canvas.drawPath(domePath, mosquePaint);

    canvas.drawRect(
      Rect.fromLTWH(
        cx - domeRadius * 1.7,
        baseY - domeRadius * 0.55,
        domeRadius * 0.35,
        domeRadius * 0.55,
      ),
      mosquePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        cx + domeRadius * 1.35,
        baseY - domeRadius * 0.55,
        domeRadius * 0.35,
        domeRadius * 0.55,
      ),
      mosquePaint,
    );
  }

  @override
  bool shouldRepaint(covariant SunArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accentStrong != accentStrong ||
      oldDelegate.accentSoft != accentSoft ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.isDark != isDark;
}
