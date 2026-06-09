part of '../screens/daily_activity_screen.dart';

mixin DailyControllerLocationMixin on State<DailyActivityScreen>, DailyControllerPrayerDataMixin {
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
        if (locationPermissionRequestInProgress) {
          _setBaitulMukarramLocation();
          await _refreshPrayerScheduleFromSource(forceRefresh: true);
          return;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not read current location. Using fallback temporarily.',
            ),
          ),
        );
      }
      debugPrint('Device location fetch failed: $e');
    }

    await _refreshPrayerScheduleFromSource(forceRefresh: true);
  }

  void _setBaitulMukarramLocation() {
    _latitude = _baitulMukarramLat;
    _longitude = _baitulMukarramLng;
    _updateHomeQiblaBearing(_baitulMukarramLat, _baitulMukarramLng);
    _safeSetState(() => _locationLabel = _profileOrFallbackLocationLabel());
  }

  String _profileOrFallbackLocationLabel() {
    final profileLocation = profileLocationNotifier.value.trim();
    if (profileLocation.isNotEmpty) return profileLocation;
    return DailyControllerStateMixin._baitulMukarramLabel;
  }

  Future<void> _resolveLocationLabel(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty || !mounted) return;
      final place = placemarks.first;
      final city =
          place.locality ??
          place.subAdministrativeArea ??
          place.administrativeArea ??
          'Current location';
      final area = place.administrativeArea ?? place.country ?? '';
      final label = area.isNotEmpty ? '$city, $area' : city;
      _safeSetState(() => _locationLabel = label);
      if (profileLocationNotifier.value != label) {
        profileLocationNotifier.value = label;
        await saveAppPreferences();
      }
    } catch (_) {
      _safeSetState(() => _locationLabel = 'Current location');
    }
  }

  Future<void> _refreshLocationFromHeader() async {
    if (_isRefreshingLocation) return;
    _isRefreshingLocation = true;
    try {
      _setUseDeviceLocationSilently(true);
      await _loadPrayerData();
      await saveAppPreferences();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prayer times updated for $_locationLabel')),
      );
    } finally {
      _isRefreshingLocation = false;
    }
  }

  void _setUseDeviceLocationSilently(bool value) {
    if (useDeviceLocationNotifier.value == value) return;
    _ignoreNextLocationToggleChange = true;
    useDeviceLocationNotifier.value = value;
  }

}
