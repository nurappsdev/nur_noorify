import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:first_project/shared/services/app_globals.dart';

enum QiblaSource { none, api, basic }

/// Sensor state is stored as an enum so the widget can localize the message
/// reactively (instead of the provider holding a pre-localized string).
enum QiblaSensorError { none, unavailable, readError }

/// Owns all Qibla compass state and side effects (compass stream, geolocation,
/// Aladhan API lookup) so the screen can stay a pure Provider consumer.
class QiblaProvider extends ChangeNotifier {
  QiblaProvider({required bool isBangla}) : _isBangla = isBangla {
    useDeviceLocationNotifier.addListener(_onLocationModeChanged);
    startCompassListener();
    unawaited(loadQiblaDirection());
  }

  static const _kaabaLat = 21.422487;
  static const _kaabaLng = 39.826206;
  static const _baitulMukarramLat = 23.7286;
  static const _baitulMukarramLng = 90.4106;

  final Dio _qiblaApi = Dio(
    BaseOptions(
      baseUrl: 'https://api.aladhan.com/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      responseType: ResponseType.json,
    ),
  );

  bool _isBangla;
  bool _disposed = false;
  StreamSubscription<CompassEvent>? _compassSub;

  double? _heading;
  double? _qiblaBearing;
  double? _distanceKm;
  QiblaSensorError _sensorError = QiblaSensorError.none;
  bool _isListening = false;
  bool _isLoadingQibla = true;
  bool _usingFallbackLocation = false;
  String _locationLabel = '';
  QiblaSource _qiblaSource = QiblaSource.none;

  double? get heading => _heading;
  double? get qiblaBearing => _qiblaBearing;
  double? get distanceKm => _distanceKm;
  QiblaSensorError get sensorError => _sensorError;
  bool get isListening => _isListening;
  bool get isLoadingQibla => _isLoadingQibla;
  bool get usingFallbackLocation => _usingFallbackLocation;
  String get locationLabel => _locationLabel;
  QiblaSource get qiblaSource => _qiblaSource;

  String _fallbackLocationLabel() =>
      _isBangla ? 'বায়তুল মুকাররম, ঢাকা' : 'Baitul Mukarram, Dhaka';

  String _currentLocationLabel() =>
      _isBangla ? 'বর্তমান অবস্থান' : 'Current location';

  void _onLocationModeChanged() {
    unawaited(loadQiblaDirection());
  }

  void startCompassListener() {
    _compassSub?.cancel();
    final stream = FlutterCompass.events;
    if (stream == null) {
      _sensorError = QiblaSensorError.unavailable;
      _isListening = false;
      _safeNotify();
      return;
    }

    _sensorError = QiblaSensorError.none;
    _isListening = true;
    _safeNotify();

    _compassSub = stream.listen(
      (event) {
        final heading = event.heading;
        if (heading == null || heading.isNaN) return;
        _heading = _normalizeAngle(heading);
        _sensorError = QiblaSensorError.none;
        _isListening = true;
        _safeNotify();
      },
      onError: (_) {
        _sensorError = QiblaSensorError.readError;
        _isListening = false;
        _safeNotify();
      },
      onDone: () {
        _isListening = false;
        _safeNotify();
      },
    );
  }

  Future<void> refreshAll({required bool isBangla}) async {
    _isBangla = isBangla;
    startCompassListener();
    await loadQiblaDirection();
  }

  Future<void> loadQiblaDirection() async {
    _isLoadingQibla = true;
    _safeNotify();

    final resolved = await _resolveCoordinates();
    final lat = resolved.lat;
    final lng = resolved.lng;

    final apiBearing = await _fetchQiblaBearingFromApi(lat: lat, lng: lng);
    final basicBearing = _calculateBasicQiblaBearing(lat: lat, lng: lng);
    final distanceKm =
        Geolocator.distanceBetween(lat, lng, _kaabaLat, _kaabaLng) / 1000;

    if (_disposed) return;
    _qiblaBearing = apiBearing ?? basicBearing;
    _qiblaSource = apiBearing != null ? QiblaSource.api : QiblaSource.basic;
    _distanceKm = distanceKm;
    _locationLabel = resolved.label;
    _usingFallbackLocation = resolved.usingFallbackLocation;
    _isLoadingQibla = false;
    _safeNotify();
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
      if (placemarks.isEmpty) return _currentLocationLabel();
      final place = placemarks.first;

      final city =
          place.locality ??
          place.subAdministrativeArea ??
          place.administrativeArea ??
          _currentLocationLabel();
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
      return _currentLocationLabel();
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

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    useDeviceLocationNotifier.removeListener(_onLocationModeChanged);
    _compassSub?.cancel();
    super.dispose();
  }
}
