import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

enum _QiblaSource { none, api, basic }

class QiblaCompassScreen extends StatefulWidget {
  const QiblaCompassScreen({super.key});

  @override
  State<QiblaCompassScreen> createState() => _QiblaCompassScreenState();
}

class _QiblaCompassScreenState extends State<QiblaCompassScreen> {
  static const _kaabaLat = 21.422487;
  static const _kaabaLng = 39.826206;
  static const _baitulMukarramLat = 23.7286;
  static const _baitulMukarramLng = 90.4106;
  static const _deg = '\u00B0';

  final Dio _qiblaApi = Dio(
    BaseOptions(
      baseUrl: 'https://api.aladhan.com/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      responseType: ResponseType.json,
    ),
  );

  StreamSubscription<CompassEvent>? _compassSub;
  double? _heading;
  double? _qiblaBearing;
  double? _distanceKm;
  String? _sensorError;
  bool _isListening = false;
  bool _isLoadingQibla = true;
  bool _usingFallbackLocation = false;
  String _locationLabel = 'Locating...';
  _QiblaSource _qiblaSource = _QiblaSource.none;

  bool get _isBangla => appLanguageNotifier.value == AppLanguage.bangla;

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

  String _fallbackLocationLabel() =>
      _text('Baitul Mukarram, Dhaka', 'বায়তুল মুকাররম, ঢাকা');

  @override
  void initState() {
    super.initState();
    useDeviceLocationNotifier.addListener(_onLocationModeChanged);
    appLanguageNotifier.addListener(_onLanguageChanged);
    _startCompassListener();
    unawaited(_loadQiblaDirection());
  }

  @override
  void dispose() {
    useDeviceLocationNotifier.removeListener(_onLocationModeChanged);
    appLanguageNotifier.removeListener(_onLanguageChanged);
    _compassSub?.cancel();
    super.dispose();
  }

  void _onLocationModeChanged() {
    unawaited(_loadQiblaDirection());
  }

