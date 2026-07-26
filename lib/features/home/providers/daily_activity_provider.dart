import 'dart:async';
import 'dart:math' as math;

import 'package:adhan_dart/adhan_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:first_project/features/home/models/home_activity_models.dart';

import 'package:first_project/features/quran/models/quran_models.dart';
import 'package:first_project/features/quran/services/quran_api_service.dart';
import 'package:first_project/features/quran/services/quran_last_read_service.dart';
import 'package:first_project/shared/services/app_globals.dart';

class ActivePrayerData {
  ActivePrayerData({
    required this.name,
    required this.countdownLabel,
    required this.remaining,
    required this.progress,
  });

  final String name;
  final String countdownLabel;
  final Duration remaining;
  final double progress;
}

class RamadanMealData {
  RamadanMealData({required this.nextSehri, required this.nextIftar});

  final DateTime nextSehri;
  final DateTime nextIftar;
}

class DailyActivityProvider extends ChangeNotifier {
  static const double _kaabaLat = 21.422487;
  static const double _kaabaLng = 39.826206;
  static const double _baitulMukarramLat = 23.7286;
  static const double _baitulMukarramLng = 90.4106;
  static const String _baitulMukarramLabel = 'Baitul Mukarram, Dhaka';
  static const int _apiMethod = 1;
  static const int _apiSchool = 1;
  static const int prayerCarouselSeed = 1000;
  static const int prayerCarouselItemCount = 10000;
  static const List<String> prayerOrder = <String>[
    'Fajr',
    'Zuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  DailyActivityProvider() {
    appLanguageNotifier.addListener(_onLanguageChanged);
    useDeviceLocationNotifier.addListener(_onUseDeviceLocationChanged);
    profileLocationNotifier.addListener(_onProfileLocationChanged);
    prayerAlertsEnabledNotifier.addListener(_onPrayerAlertToggleChanged);
    sehriAlertEnabledNotifier.addListener(_onSehriAlertToggleChanged);
    iftarAlertEnabledNotifier.addListener(_onIftarAlertToggleChanged);
    alertToneNotifier.addListener(_onAlertToneChanged);

    _setBaitulMukarramLocation(initial: true);
    _seedInitialPrayerPreview();
    _initializeMiniCompass();
    unawaited(_loadPrayerData());
    if (kQuranFeatureEnabled) {
      unawaited(loadLastReadCard());
    }

    _clockTimer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  bool _disposed = false;

  // Time & schedule state
  DateTime _now = DateTime.now();
  double? _latitude;
  double? _longitude;
  bool _isFetchingPrayerSchedule = false;
  bool _ignoreNextLocationToggleChange = false;
  DailyPrayerSchedule? _todaySchedule;
  DailyPrayerSchedule? _tomorrowSchedule;
  DateTime? _lastPrayerCalcDate;
  DateTime? _nextSehriAt;
  DateTime? _nextIftarAt;
  bool _isRefreshingLocation = false;
  String _locationLabel = _baitulMukarramLabel;
  String _countdownLabel = 'Fajr in --:--:--';
  String _activePrayer = 'Zuhr';
  Duration _activeRemaining = Duration.zero;
  double _activeProgress = 0.0;
  Map<String, String> _prayerTimes = const {
    'Fajr': '--:--',
    'Zuhr': '--:--',
    'Asr': '--:--',
    'Maghrib': '--:--',
    'Isha': '--:--',
  };

  // Daily activity static state
  final int _completedDaily = 3;
  final int _dailyGoal = 6;
  final List<ActivityItem> _activities = [
    ActivityItem(title: 'Alms', done: 4, total: 10),
    ActivityItem(title: 'Recite the Al Quran', done: 8, total: 10),
  ];

  // Compass state
  StreamSubscription<CompassEvent>? _homeCompassSub;
  double? _homeHeading;
  double? _homeQiblaBearing;

  // Prayer carousel state
  String? _selectedPrayer;

  // Quran last read state
  int? _lastReadSurahNo;
  QuranChapter? _lastReadChapter;

  // Async services
  final QuranLastReadService _lastReadService = QuranLastReadService();
  final QuranApiService _quranApiService = QuranApiService();

  final Dio _prayerApi = Dio(
    BaseOptions(
      baseUrl: 'https://api.aladhan.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
    ),
  );

  Timer? _clockTimer;

  // Inter-screen messaging (one-shot snackbar text)
  String? _pendingMessage;
  String? get pendingMessage => _pendingMessage;
  void consumePendingMessage() {
    _pendingMessage = null;
  }

  // Getters
  DateTime get now => _now;
  String get locationLabel => _locationLabel;
  String get countdownLabel => _countdownLabel;
  String get activePrayer => _activePrayer;
  Duration get activeRemaining => _activeRemaining;
  double get activeProgress => _activeProgress;
  Map<String, String> get prayerTimes => _prayerTimes;
  DateTime? get nextSehriAt => _nextSehriAt;
  DateTime? get nextIftarAt => _nextIftarAt;
  int get completedDaily => _completedDaily;
  int get dailyGoal => _dailyGoal;
  List<ActivityItem> get activities => List.unmodifiable(_activities);
  double? get homeHeading => _homeHeading;
  double? get homeQiblaBearing => _homeQiblaBearing;
  String? get selectedPrayer => _selectedPrayer;
  int? get lastReadSurahNo => _lastReadSurahNo;
  QuranChapter? get lastReadChapter => _lastReadChapter;

  String get displayPrayer => _selectedPrayer ?? _activePrayer;
  bool get isShowingActivePrayer => displayPrayer == _activePrayer;

  bool get _isBangla => appLanguageNotifier.value == AppLanguage.bangla;

  // Helpers
  static double _normalizeDegrees(double degrees) {
    final normalized = degrees % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  static double signedQiblaDelta(double target, double current) {
    return ((target - current + 540) % 360) - 180;
  }

  String _profileOrFallbackLocationLabel() {
    final value = profileLocationNotifier.value.trim();
    if (value.isNotEmpty) return value;
    return _baitulMukarramLabel;
  }

  String _formatPrayerTime(DateTime time) {
    final h = (time.hour % 12 == 0 ? 12 : time.hour % 12).toString();
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // Notifier listeners
  void _onLanguageChanged() => _safeNotify();

  void _onProfileLocationChanged() {
    if (useDeviceLocationNotifier.value) return;
    final label = _profileOrFallbackLocationLabel();
    if (_locationLabel == label) return;
    _locationLabel = label;
    _safeNotify();
  }

  Future<void> _onUseDeviceLocationChanged() async {
    if (_ignoreNextLocationToggleChange) {
      _ignoreNextLocationToggleChange = false;
      return;
    }
    await _loadPrayerData();
    _safeNotify();
  }

  void _setUseDeviceLocationSilently(bool value) {
    if (useDeviceLocationNotifier.value == value) return;
    _ignoreNextLocationToggleChange = true;
    useDeviceLocationNotifier.value = value;
  }

  Future<void> _onSehriAlertToggleChanged() async {
    if (sehriAlertEnabledNotifier.value) {
      if (_nextSehriAt != null) {
        await _scheduleSehriNotification(_nextSehriAt!);
      }
    } else {
      await _cancelSehriNotification();
    }
    _safeNotify();
  }

  Future<void> _onPrayerAlertToggleChanged() async {
    await _refreshPrayerAlertScheduling();
    _safeNotify();
  }

  Future<void> _onIftarAlertToggleChanged() async {
    if (iftarAlertEnabledNotifier.value) {
      if (_nextIftarAt != null) {
        await _scheduleIftarNotification(_nextIftarAt!);
      }
    } else {
      await _cancelIftarNotification();
    }
    _safeNotify();
  }

  void _onAlertToneChanged() {
    unawaited(_refreshAllAlertSchedulesForToneChange());
    _safeNotify();
  }

  Future<void> _refreshAllAlertSchedulesForToneChange() async {
    await _refreshPrayerAlertScheduling();
    await _refreshMealAlertScheduling();
  }

  // Clock tick
  void _onTick(Timer _) {
    if (_disposed) return;
    _now = DateTime.now();
    _updateCountdown();
    _safeNotify();
    if (_lastPrayerCalcDate == null ||
        _lastPrayerCalcDate!.day != _now.day ||
        _lastPrayerCalcDate!.month != _now.month ||
        _lastPrayerCalcDate!.year != _now.year) {
      _recalculatePrayerTimesForToday();
    }
  }

  // Compass
  void _initializeMiniCompass() {
    _homeCompassSub?.cancel();
    final stream = FlutterCompass.events;
    if (stream == null) {
      _homeHeading = null;
      return;
    }
    _homeCompassSub = stream.listen(
      (event) {
        final heading = event.heading;
        if (heading == null || heading.isNaN) return;
        _homeHeading = _normalizeDegrees(heading);
        _safeNotify();
      },
      onError: (_) {
        _homeHeading = null;
        _safeNotify();
      },
    );
  }

  void _updateHomeQiblaBearing(double lat, double lng) {
    _homeQiblaBearing = _calculateQiblaBearingBasic(lat: lat, lng: lng);
  }

  double _calculateQiblaBearingBasic({
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
    return _normalizeDegrees(bearing);
  }

  // Carousel
  String prayerForCarouselIndex(int index) {
    final len = prayerOrder.length;
    final normalized = ((index % len) + len) % len;
    return prayerOrder[normalized];
  }

  int carouselIndexForPrayer(String prayer, {int? around}) {
    final prayerIndex = prayerOrder.indexOf(prayer);
    if (prayerIndex == -1) return prayerCarouselSeed * prayerOrder.length;
    final len = prayerOrder.length;
    if (around == null) {
      return (prayerCarouselSeed * len) + prayerIndex;
    }
    final base = around - (around % len);
    final candidates = <int>[
      base + prayerIndex,
      base + prayerIndex + len,
      base + prayerIndex - len,
    ];
    candidates.sort((a, b) => (a - around).abs().compareTo((b - around).abs()));
    return candidates.first;
  }

  void setSelectedPrayer(String? prayer) {
    if (_selectedPrayer == prayer) return;
    _selectedPrayer = prayer;
    _safeNotify();
  }

  // Location & prayer data load
  Future<void> _loadPrayerData() async {
    if (!useDeviceLocationNotifier.value) {
      _setBaitulMukarramLocation();
      await _refreshPrayerScheduleFromSource(forceRefresh: true);
      return;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setUseDeviceLocationSilently(false);
        _setBaitulMukarramLocation();
        await _refreshPrayerScheduleFromSource(forceRefresh: true);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setUseDeviceLocationSilently(false);
        _setBaitulMukarramLocation();
        await _refreshPrayerScheduleFromSource(forceRefresh: true);
        return;
      }

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).timeout(const Duration(seconds: 8));
      } catch (_) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown == null) rethrow;
        position = lastKnown;
      }

      _latitude = position.latitude;
      _longitude = position.longitude;
      _updateHomeQiblaBearing(position.latitude, position.longitude);
      await _resolveLocationLabel(position.latitude, position.longitude);
    } catch (e) {
      _setBaitulMukarramLocation();
      _pendingMessage =
          'Could not read current location. Using fallback temporarily.';
      _safeNotify();
      debugPrint('Device location fetch failed: $e');
    }

