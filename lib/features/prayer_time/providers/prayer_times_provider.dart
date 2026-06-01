import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:first_project/features/prayer_time/services/prayer_schedule_service.dart';
import 'package:first_project/shared/services/app_globals.dart';

class PrayerTimesProvider extends ChangeNotifier {
  static const double baitulMukarramLat = 23.7286;
  static const double baitulMukarramLng = 90.4106;
  static const String fallbackLabel = 'Baitul Mukarram, Dhaka';

  PrayerTimesProvider() {
    useDeviceLocationNotifier.addListener(_onLocationModeChanged);
    profileLocationNotifier.addListener(_onProfileLocationChanged);
    _seedLocalPrayerPreview();
    unawaited(loadPrayerData(showLoader: false));
    _clockTimer = Timer.periodic(const Duration(seconds: 1), _onClockTick);
  }

  final PrayerScheduleService _service = PrayerScheduleService();
  Timer? _clockTimer;
  bool _disposed = false;

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

  DateTime get now => _now;
  DailyPrayerSchedule? get todaySchedule => _todaySchedule;
  DailyPrayerSchedule? get tomorrowSchedule => _tomorrowSchedule;
  String get locationLabel => _locationLabel;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  bool get isRefreshing => _isRefreshing;
  bool get usingFallbackLocation => _usingFallbackLocation;
  bool get usingOfflineCalculation => _usingOfflineCalculation;
  String get activePrayer => _activePrayer;
  DateTime? get nextPrayerAt => _nextPrayerAt;
  Duration get remaining => _remaining;
  double get elapsedProgress => _elapsedProgress;

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    _safeNotify();
    try {
      await loadPrayerData(showLoader: false);
    } finally {
      _isRefreshing = false;
      _safeNotify();
    }
  }

  Future<void> loadPrayerData({required bool showLoader}) async {
    final hasExistingPreview =
        _todaySchedule != null && _tomorrowSchedule != null;
    _isSyncing = true;
    if (showLoader && !hasExistingPreview) _isLoading = true;
    _safeNotify();

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

    if (_disposed) return;
    _todaySchedule = todaySchedule;
    _tomorrowSchedule = tomorrowSchedule;
    _locationLabel = resolved.label;
    _usingFallbackLocation = resolved.usingFallbackLocation;
    _usingOfflineCalculation = usedOfflineFallback;
    _isLoading = false;
    _isSyncing = false;
    _now = DateTime.now();
    _updateActivePrayer();
    _safeNotify();
  }

  void _seedLocalPrayerPreview() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final todaySchedule = _service.calculateFallback(
      date: today,
      latitude: baitulMukarramLat,
      longitude: baitulMukarramLng,
    );
    final tomorrowSchedule = _service.calculateFallback(
      date: tomorrow,
      latitude: baitulMukarramLat,
      longitude: baitulMukarramLng,
    );

    _now = now;
    _todaySchedule = todaySchedule;
    _tomorrowSchedule = tomorrowSchedule;
    _locationLabel = _profileOrFallbackLocationLabel();
    _usingFallbackLocation = true;
    _usingOfflineCalculation = true;
    _isLoading = false;
    _isSyncing = true;
    _updateActivePrayer();
  }

  void _onClockTick(Timer _) {
    if (_disposed) return;
    _now = DateTime.now();
    _updateActivePrayer();
    _safeNotify();
    if (_needsFreshSchedule() && !_isLoading) {
      unawaited(loadPrayerData(showLoader: false));
    }
  }

  void _onLocationModeChanged() {
    unawaited(loadPrayerData(showLoader: false));
  }

  void _onProfileLocationChanged() {
    if (_disposed || useDeviceLocationNotifier.value) return;
    _locationLabel = _profileOrFallbackLocationLabel();
    _safeNotify();
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
    return value.isEmpty ? fallbackLabel : value;
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
        latitude: baitulMukarramLat,
        longitude: baitulMukarramLng,
        label: _profileOrFallbackLocationLabel(),
        usingFallbackLocation: true,
      );
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (
          latitude: baitulMukarramLat,
          longitude: baitulMukarramLng,
          label: _profileOrFallbackLocationLabel(),
          usingFallbackLocation: true,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (locationPermissionRequestInProgress) {
          return (
            latitude: baitulMukarramLat,
            longitude: baitulMukarramLng,
            label: _profileOrFallbackLocationLabel(),
            usingFallbackLocation: true,
          );
        }
        locationPermissionRequestInProgress = true;
        try {
          permission = await Geolocator.requestPermission();
        } finally {
          locationPermissionRequestInProgress = false;
        }
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (
          latitude: baitulMukarramLat,
          longitude: baitulMukarramLng,
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
        latitude: baitulMukarramLat,
        longitude: baitulMukarramLng,
        label: _profileOrFallbackLocationLabel(),
        usingFallbackLocation: true,
      );
    }
  }

  Future<String> _resolveLocationLabel(double latitude, double longitude) async {
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
    if (today == null || tomorrow == null) return;

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

    _activePrayer = nextPrayer.key;
    _nextPrayerAt = nextPrayer.at;
    _remaining = remaining;
    _elapsedProgress = progress;
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    useDeviceLocationNotifier.removeListener(_onLocationModeChanged);
    profileLocationNotifier.removeListener(_onProfileLocationChanged);
    _clockTimer?.cancel();
    super.dispose();
  }
}
