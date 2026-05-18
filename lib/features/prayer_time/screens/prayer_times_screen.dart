import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/features/prayer_time/services/prayer_schedule_service.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  static const _baitulMukarramLat = 23.7286;
  static const _baitulMukarramLng = 90.4106;
  static const _fallbackLabel = 'Baitul Mukarram, Dhaka';

  final PrayerScheduleService _service = PrayerScheduleService();

  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  DailyPrayerSchedule? _todaySchedule;
  DailyPrayerSchedule? _tomorrowSchedule;

  String _locationLabel = 'Detecting location...';
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _isRefreshing = false;
  bool _usingFallbackLocation = false;
  bool _usingOfflineCalculation = false;

  String _activePrayer = 'Fajr';
  DateTime? _nextPrayerAt;
  Duration _remaining = Duration.zero;
  double _elapsedProgress = 0.0;

  bool get _isBangla => appLanguageNotifier.value == AppLanguage.bangla;

  String _text(String english, String bangla) => _isBangla ? bangla : english;

  @override
  void initState() {
    super.initState();
    appLanguageNotifier.addListener(_onLanguageChanged);
    useDeviceLocationNotifier.addListener(_onLocationModeChanged);
    profileLocationNotifier.addListener(_onProfileLocationChanged);
    _seedLocalPrayerPreview();
    unawaited(_loadPrayerData(showLoader: false));
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _updateActivePrayer();
      if (_needsFreshSchedule() && !_isLoading) {
        unawaited(_loadPrayerData(showLoader: false));
      }
    });
  }

  @override
  void dispose() {
    appLanguageNotifier.removeListener(_onLanguageChanged);
    useDeviceLocationNotifier.removeListener(_onLocationModeChanged);
    profileLocationNotifier.removeListener(_onProfileLocationChanged);
    _clockTimer?.cancel();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onLocationModeChanged() {
    unawaited(_loadPrayerData(showLoader: false));
  }

  void _onProfileLocationChanged() {
    if (!mounted || useDeviceLocationNotifier.value) return;
    setState(() => _locationLabel = _profileOrFallbackLocationLabel());
  }

  bool _needsFreshSchedule() {
    final today = DateTime(_now.year, _now.month, _now.day);
    return _todaySchedule == null ||
        _tomorrowSchedule == null ||
        !_isSameDate(_todaySchedule!.date, today) ||
        !_isSameDate(
          _tomorrowSchedule!.date,
          today.add(const Duration(days: 1)),
        );
  }

  String _profileOrFallbackLocationLabel() {
    final value = profileLocationNotifier.value.trim();
    return value.isEmpty ? _fallbackLabel : value;
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await _loadPrayerData(showLoader: false);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _seedLocalPrayerPreview() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final todaySchedule = _service.calculateFallback(
      date: today,
      latitude: _baitulMukarramLat,
      longitude: _baitulMukarramLng,
    );
    final tomorrowSchedule = _service.calculateFallback(
      date: tomorrow,
      latitude: _baitulMukarramLat,
      longitude: _baitulMukarramLng,
    );

    setState(() {
      _now = now;
      _todaySchedule = todaySchedule;
      _tomorrowSchedule = tomorrowSchedule;
      _locationLabel = _profileOrFallbackLocationLabel();
      _usingFallbackLocation = true;
      _usingOfflineCalculation = true;
      _isLoading = false;
      _isSyncing = true;
    });
    _updateActivePrayer();
  }

  Future<void> _loadPrayerData({required bool showLoader}) async {
    final hasExistingPreview =
        _todaySchedule != null && _tomorrowSchedule != null;
    if (mounted) {
      setState(() {
        _isSyncing = true;
        if (showLoader && !hasExistingPreview) {
          _isLoading = true;
        }
      });
    } else {
      _isSyncing = true;
      if (showLoader && !hasExistingPreview) {
        _isLoading = true;
      }
    }

    final resolved = await _resolveCoordinatesAndLabel();
    final today = DateTime(_now.year, _now.month, _now.day);
    final tomorrow = today.add(const Duration(days: 1));

    DailyPrayerSchedule todaySchedule;
    DailyPrayerSchedule tomorrowSchedule;
    var usedOfflineFallback = false;

    try {
      final result = await Future.wait<DailyPrayerSchedule>([
        _service.fetchFromApi(
          date: today,
          latitude: resolved.latitude,
          longitude: resolved.longitude,
        ),
        _service.fetchFromApi(
          date: tomorrow,
          latitude: resolved.latitude,
          longitude: resolved.longitude,
        ),
      ]);
      todaySchedule = result[0];
      tomorrowSchedule = result[1];
    } catch (_) {
      usedOfflineFallback = true;
      todaySchedule = _service.calculateFallback(
        date: today,
        latitude: resolved.latitude,
        longitude: resolved.longitude,
      );
      tomorrowSchedule = _service.calculateFallback(
        date: tomorrow,
        latitude: resolved.latitude,
        longitude: resolved.longitude,
      );
    }

    if (!mounted) return;
    setState(() {
      _todaySchedule = todaySchedule;
      _tomorrowSchedule = tomorrowSchedule;
      _locationLabel = resolved.label;
      _usingFallbackLocation = resolved.usingFallbackLocation;
      _usingOfflineCalculation = usedOfflineFallback;
      _isLoading = false;
      _isSyncing = false;
      _now = DateTime.now();
    });
    _updateActivePrayer();
  }

  Future<
    ({
      double latitude,
      double longitude,
      String label,
      bool usingFallbackLocation,
    })
  >
  _resolveCoordinatesAndLabel() async {
    if (!useDeviceLocationNotifier.value) {
      return (
        latitude: _baitulMukarramLat,
        longitude: _baitulMukarramLng,
        label: _profileOrFallbackLocationLabel(),
        usingFallbackLocation: true,
      );
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (
          latitude: _baitulMukarramLat,
          longitude: _baitulMukarramLng,
          label: _profileOrFallbackLocationLabel(),
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
          latitude: _baitulMukarramLat,
          longitude: _baitulMukarramLng,
          label: _profileOrFallbackLocationLabel(),
          usingFallbackLocation: true,
        );
      }

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
      } catch (_) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown == null) rethrow;
        position = lastKnown;
      }

      final label = await _resolveLocationLabel(
        position.latitude,
        position.longitude,
      );
      return (
        latitude: position.latitude,
        longitude: position.longitude,
        label: label,
        usingFallbackLocation: false,
      );
    } catch (_) {
      return (
        latitude: _baitulMukarramLat,
        longitude: _baitulMukarramLng,
        label: _profileOrFallbackLocationLabel(),
        usingFallbackLocation: true,
      );
    }
  }

  Future<String> _resolveLocationLabel(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return _profileOrFallbackLocationLabel();
      final place = placemarks.first;
      final city =
          place.locality ??
          place.subAdministrativeArea ??
          place.administrativeArea ??
          'Current location';
      final area = place.administrativeArea ?? place.country ?? '';
      final label = area.isNotEmpty ? '$city, $area' : city;
      if (profileLocationNotifier.value != label) {
        profileLocationNotifier.value = label;
        await saveAppPreferences();
      }
      return label;
    } catch (_) {
      return _profileOrFallbackLocationLabel();
    }
  }

  void _updateActivePrayer() {
    final today = _todaySchedule;
    final tomorrow = _tomorrowSchedule;
    if (today == null || tomorrow == null || !mounted) return;

    final list = <({String key, DateTime at})>[
      (key: 'Fajr', at: today.fajr),
      (key: 'Zuhr', at: today.dzuhr),
      (key: 'Asr', at: today.asr),
      (key: 'Maghrib', at: today.maghrib),
      (key: 'Isha', at: today.isha),
    ];

    ({String key, DateTime at})? nextPrayer;
    var nextIndex = -1;
    for (var i = 0; i < list.length; i++) {
      if (list[i].at.isAfter(_now)) {
        nextPrayer = list[i];
        nextIndex = i;
        break;
      }
    }

    DateTime previousBoundary;
    if (nextPrayer == null) {
      nextPrayer = (key: 'Fajr', at: tomorrow.fajr);
      previousBoundary = today.isha;
    } else if (nextIndex == 0) {
      previousBoundary = today.isha.subtract(const Duration(days: 1));
    } else {
      previousBoundary = list[nextIndex - 1].at;
    }

    var remaining = nextPrayer.at.difference(_now);
    if (remaining.isNegative) remaining = Duration.zero;

    final fullWindow = nextPrayer.at.difference(previousBoundary);
    final progress = fullWindow.inMilliseconds <= 0
        ? 0.0
        : ((fullWindow.inMilliseconds - remaining.inMilliseconds) /
                  fullWindow.inMilliseconds)
              .clamp(0.0, 1.0);

    setState(() {
      _activePrayer = nextPrayer!.key;
      _nextPrayerAt = nextPrayer.at;
      _remaining = remaining;
      _elapsedProgress = progress;
    });
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _localizedPrayer(String key) {
    if (!_isBangla) return key;
    const map = {
      'Fajr': '\u09ab\u099c\u09b0',
      'Sunrise': '\u09b8\u09c2\u09b0\u09cd\u09af\u09cb\u09a6\u09af\u09bc',
      'Zuhr': '\u09af\u09cb\u09b9\u09b0',
      'Asr': '\u0986\u09b8\u09b0',
      'Maghrib': '\u09ae\u09be\u0997\u09b0\u09bf\u09ac',
      'Isha': '\u098f\u09b6\u09be',
    };
    return map[key] ?? key;
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '--:--';
    final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final amPm = value.hour < 12 ? 'AM' : 'PM';
    final out = '$hour12:$minute $amPm';
    return _isBangla ? _toBanglaDigits(out) : out;
  }

  String _formatRemaining() {
    final safe = _remaining.isNegative ? Duration.zero : _remaining;
    final hh = safe.inHours.toString().padLeft(2, '0');
    final mm = (safe.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (safe.inSeconds % 60).toString().padLeft(2, '0');
    final out = '$hh:$mm:$ss';
    return _isBangla ? _toBanglaDigits(out) : out;
  }

  String _toBanglaDigits(String input) {
    const latin = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bangla = [
      '\u09e6',
      '\u09e7',
      '\u09e8',
      '\u09e9',
      '\u09ea',
      '\u09eb',
      '\u09ec',
      '\u09ed',
      '\u09ee',
      '\u09ef',
    ];
    var output = input;
    for (var i = 0; i < latin.length; i++) {
      output = output.replaceAll(latin[i], bangla[i]);
    }
    return output;
  }

  List<({String key, IconData icon, DateTime? time, String subtitle})>
  _prayerCards() {
    final today = _todaySchedule;
    return [
      (
        key: 'Fajr',
        icon: Icons.wb_twilight_rounded,
        time: today?.fajr,
        subtitle: _text(
          'Dawn prayer',
          '\u09ad\u09cb\u09b0\u09c7\u09b0 \u09b8\u09be\u09b2\u09be\u09a4',
        ),
      ),
      (
        key: 'Zuhr',
        icon: Icons.wb_sunny_rounded,
        time: today?.dzuhr,
        subtitle: _text(
          'Midday prayer',
          '\u09a6\u09c1\u09aa\u09c1\u09b0\u09c7\u09b0 \u09b8\u09be\u09b2\u09be\u09a4',
        ),
      ),
      (
        key: 'Asr',
        icon: Icons.brightness_5_rounded,
        time: today?.asr,
        subtitle: _text(
          'Afternoon prayer',
          '\u09ac\u09bf\u0995\u09be\u09b2\u09c7\u09b0 \u09b8\u09be\u09b2\u09be\u09a4',
        ),
      ),
      (
        key: 'Maghrib',
        icon: Icons.bedtime_rounded,
        time: today?.maghrib,
        subtitle: _text(
          'Sunset prayer',
          '\u09b8\u09c2\u09b0\u09cd\u09af\u09be\u09b8\u09cd\u09a4\u09c7\u09b0 \u09b8\u09be\u09b2\u09be\u09a4',
        ),
      ),
      (
        key: 'Isha',
        icon: Icons.nightlight_round,
        time: today?.isha,
        subtitle: _text(
          'Night prayer',
          '\u09b0\u09be\u09a4\u09c7\u09b0 \u09b8\u09be\u09b2\u09be\u09a4',
        ),
      ),
    ];
  }

  List<({String label, IconData icon, DateTime? time, bool emphasized})>
  _dayHighlights() {
    final today = _todaySchedule;
    return [
      (
        label: _text(
          'Sehri Ends',
          '\u09b8\u09c7\u09b9\u09b0\u09bf \u09b6\u09c7\u09b7',
        ),
        icon: Icons.nightlight_round,
        time: today?.fajr,
        emphasized: false,
      ),
      (
        label: _text(
          'Sunrise',
          '\u09b8\u09c2\u09b0\u09cd\u09af\u09cb\u09a6\u09af\u09bc',
        ),
        icon: Icons.wb_sunny_outlined,
        time: today?.sunrise,
        emphasized: false,
      ),
      (
        label: _text(
          'Iftar Starts',
          '\u0987\u09ab\u09a4\u09be\u09b0 \u09b6\u09c1\u09b0\u09c1',
        ),
        icon: Icons.restaurant_rounded,
        time: today?.maghrib,
        emphasized: true,
      ),
      (
        label: _text(
          'Isha Starts',
          '\u098f\u09b6\u09be \u09b6\u09c1\u09b0\u09c1',
        ),
        icon: Icons.dark_mode_outlined,
        time: today?.isha,
        emphasized: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final ringProgress = (1.0 - _elapsedProgress).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    children: [
                      NoorifyGlassCard(
                        radius: BorderRadius.circular(24),
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                  return;
                                }
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed(RouteNames.discover);
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: glass.isDark
                                    ? const Color(0x332EB8E6)
                                    : const Color(0x221EA8B8),
                                foregroundColor: glass.accent,
                              ),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _text(
                                      'Prayer Times',
                                      '\u09a8\u09be\u09ae\u09be\u099c\u09c7\u09b0 \u09b8\u09ae\u09df',
                                    ),
                                    style: TextStyle(
                                      color: glass.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _locationLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: glass.textSecondary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (_isSyncing) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      _text(
                                        'Syncing location and online data...',
                                        '\u09b2\u09cb\u0995\u09c7\u09b6\u09a8 \u0993 \u0985\u09a8\u09b2\u09be\u0987\u09a8 \u09a1\u09be\u099f\u09be \u09b8\u09bf\u0982\u0995 \u09b9\u099a\u09cd\u099b\u09c7...',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: glass.accentSoft,
                                        fontSize: 10.8,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pushNamed(RouteNames.islamicCalendar),
                                  style: IconButton.styleFrom(
                                    backgroundColor: glass.isDark
                                        ? const Color(0x332EB8E6)
                                        : const Color(0x221EA8B8),
                                    foregroundColor: glass.accent,
                                  ),
                                  icon: const Icon(
                                    Icons.calendar_today_rounded,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: _isRefreshing ? null : _refresh,
                                  style: IconButton.styleFrom(
                                    backgroundColor: glass.isDark
                                        ? const Color(0x332EB8E6)
                                        : const Color(0x221EA8B8),
                                    foregroundColor: glass.accent,
                                  ),
                                  icon: _isRefreshing
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: glass.accent,
                                          ),
                                        )
                                      : const Icon(Icons.refresh_rounded),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      NoorifyGlassCard(
                        radius: BorderRadius.circular(24),
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                        child: _isLoading
                            ? SizedBox(
                                height: 130,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: glass.accent,
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _text(
                                            'Next Prayer',
                                            '\u09aa\u09b0\u09ac\u09b0\u09cd\u09a4\u09c0 \u09b8\u09be\u09b2\u09be\u09a4',
                                          ),
                                          style: TextStyle(
                                            color: glass.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: glass.isDark
                                              ? const Color(0x222EB8E6)
                                              : const Color(0x251EA8B8),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: glass.glassBorder,
                                          ),
                                        ),
                                        child: Text(
                                          _localizedPrayer(_activePrayer),
                                          style: TextStyle(
                                            color: glass.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatRemaining(),
                                    style: TextStyle(
                                      color: glass.accentSoft,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    _text(
                                      'remaining',
                                      '\u09ac\u09be\u0995\u09bf',
                                    ),
                                    style: TextStyle(
                                      color: glass.textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: LinearProgressIndicator(
                                      value: ringProgress,
                                      minHeight: 8,
                                      backgroundColor: glass.isDark
                                          ? const Color(0x2A9EE7F4)
                                          : const Color(0x331EA8B8),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        glass.accent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${_text('At', '\u09b8\u09ae\u09df')}: ${_formatTime(_nextPrayerAt)}',
                                          style: TextStyle(
                                            color: glass.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 15,
                                        color: glass.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _locationLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: glass.textSecondary,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (_usingFallbackLocation ||
                                      _usingOfflineCalculation)
                                    Text(
                                      _usingOfflineCalculation
                                          ? _text(
                                              'Using offline prayer calculation',
                                              '\u0985\u09ab\u09b2\u09be\u0987\u09a8 \u09b8\u09be\u09b2\u09be\u09a4 \u09b9\u09bf\u09b8\u09be\u09ac \u099a\u09b2\u099b\u09c7',
                                            )
                                          : _text(
                                              'Using saved location',
                                              '\u09b8\u0982\u09b0\u0995\u09cd\u09b7\u09bf\u09a4 \u09b2\u09cb\u0995\u09c7\u09b6\u09a8 \u09ac\u09cd\u09af\u09ac\u09b9\u09be\u09b0 \u09b9\u099a\u09cd\u099b\u09c7',
                                            ),
                                      style: TextStyle(
                                        color: glass.textSecondary,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 12),
                      NoorifyGlassCard(
                        radius: BorderRadius.circular(20),
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _text(
                                "Today's Schedule",
                                '\u0986\u099c\u0995\u09c7\u09b0 \u09b8\u09ae\u09df\u09b8\u09c2\u099a\u09bf',
                              ),
                              style: TextStyle(
                                color: glass.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ..._prayerCards().map((item) {
                              final isActive = item.key == _activePrayer;
                              return _PrayerTimeCard(
                                title: _localizedPrayer(item.key),
                                subtitle: item.subtitle,
                                time: _formatTime(item.time),
                                icon: item.icon,
                                isActive: isActive,
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      NoorifyGlassCard(
                        radius: BorderRadius.circular(20),
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _text(
                                "Today's Highlights",
                                '\u0986\u099c\u0995\u09c7\u09b0 \u0997\u09c1\u09b0\u09c1\u09a4\u09cd\u09ac\u09aa\u09c2\u09b0\u09cd\u09a3 \u09b8\u09ae\u09df',
                              ),
                              style: TextStyle(
                                color: glass.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ..._dayHighlights().map(
                              (item) => _PrayerHighlightTile(
                                label: item.label,
                                icon: item.icon,
                                time: _formatTime(item.time),
                                emphasized: item.emphasized,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                side: BorderSide(color: glass.glassBorder),
                                foregroundColor: glass.textPrimary,
                              ),
                              onPressed: () => Navigator.of(
                                context,
                              ).pushNamed(RouteNames.prayerCompass),
                              icon: const Icon(Icons.explore_rounded),
                              label: Text(
                                _text(
                                  'Open Qibla',
                                  '\u0995\u09bf\u09ac\u09b2\u09be \u0996\u09c1\u09b2\u09c1\u09a8',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                side: BorderSide(color: glass.glassBorder),
                                foregroundColor: glass.textPrimary,
                              ),
                              onPressed: () => Navigator.of(
                                context,
                              ).pushNamed(RouteNames.islamicCalendar),
                              icon: const Icon(Icons.calendar_month_rounded),
                              label: Text(
                                _text(
                                  'Calendar',
                                  '\u0995\u09cd\u09af\u09be\u09b2\u09c7\u09a8\u09cd\u09a1\u09be\u09b0',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                backgroundColor: glass.accent,
                                foregroundColor: glass.isDark
                                    ? const Color(0xFF082733)
                                    : Colors.white,
                              ),
                              onPressed: _isRefreshing ? null : _refresh,
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(
                                _text(
                                  'Refresh',
                                  '\u09b0\u09bf\u09ab\u09cd\u09b0\u09c7\u09b6',
                                ),
                              ),
                            ),
                          ),
                        ],
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

class _PrayerHighlightTile extends StatelessWidget {
  const _PrayerHighlightTile({
    required this.label,
    required this.icon,
    required this.time,
    required this.emphasized,
  });

  final String label;
  final IconData icon;
  final String time;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: emphasized
            ? (glass.isDark ? const Color(0x2038D4C7) : const Color(0x1A1EA8B8))
            : (glass.isDark
                  ? const Color(0x161A3345)
                  : const Color(0x75FFFFFF)),
        border: Border.all(
          color: emphasized
              ? glass.accent.withValues(alpha: 0.72)
              : glass.glassBorder.withValues(alpha: 0.7),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 18, color: glass.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: glass.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: emphasized ? glass.accent : glass.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerTimeCard extends StatelessWidget {
  const _PrayerTimeCard({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.isActive,
  });

  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isActive
            ? (glass.isDark ? const Color(0x2038D4C7) : const Color(0x1A1EA8B8))
            : (glass.isDark
                  ? const Color(0x161A3345)
                  : const Color(0x75FFFFFF)),
        border: Border.all(
          color: isActive
              ? glass.accent.withValues(alpha: 0.72)
              : glass.glassBorder.withValues(alpha: 0.7),
          width: isActive ? 1.2 : 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: glass.accent.withValues(alpha: isActive ? 0.22 : 0.14),
            ),
            child: Icon(icon, size: 19, color: glass.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: glass.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: glass.textSecondary,
                    fontSize: 11.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: isActive ? glass.accent : glass.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_circle_rounded, size: 16, color: glass.accent),
          ],
        ],
      ),
    );
  }
}