    await _refreshPrayerScheduleFromSource(forceRefresh: true);
  }

  void _setBaitulMukarramLocation({bool initial = false}) {
    _latitude = _baitulMukarramLat;
    _longitude = _baitulMukarramLng;
    _updateHomeQiblaBearing(_baitulMukarramLat, _baitulMukarramLng);
    _locationLabel = _profileOrFallbackLocationLabel();
    if (!initial) _safeNotify();
  }

  Future<void> _resolveLocationLabel(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty || _disposed) return;
      final place = placemarks.first;
      final city =
          place.locality ??
          place.subAdministrativeArea ??
          place.administrativeArea ??
          'Current location';
      final area = place.administrativeArea ?? place.country ?? '';
      final label = area.isNotEmpty ? '$city, $area' : city;
      _locationLabel = label;
      _safeNotify();
      if (profileLocationNotifier.value != label) {
        profileLocationNotifier.value = label;
        await saveAppPreferences();
      }
    } catch (_) {
      _locationLabel = 'Current location';
      _safeNotify();
    }
  }

  Future<void> refreshLocationFromHeader() async {
    if (_isRefreshingLocation) return;
    _isRefreshingLocation = true;
    try {
      _setUseDeviceLocationSilently(true);
      await _loadPrayerData();
      await saveAppPreferences();
      if (_disposed) return;
      _pendingMessage = 'Prayer times updated for $_locationLabel';
      _safeNotify();
    } finally {
      _isRefreshingLocation = false;
    }
  }

  Future<void> refreshPrayerScheduleFromSource({
    required bool forceRefresh,
  }) async {
    await _refreshPrayerScheduleFromSource(forceRefresh: forceRefresh);
  }

  Future<void> _refreshPrayerScheduleFromSource({
    required bool forceRefresh,
  }) async {
    if (_disposed) return;
    if (_isFetchingPrayerSchedule) return;
    final today = DateTime(_now.year, _now.month, _now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final alreadyLoaded =
        _todaySchedule != null &&
        _tomorrowSchedule != null &&
        _isSameDate(_todaySchedule!.date, today) &&
        _isSameDate(_tomorrowSchedule!.date, tomorrow);
    if (!forceRefresh && alreadyLoaded) return;

    _isFetchingPrayerSchedule = true;
    try {
      final results = await Future.wait<DailyPrayerSchedule>([
        _fetchPrayerScheduleFromApi(today),
        _fetchPrayerScheduleFromApi(tomorrow),
      ]);
      _todaySchedule = results[0];
      _tomorrowSchedule = results[1];
    } catch (_) {
      _todaySchedule = _buildFallbackSchedule(today);
      _tomorrowSchedule = _buildFallbackSchedule(tomorrow);
      if (forceRefresh) {
        _pendingMessage = 'Using offline calculated prayer times';
      }
    } finally {
      _isFetchingPrayerSchedule = false;
    }

    if (_disposed) return;
    _recalculatePrayerTimesForToday();
  }

  Future<DailyPrayerSchedule> _fetchPrayerScheduleFromApi(DateTime date) async {
    final latitude = _latitude ?? _baitulMukarramLat;
    final longitude = _longitude ?? _baitulMukarramLng;
    final response = await _prayerApi.get(
      '/v1/timings/${_formatApiDate(date)}',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'method': _apiMethod,
        'school': _apiSchool,
      },
    );

    final root = response.data;
    if (root is! Map) {
      throw const FormatException('Invalid prayer response root');
    }
    final data = root['data'];
    if (data is! Map) {
      throw const FormatException('Invalid prayer response data');
    }
    final timings = data['timings'];
    if (timings is! Map) {
      throw const FormatException('Invalid prayer response timings');
    }

    String valueFor(String key) => (timings[key] ?? '').toString();
    return DailyPrayerSchedule(
      date: DateTime(date.year, date.month, date.day),
      imsak: _parseApiTime(date, valueFor('Imsak')),
      fajr: _parseApiTime(date, valueFor('Fajr')),
      dzuhr: _parseApiTime(date, valueFor('Dhuhr')),
      ashr: _parseApiTime(date, valueFor('Asr')),
      maghrib: _parseApiTime(date, valueFor('Maghrib')),
      isha: _parseApiTime(date, valueFor('Isha')),
    );
  }

  String _formatApiDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd-$mm-${date.year}';
  }

  DateTime _parseApiTime(DateTime date, String raw) {
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
    if (match == null) {
      throw FormatException('Invalid prayer time: $raw');
    }
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DailyPrayerSchedule _buildFallbackSchedule(DateTime date) {
    final prayers = _prayerTimesForDate(date);
    return DailyPrayerSchedule(
      date: DateTime(date.year, date.month, date.day),
      imsak: prayers.fajr.toLocal(),
      fajr: prayers.fajr.toLocal(),
      dzuhr: prayers.dhuhr.toLocal(),
      ashr: prayers.asr.toLocal(),
      maghrib: prayers.maghrib.toLocal(),
      isha: prayers.isha.toLocal(),
    );
  }

  CalculationParameters _buildCalculationParams() {
    final params = CalculationMethodParameters.karachi();
    params.madhab = Madhab.hanafi;
    return params;
  }

  PrayerTimes _prayerTimesForDate(DateTime date) {
    final latitude = _latitude ?? _baitulMukarramLat;
    final longitude = _longitude ?? _baitulMukarramLng;
    return PrayerTimes(
      date: date,
      coordinates: Coordinates(latitude, longitude),
      calculationParameters: _buildCalculationParams(),
    );
  }

  RamadanMealData _buildRamadanMealData({
    required DateTime now,
    required DateTime sehri,
    required DateTime maghrib,
    required DateTime tomorrowSehri,
    required DateTime tomorrowMaghrib,
  }) {
    final nextSehri = now.isBefore(sehri) ? sehri : tomorrowSehri;
    final nextIftar = now.isBefore(maghrib) ? maghrib : tomorrowMaghrib;
    return RamadanMealData(nextSehri: nextSehri, nextIftar: nextIftar);
  }

  void _seedInitialPrayerPreview() {
    final today = DateTime(_now.year, _now.month, _now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final todaySchedule = _buildFallbackSchedule(today);
    final tomorrowSchedule = _buildFallbackSchedule(tomorrow);

    final activeData = _buildActivePrayerData(
      now: _now,
      fajr: todaySchedule.fajr,
      dzuhr: todaySchedule.dzuhr,
      ashr: todaySchedule.ashr,
      maghrib: todaySchedule.maghrib,
      isha: todaySchedule.isha,
      ishaBefore: todaySchedule.isha.subtract(const Duration(days: 1)),
    );

    final mealData = _buildRamadanMealData(
      now: _now,
      sehri: todaySchedule.imsak,
      maghrib: todaySchedule.maghrib,
      tomorrowSehri: tomorrowSchedule.imsak,
      tomorrowMaghrib: tomorrowSchedule.maghrib,
    );

    _todaySchedule = todaySchedule;
    _tomorrowSchedule = tomorrowSchedule;
    _lastPrayerCalcDate = today;
    _prayerTimes = {
      'Fajr': _formatPrayerTime(todaySchedule.fajr),
      'Zuhr': _formatPrayerTime(todaySchedule.dzuhr),
      'Asr': _formatPrayerTime(todaySchedule.ashr),
      'Maghrib': _formatPrayerTime(todaySchedule.maghrib),
      'Isha': _formatPrayerTime(todaySchedule.isha),
    };
    _activePrayer = activeData.name;
    _countdownLabel = activeData.countdownLabel;
    _activeRemaining = activeData.remaining;
    _activeProgress = activeData.progress;
    _nextSehriAt = mealData.nextSehri;
    _nextIftarAt = mealData.nextIftar;
  }

  void _recalculatePrayerTimesForToday() {
    if (_disposed) return;
    final today = DateTime(_now.year, _now.month, _now.day);
    final scheduleToday = _todaySchedule;
    final scheduleTomorrow = _tomorrowSchedule;
    if (scheduleToday == null ||
        scheduleTomorrow == null ||
        !_isSameDate(scheduleToday.date, today)) {
      unawaited(_refreshPrayerScheduleFromSource(forceRefresh: true));
      return;
    }

    final fajr = scheduleToday.fajr;
    final dzuhr = scheduleToday.dzuhr;
    final ashr = scheduleToday.ashr;
    final maghrib = scheduleToday.maghrib;
    final isha = scheduleToday.isha;
    final ishaBefore = scheduleToday.isha.subtract(const Duration(days: 1));
    final mealData = _buildRamadanMealData(
      now: _now,
      sehri: scheduleToday.imsak,
      maghrib: maghrib,
      tomorrowSehri: scheduleTomorrow.imsak,
      tomorrowMaghrib: scheduleTomorrow.maghrib,
    );
    final activeData = _buildActivePrayerData(
      now: _now,
      fajr: fajr,
      dzuhr: dzuhr,
      ashr: ashr,
      maghrib: maghrib,
      isha: isha,
      ishaBefore: ishaBefore,
    );

    _lastPrayerCalcDate = today;
    _prayerTimes = {
      'Fajr': _formatPrayerTime(fajr),
      'Zuhr': _formatPrayerTime(dzuhr),
      'Asr': _formatPrayerTime(ashr),
      'Maghrib': _formatPrayerTime(maghrib),
      'Isha': _formatPrayerTime(isha),
    };
    _activePrayer = activeData.name;
    _countdownLabel = activeData.countdownLabel;
    _activeRemaining = activeData.remaining;
    _activeProgress = activeData.progress;
    _nextSehriAt = mealData.nextSehri;
    _nextIftarAt = mealData.nextIftar;
    _safeNotify();
    _refreshMealAlertScheduling();
    _refreshPrayerAlertScheduling();
  }

  void _updateCountdown() {
    if (_prayerTimes['Fajr'] == '--:--') return;
    final today = DateTime(_now.year, _now.month, _now.day);
    final scheduleToday = _todaySchedule;
    final scheduleTomorrow = _tomorrowSchedule;
    if (scheduleToday == null ||
        scheduleTomorrow == null ||
        !_isSameDate(scheduleToday.date, today)) {
      if (!_isFetchingPrayerSchedule) {
        unawaited(_refreshPrayerScheduleFromSource(forceRefresh: true));
      }
      return;
    }

    final fajr = scheduleToday.fajr;
    final dzuhr = scheduleToday.dzuhr;
    final ashr = scheduleToday.ashr;
    final maghrib = scheduleToday.maghrib;
    final isha = scheduleToday.isha;
    final ishaBefore = scheduleToday.isha.subtract(const Duration(days: 1));
    final mealData = _buildRamadanMealData(
      now: _now,
      sehri: scheduleToday.imsak,
      maghrib: maghrib,
      tomorrowSehri: scheduleTomorrow.imsak,
      tomorrowMaghrib: scheduleTomorrow.maghrib,
    );
    final activeData = _buildActivePrayerData(
      now: _now,
      fajr: fajr,
      dzuhr: dzuhr,
      ashr: ashr,
      maghrib: maghrib,
      isha: isha,
      ishaBefore: ishaBefore,
    );
    final mealsChanged =
        mealData.nextSehri != _nextSehriAt ||
        mealData.nextIftar != _nextIftarAt;

    if (activeData.name != _activePrayer ||
        activeData.countdownLabel != _countdownLabel ||
        activeData.progress != _activeProgress ||
        activeData.remaining != _activeRemaining ||
        mealsChanged) {
      _activePrayer = activeData.name;
      _countdownLabel = activeData.countdownLabel;
      _activeRemaining = activeData.remaining;
      _activeProgress = activeData.progress;
      _nextSehriAt = mealData.nextSehri;
      _nextIftarAt = mealData.nextIftar;
      if (mealsChanged) _refreshMealAlertScheduling();
    }
  }

  ActivePrayerData _buildActivePrayerData({
    required DateTime now,
    required DateTime fajr,
    required DateTime dzuhr,
    required DateTime ashr,
    required DateTime maghrib,
    required DateTime isha,
    required DateTime ishaBefore,
  }) {
    final schedule = <MapEntry<String, DateTime>>[
      MapEntry('Fajr', fajr),
      MapEntry('Zuhr', dzuhr),
      MapEntry('Asr', ashr),
      MapEntry('Maghrib', maghrib),
      MapEntry('Isha', isha),
    ];

    MapEntry<String, DateTime>? activePrayer;
    int activeIndex = -1;
    for (int i = 0; i < schedule.length; i++) {
      if (schedule[i].value.isAfter(now)) {
        activePrayer = schedule[i];
        activeIndex = i;
        break;
      }
    }

    DateTime previousBoundary;
    if (activePrayer == null) {
      activePrayer = MapEntry('Fajr', fajr.add(const Duration(days: 1)));
      previousBoundary = isha;
    } else if (activeIndex == 0) {
      previousBoundary = ishaBefore;
    } else {
      previousBoundary = schedule[activeIndex - 1].value;
    }

    final remaining = activePrayer.value.difference(now);
    final totalWindow = activePrayer.value.difference(previousBoundary);
    final elapsed = totalWindow - remaining;
    final progress = totalWindow.inMilliseconds <= 0
        ? 0.0
        : (elapsed.inMilliseconds / totalWindow.inMilliseconds).clamp(0.0, 1.0);
    final hh = remaining.inHours.toString().padLeft(2, '0');
    final mm = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return ActivePrayerData(
      name: activePrayer.key,
      countdownLabel: '${activePrayer.key} in $hh:$mm:$ss',
      remaining: remaining.isNegative ? Duration.zero : remaining,
      progress: progress,
    );
  }

  // Notifications scheduling
  Future<void> _scheduleMealNotification({
    required int id,
    required String channelId,
    required String channelName,
    required String channelDescription,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (!localNotificationsInitialized) return;
    _ensureTimezoneInitializedForScheduling();
    var scheduled = tz.TZDateTime.from(at, tz.local);
    final nowTz = tz.TZDateTime.now(tz.local);
    if (scheduled.isBefore(nowTz)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final tone = alertToneNotifier.value;
    NotificationDetails detailsForTone(AppAlertTone value) {
      final valuePlaySound = alertTonePlaySound(value);
      return NotificationDetails(
        android: AndroidNotificationDetails(
          channelIdForTone(channelId, tone: value),
          channelName,
          channelDescription: '$channelDescription (${alertToneLabel(value)})',
          importance: Importance.max,
          priority: Priority.high,
          playSound: valuePlaySound,
          sound: alertToneSound(value),
          audioAttributesUsage: alertToneUsage(value),
        ),
        iOS: DarwinNotificationDetails(presentSound: valuePlaySound),
      );
    }

    Future<void> scheduleWithDetails(
      NotificationDetails details, {
      required AndroidScheduleMode mode,
    }) async {
      await localNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: mode,
        payload: payload,
      );
    }

    final details = detailsForTone(tone);

    try {
      await scheduleWithDetails(
        details,
        mode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        await scheduleWithDetails(
          details,
          mode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } else if (tone == AppAlertTone.adhan) {
        final fallback = detailsForTone(AppAlertTone.appDefault);
        try {
          await scheduleWithDetails(
            fallback,
            mode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } on PlatformException catch (fallbackError) {
          if (fallbackError.code == 'exact_alarms_not_permitted') {
            await scheduleWithDetails(
              fallback,
              mode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
          } else {
            rethrow;
          }
        }
      } else {
        rethrow;
      }
    }
  }

  void _ensureTimezoneInitializedForScheduling() {
    try {
      tz.local;
    } catch (_) {
      try {
        tz_data.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }
  }

  String _localizedSehriAlertTitle() => _isBangla
      ? 'সেহরি এলার্ট'
      : 'Sehri Alert';
  String _localizedSehriAlertBody() => _isBangla
      ? 'সেহরির সময় হয়েছে।'
      : 'It is time for Sehri.';
  String _localizedIftarAlertTitle() => _isBangla
      ? 'ইফতার এলার্ট'
      : 'Iftar Alert';
  String _localizedIftarAlertBody() => _isBangla
      ? 'ইফতারের সময় হয়েছে।'
      : 'It is time for Iftar.';

  Future<void> _scheduleSehriNotification(DateTime sehriTime) async {
    if (!sehriAlertEnabledNotifier.value) return;
    await _scheduleMealNotification(
      id: sehriNotificationId,
      channelId: 'sehri_alert_channel',
      channelName: 'Sehri Alerts',
      channelDescription: 'Alert when Sehri time starts',
      at: sehriTime,
      title: _localizedSehriAlertTitle(),
      body: _localizedSehriAlertBody(),
      payload: 'sehri',
    );
  }

  Future<void> _schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime at,
  }) async {
    if (!prayerAlertsEnabledNotifier.value) return;
    await _scheduleMealNotification(
      id: id,
      channelId: 'prayer_alert_channel',
      channelName: 'Prayer Alerts',
      channelDescription: 'Alert when prayer time starts',
      at: at,
      title: '$prayerName Prayer Alert',
      body: 'It is time for $prayerName prayer.',
      payload: 'prayer_${prayerName.toLowerCase()}',
    );
  }

  Future<void> _cancelPrayerNotifications() async {
    if (!localNotificationsInitialized) return;
    await localNotificationsPlugin.cancel(fajrNotificationId);
    await localNotificationsPlugin.cancel(dzuhrNotificationId);
    await localNotificationsPlugin.cancel(ashrNotificationId);
    await localNotificationsPlugin.cancel(maghribNotificationId);
    await localNotificationsPlugin.cancel(ishaNotificationId);
  }

  Future<void> _refreshPrayerAlertScheduling() async {
    try {
      if (!prayerAlertsEnabledNotifier.value) {
        await _cancelPrayerNotifications();
        return;
      }
      final schedule = _todaySchedule;
      if (schedule == null) return;
      await _schedulePrayerNotification(
        id: fajrNotificationId,
        prayerName: 'Fajr',
        at: schedule.fajr,
      );
      await _schedulePrayerNotification(
        id: dzuhrNotificationId,
        prayerName: 'Zuhr',
        at: schedule.dzuhr,
      );
      await _schedulePrayerNotification(
        id: ashrNotificationId,
        prayerName: 'Asr',
        at: schedule.ashr,
      );
      await _schedulePrayerNotification(
        id: maghribNotificationId,
        prayerName: 'Maghrib',
        at: schedule.maghrib,
      );
      await _schedulePrayerNotification(
        id: ishaNotificationId,
        prayerName: 'Isha',
        at: schedule.isha,
      );
    } catch (e) {
      debugPrint('Prayer alert scheduling failed: $e');
    }
  }

  Future<void> _scheduleIftarNotification(DateTime iftarTime) async {
    if (!iftarAlertEnabledNotifier.value) return;
    await _scheduleMealNotification(
      id: iftarNotificationId,
      channelId: 'iftar_alert_channel',
      channelName: 'Iftar Alerts',
      channelDescription: 'Alert when Iftar time starts',
      at: iftarTime,
      title: _localizedIftarAlertTitle(),
      body: _localizedIftarAlertBody(),
      payload: 'iftar',
    );
  }

  Future<void> _cancelSehriNotification() async {
    if (!localNotificationsInitialized) return;
    await localNotificationsPlugin.cancel(sehriNotificationId);
  }

  Future<void> _cancelIftarNotification() async {
    if (!localNotificationsInitialized) return;
    await localNotificationsPlugin.cancel(iftarNotificationId);
  }

  Future<void> _refreshMealAlertScheduling() async {
    try {
      if (_nextSehriAt != null) {
        if (sehriAlertEnabledNotifier.value) {
          await _scheduleSehriNotification(_nextSehriAt!);
        } else {
          await _cancelSehriNotification();
        }
      }
      if (_nextIftarAt != null) {
        if (iftarAlertEnabledNotifier.value) {
          await _scheduleIftarNotification(_nextIftarAt!);
        } else {
          await _cancelIftarNotification();
        }
      }
    } catch (e) {
      debugPrint('Meal alert scheduling failed: $e');
    }
  }

  // Last read
  Future<void> loadLastReadCard() async {
    if (!kQuranFeatureEnabled) {
      if (_disposed) return;
      _lastReadSurahNo = null;
      _lastReadChapter = null;
      _safeNotify();
      return;
    }

    final savedSurahNo = await _lastReadService.readLastReadSurahNo();
    if (_disposed) return;

    if (savedSurahNo == null) {
      _lastReadSurahNo = null;
      _lastReadChapter = null;
      _safeNotify();
      return;
    }

    QuranChapter? chapter;
    try {
      final chapters = await _quranApiService.fetchChapters();
      for (final item in chapters) {
        if (item.surahNo == savedSurahNo) {
          chapter = item;
          break;
        }
      }
    } catch (_) {}

    if (_disposed) return;
    _lastReadSurahNo = savedSurahNo;
    _lastReadChapter = chapter;
    _safeNotify();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    appLanguageNotifier.removeListener(_onLanguageChanged);
    useDeviceLocationNotifier.removeListener(_onUseDeviceLocationChanged);
    profileLocationNotifier.removeListener(_onProfileLocationChanged);
    prayerAlertsEnabledNotifier.removeListener(_onPrayerAlertToggleChanged);
    sehriAlertEnabledNotifier.removeListener(_onSehriAlertToggleChanged);
    iftarAlertEnabledNotifier.removeListener(_onIftarAlertToggleChanged);
    alertToneNotifier.removeListener(_onAlertToneChanged);
    _homeCompassSub?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }
}
