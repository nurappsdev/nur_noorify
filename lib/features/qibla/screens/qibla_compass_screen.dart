import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:first_project/features/qibla/providers/qibla_provider.dart';
import 'package:first_project/shared/providers/language_provider.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class QiblaCompassScreen extends StatelessWidget {
  const QiblaCompassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<QiblaProvider>(
      create: (ctx) =>
          QiblaProvider(isBangla: ctx.read<LanguageProvider>().isBangla),
      child: const _QiblaCompassView(),
    );
  }
}

class _QiblaCompassView extends StatefulWidget {
  const _QiblaCompassView();

  @override
  State<_QiblaCompassView> createState() => _QiblaCompassViewState();
}

class _QiblaCompassViewState extends State<_QiblaCompassView> {
  static const _deg = '\u00B0';

  QiblaProvider get _qibla => context.read<QiblaProvider>();

  double? get _heading => _qibla.heading;
  double? get _qiblaBearing => _qibla.qiblaBearing;
  double? get _distanceKm => _qibla.distanceKm;
  bool get _isListening => _qibla.isListening;
  bool get _isLoadingQibla => _qibla.isLoadingQibla;
  bool get _usingFallbackLocation => _qibla.usingFallbackLocation;
  String get _locationLabel => _qibla.locationLabel;
  QiblaSource get _qiblaSource => _qibla.qiblaSource;
  QiblaSensorError get _sensorError => _qibla.sensorError;

  bool get _isBangla => context.read<LanguageProvider>().isBangla;

  bool _looksMojibake(String value) {
    for (final unit in value.codeUnits) {
      if (unit == 0x00C3 ||
          unit == 0x00C2 ||
          unit == 0x00E0 ||
          unit == 0x00D8 ||
          unit == 0x00D9 ||
          unit == 0x00D0 ||
          unit == 0x00E2) {
        return true;
      }
    }
    return false;
  }

  String _repairMojibake(String value) {
    var output = value;
    for (var i = 0; i < 4; i++) {
      if (!_looksMojibake(output)) break;
      try {
        output = utf8.decode(latin1.encode(output));
      } catch (_) {
        break;
      }
    }
    return output;
  }

  bool _containsBangla(String value) {
    return RegExp(r'[\u0980-\u09FF]').hasMatch(value);
  }

  String _text(String english, String bangla) {
    if (!_isBangla) return english;
    final repaired = _repairMojibake(bangla);
    if (_containsBangla(repaired) && !_looksMojibake(repaired)) {
      return repaired;
    }
    return english;
  }

  Future<void> _refreshAll() => _qibla.refreshAll(isBangla: _isBangla);