  void _onLanguageChanged() {
    _safeSetState(() {});
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  void _startCompassListener() {
    _compassSub?.cancel();
    final stream = FlutterCompass.events;
    if (stream == null) {
      _safeSetState(() {
        _sensorError = _text(
          'Compass is not available on this device.',
          'এই ডিভাইসে কম্পাস সেন্সর নেই।',
        );
        _isListening = false;
      });
      return;
    }

    _safeSetState(() {
      _sensorError = null;
      _isListening = true;
    });

    _compassSub = stream.listen(
      (event) {
        final heading = event.heading;
        if (heading == null || heading.isNaN) return;
        _safeSetState(() {
          _heading = _normalizeAngle(heading);
          _sensorError = null;
          _isListening = true;
        });
      },
      onError: (_) {
        _safeSetState(() {
          _sensorError = _text(
            'Could not read compass sensor.',
            'কম্পাস সেন্সর থেকে ডাটা পাওয়া যায়নি।',
          );
          _isListening = false;
        });
      },
      onDone: () {
        _safeSetState(() => _isListening = false);
      },
    );
  }

  Future<void> _refreshAll() async {
    _startCompassListener();
    await _loadQiblaDirection();
  }

  Future<void> _loadQiblaDirection() async {
    _safeSetState(() => _isLoadingQibla = true);

    final resolved = await _resolveCoordinates();
    final lat = resolved.lat;
    final lng = resolved.lng;
    final locationLabel = resolved.label;
    final usingFallbackLocation = resolved.usingFallbackLocation;

    final apiBearing = await _fetchQiblaBearingFromApi(lat: lat, lng: lng);
    final basicBearing = _calculateBasicQiblaBearing(lat: lat, lng: lng);
    final distanceKm =
        Geolocator.distanceBetween(lat, lng, _kaabaLat, _kaabaLng) / 1000;

    _safeSetState(() {
      _qiblaBearing = apiBearing ?? basicBearing;
      _qiblaSource = apiBearing != null ? _QiblaSource.api : _QiblaSource.basic;
      _distanceKm = distanceKm;
      _locationLabel = locationLabel;
      _usingFallbackLocation = usingFallbackLocation;
      _isLoadingQibla = false;
    });
  }

  Future<double?> _fetchQiblaBearingFromApi({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _qiblaApi.get('/qibla/$lat/$lng');
      final root = response.data;
      if (root is! Map) return null;
      final data = root['data'];
      if (data is! Map) return null;
      final direction = data['direction'];
      if (direction is! num) return null;
      return _normalizeAngle(direction.toDouble());
    } catch (_) {
      return null;
    }
  }

  Future<({double lat, double lng, String label, bool usingFallbackLocation})>
  _resolveCoordinates() async {
    if (!useDeviceLocationNotifier.value) {
      return (
        lat: _baitulMukarramLat,
        lng: _baitulMukarramLng,
        label: _fallbackLocationLabel(),
        usingFallbackLocation: true,
      );
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (
          lat: _baitulMukarramLat,
          lng: _baitulMukarramLng,
          label: _fallbackLocationLabel(),
          usingFallbackLocation: true,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (
          lat: _baitulMukarramLat,
          lng: _baitulMukarramLng,
          label: _fallbackLocationLabel(),
          usingFallbackLocation: true,
        );
      }

      final position = await Geolocator.getCurrentPosition();
      final label = await _resolveLocationLabel(
        position.latitude,
        position.longitude,
      );
      return (
        lat: position.latitude,
        lng: position.longitude,
        label: label,
        usingFallbackLocation: false,
      );
    } catch (_) {
      return (
        lat: _baitulMukarramLat,
        lng: _baitulMukarramLng,
        label: _fallbackLocationLabel(),
        usingFallbackLocation: true,
      );
    }
  }

  Future<String> _resolveLocationLabel(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) {
        return _text('Current location', 'বর্তমান অবস্থান');
      }
      final place = placemarks.first;

      final city =
          place.locality ??
          place.subAdministrativeArea ??
          place.administrativeArea ??
          _text('Current location', 'বর্তমান অবস্থান');
      final region = place.subAdministrativeArea ?? place.administrativeArea;
      final country = place.country;

      final trailing = <String>[];
      if (region != null && region.isNotEmpty && region != city) {
        trailing.add(region);
      }
      if (country != null && country.isNotEmpty) {
        trailing.add(country);
      }

      if (trailing.isEmpty) return city;
      return '$city, ${trailing.join(', ')}';
    } catch (_) {
      return _text('Current location', 'বর্তমান অবস্থান');
    }
  }

  double _calculateBasicQiblaBearing({
    required double lat,
    required double lng,
  }) {
    final latRad = lat * math.pi / 180;
    final lngRad = lng * math.pi / 180;
    final kaabaLatRad = _kaabaLat * math.pi / 180;
    final kaabaLngRad = _kaabaLng * math.pi / 180;
    final dLng = kaabaLngRad - lngRad;

    final y = math.sin(dLng);
    final x =
        math.cos(latRad) * math.tan(kaabaLatRad) -
        math.sin(latRad) * math.cos(dLng);
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return _normalizeAngle(bearing);
  }

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
      case _QiblaSource.api:
        return _text('Qibla source: API', 'কিবলা সোর্স: API');
      case _QiblaSource.basic:
        return _text(
          'Qibla source: Basic fallback',
          'কিবলা সোর্স: বেসিক ফলব্যাক',
        );
      case _QiblaSource.none:
        return _text('Qibla source: --', 'কিবলা সোর্স: --');
    }
  }

  String _statusHint() {
    if (_sensorError != null) return _sensorError!;
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
                                _sensorError == null) ...[
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
                                color: _sensorError == null
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
              bottomNav(context, 3),
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
