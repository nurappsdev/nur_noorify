import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Maps a time-based progress (fraction of the Fajr→Maghrib span elapsed) to
/// the geometric sweep used to place the sun on the elliptical arc.
///
/// The naive mapping `angle = π·(1 − p)` makes horizontal motion fastest at the
/// apex (its speed is `∝ sin(π·p)`), so the sun lurches far toward the edge just
/// before/after solar noon. Remapping through `acos` makes the sun's horizontal
/// position move linearly with elapsed time, so e.g. shortly after Dhuhr it sits
/// just slightly past the middle rather than jumping well to the right.
double _linearArcProgress(double timeProgress) {
  final clamped = timeProgress.clamp(0.0, 1.0);
  return math.acos((1 - 2 * clamped).clamp(-1.0, 1.0)) / math.pi;
}

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
    required this.currentTimeLabel,
    this.replayTick = 0,
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

  /// Live clock shown riding with the sun marker along the arc.
  final String currentTimeLabel;

  /// Bumped by the host whenever the home screen becomes visible again (e.g.
  /// returning from another tab) to replay the sunrise→now sweep.
  final int replayTick;

  @override
  State<SunArcArea> createState() => _SunArcAreaState();
}

class _SunArcAreaState extends State<SunArcArea>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    // Sweep from sunrise (0) up to the current position on first appearance.
    // The easing is applied to the sweep's *timing* via animateTo's curve so
    // the controller still settles exactly on currentProgress — wrapping it in
    // a CurvedAnimation instead would distort the resting position.
    _controller.value = 0.0;
    _controller.animateTo(
      widget.currentProgress.clamp(0.0, 1.0),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(SunArcArea old) {
    super.didUpdateWidget(old);
    if (old.replayTick != widget.replayTick) {
      _replay();
    } else if (!_controller.isAnimating &&
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
    _controller.animateTo(
      widget.currentProgress.clamp(0.0, 1.0),
      curve: Curves.easeInOutCubic,
    );
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
        aspectRatio: 3.6,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final cx = w / 2;
            final baseY = h - 5;
            // Elliptical arc: a wide horizontal radius spreads the endpoints to
            // the card edges, while the smaller vertical radius keeps it short.
            final rx = w / 2 - 6;
            final ry = h - 14;

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                // Remap so the sun travels at a uniform horizontal pace; the
                // raw value accelerates the marker near the midday apex.
                final progress = _linearArcProgress(_controller.value);
                final angle = math.pi * (1 - progress);
                final sunDx = cx + rx * math.cos(angle);
                final sunDy = baseY - ry * math.sin(angle);
                final iconScale = _sunIconScale(progress);
                final chipColor = widget.accentSoft.withValues(
                  alpha: widget.isDark ? 0.18 : 0.12,
                );

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
                      left: sunDx,
                      top: sunDy,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, -0.5),
                        child: SunMarker(
                          scale: iconScale,
                          timeLabel: widget.currentTimeLabel,
                          timeColor: widget.textPrimary,
                          glowColor: widget.accentGold,
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(-0.62, -0.1),
                      child: ArcLabel(
                        emoji: '🌤️',
                        title: widget.leadingTitle,
                        time: widget.leadingTimeLabel,
                        titleColor: widget.textPrimary,
                        timeColor: widget.textSecondary,
                        chipColor: chipColor,
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0.62, -0.1),
                      child: ArcLabel(
                        emoji: '☀️',
                        title: widget.trailingTitle,
                        time: widget.trailingTimeLabel,
                        titleColor: widget.textPrimary,
                        timeColor: widget.textSecondary,
                        chipColor: chipColor,
                      ),
                    ),
                    Positioned(
                      left: -2,
                      bottom: -2,
                      child: ArcEndpoint(
                        emoji: '🌅',
                        time: widget.sunriseClockText,
                        textColor: widget.textSecondary,
                        chipColor: chipColor,
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: ArcEndpoint(
                        emoji: '🌇',
                        time: widget.sunsetClockText,
                        textColor: widget.textSecondary,
                        chipColor: chipColor,
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

/// Traveling sun glyph (emoji) wrapped in a soft golden halo, with the live
/// clock shown in a pill just beneath it.
class SunMarker extends StatelessWidget {
  const SunMarker({
    super.key,
    required this.scale,
    required this.timeLabel,
    required this.timeColor,
    required this.glowColor,
  });

  final double scale;
  final String timeLabel;
  final Color timeColor;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    final emojiSize = 16.sp * scale;
    final haloSize = emojiSize + 18.w;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: haloSize,
          height: haloSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glowColor.withValues(alpha: 0.55),
                      glowColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
              Text('☀️', style: TextStyle(fontSize: emojiSize)),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: glowColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: Text(
            timeLabel,
            style: TextStyle(
              color: timeColor,
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
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
    required this.chipColor,
    this.emoji,
  });

  final String title;
  final String time;
  final Color titleColor;
  final Color timeColor;
  final Color chipColor;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null) ...[
                Text(emoji!, style: TextStyle(fontSize: 12.sp)),
                SizedBox(width: 3.w),
              ],
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            time,
            style: TextStyle(
              color: timeColor,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ArcEndpoint extends StatelessWidget {
  const ArcEndpoint({
    super.key,
    required this.emoji,
    required this.time,
    required this.textColor,
    required this.chipColor,
    this.alignRight = false,
  });

  final String emoji;
  final String time;
  final Color textColor;
  final Color chipColor;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final children = [
      Text(emoji, style: TextStyle(fontSize: 12.sp)),
      SizedBox(width: 4.w),
      Text(
        time,
        style: TextStyle(
          color: textColor,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    ];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignRight ? children.reversed.toList() : children,
      ),
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
    // Match the elliptical geometry used by the marker in the widget state.
    final rx = w / 2 - 6;
    final ry = h - 14;
    final baseY = h - 6;
    final center = Offset(cx, baseY);

    final arcRect = Rect.fromCenter(
      center: center,
      width: rx * 2,
      height: ry * 2,
    );
    final clamped = progress.clamp(0.0, 1.0);
    final filledSweep = math.pi * clamped;

    // Full dashed track for the not-yet-reached portion of the path.
    final dashedTrack = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const dashCount = 60;
    for (var i = 0; i < dashCount; i++) {
      if (i.isOdd) continue;
      final angle = math.pi - (math.pi * (i / dashCount));
      final p1 = Offset(
        center.dx + (rx - 2) * math.cos(angle),
        center.dy - (ry - 2) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (rx + 2) * math.cos(angle),
        center.dy - (ry + 2) * math.sin(angle),
      );
      canvas.drawLine(p1, p2, dashedTrack);
    }

    // Soft "sky" gradient filling the area under the traveled arc.
    if (clamped > 0) {
      final tipX = center.dx + rx * math.cos(math.pi + filledSweep);
      final fillPath = Path()
        ..moveTo(cx - rx, baseY)
        ..arcTo(arcRect, math.pi, filledSweep, false)
        ..lineTo(tipX, baseY)
        ..close();
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentGold.withValues(alpha: isDark ? 0.30 : 0.22),
            accentSoft.withValues(alpha: 0.03),
          ],
        ).createShader(Rect.fromLTRB(0, baseY - ry, w, baseY));
      canvas.drawPath(fillPath, fillPaint);
    }

    // Blurred glow behind the traveled arc stroke.
    final glowPaint = Paint()
      ..color = accentGold.withValues(alpha: isDark ? 0.55 : 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(arcRect, math.pi, filledSweep, false, glowPaint);

    // Crisp gradient arc: cool at the horizon, warming toward the sun.
    final filledPaint = Paint()
      ..shader = LinearGradient(
        colors: [accentStrong, accentGold],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, math.pi, filledSweep, false, filledPaint);

    // Horizon line that fades out toward both ends.
    final ground = Paint()
      ..shader = LinearGradient(
        colors: [
          trackColor.withValues(alpha: 0),
          trackColor,
          trackColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, baseY, w, 1))
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(4, baseY),
      Offset(w - 4, baseY),
      ground,
    );

    final mosqueColor = (isDark ? Colors.white : const Color(0xFF1F4E66))
        .withValues(alpha: isDark ? 0.06 : 0.07);
    final mosquePaint = Paint()..color = mosqueColor;
    final domeRadius = ry * 0.42;
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
      oldDelegate.accentGold != accentGold ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.isDark != isDark;
}