  double _normalizeAngle(double degrees) {
    final normalized = degrees % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  double _signedDelta(double target, double current) {
    return ((target - current + 540) % 360) - 180;
  }

  String _headingText(double? value) {
    if (value == null) return '--';
    return '${value.round()}$_deg';
  }

  String _directionText(double? value) {
    if (value == null) return '--';
    final angle = _normalizeAngle(value);
    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((angle + 22.5) ~/ 45) % 8;
    return labels[index];
  }

  String _qiblaValueText() {
    final heading = _heading;
    final bearing = _qiblaBearing;
    if (heading == null || bearing == null) return '--';
    final delta = _signedDelta(bearing, heading);
    final angle = delta.abs().round();
    if (angle < 1) return '0$_deg';
    if (_isBangla) {
      return '$angle$_deg ${delta >= 0 ? 'পূর্ব' : 'পশ্চিম'}';
    }
    return '$angle$_deg ${delta >= 0 ? 'E' : 'W'}';
  }

  String _qiblaSourceText() {
    switch (_qiblaSource) {
      case QiblaSource.api:
        return _text('Qibla source: API', 'কিবলা সোর্স: API');
      case QiblaSource.basic:
        return _text(
          'Qibla source: Basic fallback',
          'কিবলা সোর্স: বেসিক ফলব্যাক',
        );
      case QiblaSource.none:
        return _text('Qibla source: --', 'কিবলা সোর্স: --');
    }
  }

  String? _sensorErrorText() {
    switch (_sensorError) {
      case QiblaSensorError.none:
        return null;
      case QiblaSensorError.unavailable:
        return _text(
          'Compass is not available on this device.',
          'এই ডিভাইসে কম্পাস সেন্সর নেই।',
        );
      case QiblaSensorError.readError:
        return _text(
          'Could not read compass sensor.',
          'কম্পাস সেন্সর থেকে ডাটা পাওয়া যায়নি।',
        );
    }
  }

  String _statusHint() {
    final sensorError = _sensorErrorText();
    if (sensorError != null) return sensorError;
    if (_heading == null) {
      return _text(
        'Move your phone in a figure-8 to calibrate the compass.',
        'কম্পাস ক্যালিব্রেট করতে ফোনটি ৮ আকৃতিতে নাড়ান।',
      );
    }
    if (_qiblaBearing == null) {
      return _text('Fetching Qibla direction...', 'কিবলার দিক আনা হচ্ছে...');
    }
    final delta = _signedDelta(_qiblaBearing!, _heading!);
    final absDelta = delta.abs();
    if (absDelta < 4) {
      return _text('You are facing Qibla.', 'আপনি কিবলা মুখী আছেন।');
    }
    final angle = absDelta.round();
    if (_isBangla) {
      return delta > 0
          ? 'কিবলার দিকে যেতে ডানে $angle$_deg ঘুরুন।'
          : 'কিবলার দিকে যেতে বামে $angle$_deg ঘুরুন।';
    }
    return delta > 0
        ? 'Turn right $angle$_deg to face Qibla.'
        : 'Turn left $angle$_deg to face Qibla.';
  }

  ({String primary, String secondary}) _locationTextLines() {
    final normalized = _locationLabel.trim();
    if (normalized.isEmpty) {
      return (
        primary: _text('Current location', 'বর্তমান অবস্থান'),
        secondary: '',
      );
    }

    final parts = normalized
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (parts.length <= 1) {
      return (primary: normalized, secondary: '');
    }
    return (primary: parts.first, secondary: parts.sublist(1).join(', '));
  }

  @override
  Widget build(BuildContext context) {
    context.watch<QiblaProvider>();
    context.watch<LanguageProvider>();
    final glass = NoorifyGlassTheme(context);
    final dialTurns = _heading == null ? 0.0 : -_heading! / 360;
    final qiblaTurns = (_heading != null && _qiblaBearing != null)
        ? _signedDelta(_qiblaBearing!, _heading!) / 360
        : null;
    final location = _locationTextLines();

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 16.h),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Material(
                            color: glass.isDark
                                ? const Color(0x332EB8E6)
                                : const Color(0x1A1EA8B8),
                            shape: const CircleBorder(),
                            child: IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18.sp,
                                color: glass.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              _text('Qibla Compass', 'কিবলা কম্পাস'),
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w700,
                                color: glass.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      NoorifyGlassCard(
                        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
                        radius: BorderRadius.circular(20.r),
                        child: Column(
                          children: [
                            Text(
                              _text(
                                'Phone sensor heading + Qibla direction',
                                'ফোন সেন্সর হেডিং + কিবলা দিক',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                color: glass.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 14.h),
                            SizedBox(
                              width: 314.r,
                              height: 314.r,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 300.r,
                                    height: 300.r,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: glass.isDark
                                            ? const [
                                                Color(0xFF18293C),
                                                Color(0xFF101E2D),
                                              ]
                                            : const [
                                                Color(0xFFFFFFFF),
                                                Color(0xFFEAF3FA),
                                              ],
                                      ),
                                      border: Border.all(
                                        color: glass.isDark
                                            ? const Color(0x3E8CBED8)
                                            : const Color(0x80BFD8E9),
                                      ),
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: dialTurns,
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOut,
                                    child: SizedBox(
                                      width: 286.r,
                                      height: 286.r,
                                      child: CustomPaint(
                                        painter: _CompassDialMarksPainter(
                                          isDark: glass.isDark,
                                        ),
                                      ),
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: dialTurns,
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOut,
                                    child: SizedBox(
                                      width: 268.r,
                                      height: 268.r,
                                      child: Stack(
                                        children: [
                                          Align(
                                            alignment: Alignment.topCenter,
                                            child: _CardinalLabel(
                                              'N',
                                              color: glass.isDark
                                                  ? const Color(0xFFBCD4E8)
                                                  : const Color(0xFF557A93),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: _CardinalLabel(
                                              'E',
                                              color: glass.isDark
                                                  ? const Color(0xFFBCD4E8)
                                                  : const Color(0xFF557A93),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.bottomCenter,
                                            child: _CardinalLabel(
                                              'S',
                                              color: glass.isDark
                                                  ? const Color(0xFFBCD4E8)
                                                  : const Color(0xFF557A93),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: _CardinalLabel(
                                              'W',
                                              color: glass.isDark
                                                  ? const Color(0xFFBCD4E8)
                                                  : const Color(0xFF557A93),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (qiblaTurns != null)
                                    AnimatedRotation(
                                      turns: qiblaTurns,
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      curve: Curves.easeOut,
                                      child: SizedBox(
                                        width: 256.r,
                                        height: 256.r,
                                        child: Align(
                                          alignment: Alignment.topCenter,
                                          child: _QiblaDot(
                                            accent: glass.accent,
                                          ),
                                        ),
                                      ),
                                    ),
                                  SizedBox(
                                    width: 258.r,
                                    height: 258.r,
                                    child: CustomPaint(
                                      painter: _NeedlePainter(
                                        color: glass.accent,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 11.r,
                                    height: 11.r,
                                    decoration: BoxDecoration(
                                      color: glass.isDark
                                          ? const Color(0xFF8DB3CA)
                                          : const Color(0xFF6E90A6),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 14.h),
                            Text(
                              _headingText(_heading),
                              style: TextStyle(
                                fontSize: 50.sp,
                                height: 1,
                                color: glass.accent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              _directionText(_heading),
                              style: TextStyle(
                                fontSize: 20.sp,
                                color: glass.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _text(
                                'Qibla offset: ${_qiblaValueText()}',
                                'কিবলা অফসেট: ${_qiblaValueText()}',
                              ),
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: glass.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _qiblaSourceText(),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: glass.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              location.primary,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 21.sp,
                                color: glass.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (location.secondary.isNotEmpty)
                              Text(
                                location.secondary,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: glass.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (_distanceKm != null) ...[
                              SizedBox(height: 4.h),
                              Text(
                                _text(
                                  '${_distanceKm!.toStringAsFixed(0)} km to Kaaba',
                                  'কাবা পর্যন্ত ${_distanceKm!.toStringAsFixed(0)} কিমি',
                                ),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: glass.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (_usingFallbackLocation) ...[
                              SizedBox(height: 6.h),
                              Text(
                                _text(
                                  'Using fallback location (Dhaka)',
                                  'ফলব্যাক লোকেশন (ঢাকা) ব্যবহার হচ্ছে',
                                ),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Color(0xFFC58A1E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            SizedBox(height: 12.h),
                            FilledButton.icon(
                              onPressed: _refreshAll,
                              style: FilledButton.styleFrom(
                                backgroundColor: glass.accent,
                                foregroundColor: glass.isDark
                                    ? const Color(0xFF072734)
                                    : Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 22.w,
                                  vertical: 12.h,
                                ),
                                shape: const StadiumBorder(),
                              ),
                              icon: Icon(Icons.refresh_rounded, size: 17.sp),
                              label: Text(
                                'Refresh',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                            if ((_isLoadingQibla || !_isListening) &&
                                _sensorError == QiblaSensorError.none) ...[
                              SizedBox(height: 12.h),
                              SizedBox(
                                width: 22.r,
                                height: 22.r,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.1,
                                  color: glass.accent,
                                ),
                              ),
                            ],
                            SizedBox(height: 10.h),
                            Text(
                              _statusHint(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: _sensorError == QiblaSensorError.none
                                    ? glass.textSecondary
                                    : const Color(0xFFB65757),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QiblaDot extends StatelessWidget {
  const _QiblaDot({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20.r,
      height: 20.r,
      decoration: BoxDecoration(
        color: accent,
        border: Border.all(color: Colors.white, width: 2.w),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.star_rounded, size: 10.sp, color: Colors.white),
    );
  }
}

class _CardinalLabel extends StatelessWidget {
  const _CardinalLabel(this.label, {required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontSize: 26.sp, color: color, fontWeight: FontWeight.w700),
    );
  }
}

class _CompassDialMarksPainter extends CustomPainter {
  const _CompassDialMarksPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final majorTickPaint = Paint()
      ..color = isDark ? const Color(0xFF84A8BE) : const Color(0xFF8AA4B8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final minorTickPaint = Paint()
      ..color = isDark ? const Color(0xFF6A8FA8) : const Color(0xFF9CB3C3)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 36; i++) {
      final angle = (i * 10) * math.pi / 180;
      final major = i % 3 == 0;
      final inner = radius - (major ? 14 : 9);
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NeedlePainter extends CustomPainter {
  const _NeedlePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const northY = 20.0;

    final stemPaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, Offset(center.dx, northY + 20), stemPaint);

    final triangle = Path()
      ..moveTo(center.dx, northY)
      ..lineTo(center.dx - 9, northY + 16)
      ..lineTo(center.dx + 9, northY + 16)
      ..close();
    canvas.drawPath(triangle, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
