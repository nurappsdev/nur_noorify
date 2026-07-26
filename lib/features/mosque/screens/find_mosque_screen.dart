import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'package:url_launcher/url_launcher.dart';

import 'package:first_project/features/mosque/models/mosque_item.dart';
import 'package:first_project/features/mosque/services/mosque_service.dart';

/// Shows a regular Google map centred on the user when location is available,
/// with nearby mosques highlighted as green markers.
class FindMosqueScreen extends StatefulWidget {
  const FindMosqueScreen({super.key});

  @override
  State<FindMosqueScreen> createState() => _FindMosqueScreenState();
}

class _FindMosqueScreenState extends State<FindMosqueScreen> {
  // Baitul Mukarram, Dhaka - used as a fallback when location is unavailable.
  static const maps.LatLng _fallbackCenter = maps.LatLng(23.7308, 90.4128);
  static const double _initialZoom = 14;
  static const double _minZoom = 4;
  static const double _maxZoom = 19;
  static const String _googleDirectionsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyASCb268NsxS1RGEhZ4N43xW9UuuDL750E',
  );

  final Completer<maps.GoogleMapController> _mapController = Completer();
  final MosqueService _mosqueService = MosqueService();
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://maps.googleapis.com/maps/api',
      connectTimeout: Duration(seconds: 12),
      receiveTimeout: Duration(seconds: 15),
      responseType: ResponseType.json,
    ),
  );

  maps.LatLng _center = _fallbackCenter;
  maps.LatLng? _userLocation;
  maps.LatLng? _selectedDestination;
  String _destinationLabel = 'Selected location';
  maps.BitmapDescriptor? _mosqueMarkerIcon;
  Set<maps.Marker> _mosqueMarkers = const {};
  Set<maps.Marker> _routeMarkers = const {};
  Set<maps.Polyline> _polylines = const {};
  _RouteSummary? _routeSummary;
  double _zoom = _initialZoom;
  bool _isLocating = true;
  bool _isRouting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    if (mounted) {
      setState(() => _isLocating = true);
    }

    final position = await _resolveUserPosition();
    final center = position != null
        ? maps.LatLng(position.latitude, position.longitude)
        : _fallbackCenter;

    if (!mounted) return;
    setState(() {
      _center = center;
      _userLocation = position == null ? null : center;
      _isLocating = false;
    });
    await _moveCamera(center, _initialZoom);
    unawaited(_loadNearbyMosques(center));
  }

  /// Tries to read the device location, requesting permission if needed.
  /// Returns null when location is unavailable so the map falls back gracefully.
  Future<Position?> _resolveUserPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).timeout(const Duration(seconds: 8));
      } catch (_) {
        return Geolocator.getLastKnownPosition();
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _moveCamera(maps.LatLng target, double zoom) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    await controller.animateCamera(
      maps.CameraUpdate.newCameraPosition(
        maps.CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  Future<void> _zoomBy(double delta) async {
    final next = (_zoom + delta).clamp(_minZoom, _maxZoom).toDouble();
    setState(() => _zoom = next);
    await _moveCamera(_center, next);
  }

  Future<void> _fitCameraToPoints(List<maps.LatLng> points) async {
    if (!_mapController.isCompleted || points.isEmpty) return;
    final controller = await _mapController.future;
    await controller.animateCamera(
      maps.CameraUpdate.newLatLngBounds(_boundsFor(points), 72.r),
    );
  }

  Future<void> _recenterOnUser() async {
    if (_userLocation == null) {
      await _initialize();
    }

    final user = _userLocation;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location is not available.')),
      );
      return;
    }

    setState(() {
      _center = user;
      _zoom = _initialZoom;
    });
    await _moveCamera(user, _initialZoom);
    unawaited(_loadNearbyMosques(user));
  }

  Future<void> _loadNearbyMosques(maps.LatLng center) async {
    try {
      _mosqueMarkerIcon ??= await _createMosqueMarkerIcon();
      final mosques = await _mosqueService.fetchNearbyMosques(
        latitude: center.latitude,
        longitude: center.longitude,
        radiusMeters: 10000,
        limit: 80,
      );
      if (!mounted) return;
      setState(() {
        _mosqueMarkers = mosques.map(_buildMosqueMarker).toSet();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _mosqueMarkers = const {});
    }
  }

  maps.Marker _buildMosqueMarker(MosqueItem mosque) {
    return maps.Marker(
      markerId: maps.MarkerId('mosque_${mosque.id}'),
      position: maps.LatLng(mosque.latitude, mosque.longitude),
      icon: _mosqueMarkerIcon ?? maps.BitmapDescriptor.defaultMarker,
      consumeTapEvents: true,
      infoWindow: maps.InfoWindow(
        title: mosque.name,
        snippet: '${mosque.distanceKm.toStringAsFixed(1)} km away',
        onTap: () => unawaited(_selectMosqueDestination(mosque)),
      ),
      onTap: () => unawaited(_selectMosqueDestination(mosque)),
    );
  }

  Future<maps.BitmapDescriptor> _createMosqueMarkerIcon() async {
    const size = 112.0;
    const markerGreen = Color(0xFF159447);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;
    final shadowPaint = Paint()
      ..isAntiAlias = true
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final iconCenter = Offset(size / 2, size * 0.43);

    final pinPath = Path()
      ..addOval(Rect.fromCircle(center: iconCenter, radius: 34))
      ..moveTo(size / 2 - 17, size * 0.69)
      ..quadraticBezierTo(size / 2, size * 0.94, size / 2 + 17, size * 0.69)
      ..close();
    canvas.drawPath(pinPath.shift(const Offset(0, 3)), shadowPaint);
    paint.color = markerGreen;
    canvas.drawPath(pinPath, paint);
    paint.color = Colors.white;
    canvas.drawCircle(iconCenter, 25, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.mosque_rounded.codePoint),
        style: TextStyle(
          fontFamily: Icons.mosque_rounded.fontFamily,
          package: Icons.mosque_rounded.fontPackage,
          color: markerGreen,
          fontSize: 35,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      iconCenter - Offset(textPainter.width / 2, textPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List();
    if (bytes == null || bytes.isEmpty) {
      return maps.BitmapDescriptor.defaultMarker;
    }

    return maps.BitmapDescriptor.bytes(
      bytes,
      width: 56,
      height: 56,
      imagePixelRatio: 2,
    );
  }

  Future<void> _selectMosqueDestination(MosqueItem mosque) {
    return _selectDestination(
      maps.LatLng(mosque.latitude, mosque.longitude),
      label: mosque.name,
    );
  }

  Future<void> _selectDestination(
    maps.LatLng destination, {
    String label = 'Selected location',
  }) async {
    if (_userLocation == null) {
      await _initialize();
    }

    final origin = _userLocation;
    if (origin == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location is not available.')),
      );
      return;
    }

    setState(() => _isRouting = true);
    try {
      final route = await _fetchRoute(origin, destination);
      if (!mounted) return;
      final points = route.points;
      setState(() {
        _isRouting = false;
        _selectedDestination = destination;
        _destinationLabel = label;
        _routeSummary = route.summary;
        _routeMarkers = {
          maps.Marker(
            markerId: const maps.MarkerId('selected_destination'),
            position: destination,
            infoWindow: maps.InfoWindow(title: label),
          ),
        };
        _polylines = {
          maps.Polyline(
            polylineId: const maps.PolylineId('route_to_selected_destination'),
            points: points,
            color: Theme.of(context).colorScheme.primary,
            width: 6,
          ),
        };
      });
      await _fitCameraToPoints([origin, ...points, destination]);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isRouting = false);
      await _openSelectedDestinationInGoogleMaps(origin, destination);
    }
  }

  Future<_RouteResult> _fetchRoute(
    maps.LatLng origin,
    maps.LatLng destination,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/directions/json',
      queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': 'driving',
        'key': _googleDirectionsApiKey,
      },
    );
    final data = response.data;
    if (data == null || data['status'] != 'OK') {
      return _RouteResult.empty(origin, destination);
    }

    final routes = data['routes'];
    if (routes is! List || routes.isEmpty) {
      return _RouteResult.empty(origin, destination);
    }

    final firstRoute = routes.first;
    if (firstRoute is! Map) return _RouteResult.empty(origin, destination);

    final overviewPolyline = firstRoute['overview_polyline'];
    if (overviewPolyline is! Map) {
      return _RouteResult.empty(origin, destination);
    }

    final encoded = overviewPolyline['points'];
    if (encoded is! String || encoded.isEmpty) {
      return _RouteResult.empty(origin, destination);
    }

    final points = _decodePolyline(encoded);
    final legs = firstRoute['legs'];
    final firstLeg = legs is List && legs.isNotEmpty && legs.first is Map
        ? Map<String, dynamic>.from(legs.first as Map)
        : const <String, dynamic>{};
    final distance = firstLeg['distance'] is Map
        ? Map<String, dynamic>.from(firstLeg['distance'] as Map)
        : const <String, dynamic>{};
    final duration = firstLeg['duration'] is Map
        ? Map<String, dynamic>.from(firstLeg['duration'] as Map)
        : const <String, dynamic>{};

    return _RouteResult(
      points: points.isEmpty ? [origin, destination] : points,
      summary: _RouteSummary(
        distanceText: (distance['text'] ?? '').toString(),
        durationText: (duration['text'] ?? '').toString(),
      ),
    );
  }

  List<maps.LatLng> _decodePolyline(String encoded) {
    final points = <maps.LatLng>[];
    var index = 0;
    var latitude = 0;
    var longitude = 0;

    while (index < encoded.length) {
      final latResult = _decodePolylineValue(encoded, index);
      index = latResult.nextIndex;
      latitude += latResult.value;

      final lngResult = _decodePolylineValue(encoded, index);
      index = lngResult.nextIndex;
      longitude += lngResult.value;

      points.add(maps.LatLng(latitude / 1E5, longitude / 1E5));
    }

    return points;
  }

  _PolylineValue _decodePolylineValue(String encoded, int startIndex) {
    var index = startIndex;
    var shift = 0;
    var result = 0;

    while (index < encoded.length) {
      final byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
      if (byte < 0x20) break;
    }

    final value = (result & 1) == 1 ? ~(result >> 1) : result >> 1;
    return _PolylineValue(value: value, nextIndex: index);
  }

  maps.LatLngBounds _boundsFor(List<maps.LatLng> points) {
    var south = points.first.latitude;
    var north = points.first.latitude;
    var west = points.first.longitude;
    var east = points.first.longitude;

    for (final point in points.skip(1)) {
      south = math.min(south, point.latitude);
      north = math.max(north, point.latitude);
      west = math.min(west, point.longitude);
      east = math.max(east, point.longitude);
    }

    return maps.LatLngBounds(
      southwest: maps.LatLng(south, west),
      northeast: maps.LatLng(north, east),
    );
  }

  Future<void> _openSelectedDestinationInGoogleMaps(
    maps.LatLng origin,
    maps.LatLng destination,
  ) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&travelmode=driving',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open directions.')),
      );
    }
  }

  Future<bool> _openSelectedNavigation(maps.LatLng destination) async {
    final navigationUri = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => Uri.parse(
        'comgooglemaps://?daddr=${destination.latitude},${destination.longitude}'
        '&directionsmode=driving',
      ),
      _ => Uri.parse(
        'google.navigation:q=${destination.latitude},${destination.longitude}'
        '&mode=d',
      ),
    };

    try {
      return launchUrl(navigationUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Mosque'),
        actions: [
          IconButton(
            tooltip: 'Refresh location',
            onPressed: _isLocating ? null : () => unawaited(_initialize()),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          maps.GoogleMap(
            initialCameraPosition: maps.CameraPosition(
              target: _center,
              zoom: _initialZoom,
            ),
            mapType: maps.MapType.normal,
            minMaxZoomPreference: const maps.MinMaxZoomPreference(
              _minZoom,
              _maxZoom,
            ),
            myLocationEnabled: _userLocation != null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: true,
            markers: {..._mosqueMarkers, ..._routeMarkers},
            polylines: _polylines,
            onTap: _selectDestination,
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
              unawaited(_moveCamera(_center, _zoom));
            },
            onCameraMove: (position) {
              _center = position.target;
              _zoom = position.zoom;
            },
          ),
          if (_isLocating)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
          if (_isRouting)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
          if (_selectedDestination != null)
            Positioned(
              left: 14.w,
              right: 14.w,
              top: 14.h,
              child: _buildDirectionsHeader(),
            ),
          if (_selectedDestination == null)
            Positioned(left: 16.w, bottom: 24.h, child: _selectionHint()),
          if (_selectedDestination != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildRouteSummary(),
            ),
          Positioned(
            right: 16.w,
            bottom: _selectedDestination == null ? 24.h : 164.h,
            child: Column(
              children: [
                _mapButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom in',
                  onPressed: () => unawaited(_zoomBy(1)),
                ),
                SizedBox(height: 10.h),
                _mapButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom out',
                  onPressed: () => unawaited(_zoomBy(-1)),
                ),
                SizedBox(height: 10.h),
                _mapButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'My location',
                  onPressed: () => unawaited(_recenterOnUser()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }

  Widget _selectionHint() {
    return Material(
      borderRadius: BorderRadius.circular(999.r),
      color: Theme.of(context).colorScheme.surface,
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.route_rounded,
              size: 18.r,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 8.w),
            Text(
              _isRouting ? 'Loading route...' : 'Tap map to select route',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionsHeader() {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 4,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: [
            Column(
              children: [
                Icon(Icons.my_location_rounded, color: Colors.blue, size: 18.r),
                Container(width: 1, height: 20.h, color: Colors.grey.shade300),
                Icon(Icons.location_on, color: Colors.red, size: 20.r),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your location',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Divider(height: 18.h),
                  Text(
                    _destinationLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Clear route',
              onPressed: _clearRoute,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSummary() {
    final summary = _routeSummary;
    final duration = summary?.durationText.isNotEmpty == true
        ? summary!.durationText
        : '--';
    final distance = summary?.distanceText.isNotEmpty == true
        ? summary!.distanceText
        : '';

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Text(
                    'Drive',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Share',
                    onPressed: _shareSelectedRoute,
                    icon: const Icon(Icons.share_rounded),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _clearRoute,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(
                    Icons.directions_car_rounded,
                    size: 18.r,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '$duration ${distance.isEmpty ? '' : '($distance)'}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _openSelectedRoute,
                    icon: const Icon(Icons.navigation_rounded),
                    label: const Text('Start'),
                  ),
                  SizedBox(width: 8.w),
                  _routeActionButton(
                    Icons.add_location_alt_rounded,
                    'Add stops',
                  ),
                  SizedBox(width: 8.w),
                  _routeActionButton(Icons.share_rounded, 'Share'),
                  SizedBox(width: 8.w),
                  _routeActionButton(Icons.bookmark_border_rounded, 'Save'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _routeActionButton(IconData icon, String label) {
    return Expanded(
      child: FilledButton.tonalIcon(
        onPressed: label == 'Share' ? _shareSelectedRoute : null,
        icon: Icon(icon, size: 18.r),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  void _clearRoute() {
    setState(() {
      _selectedDestination = null;
      _destinationLabel = 'Selected location';
      _routeSummary = null;
      _routeMarkers = const {};
      _polylines = const {};
      _isRouting = false;
    });
  }

  void _shareSelectedRoute() {
    final origin = _userLocation;
    final destination = _selectedDestination;
    if (origin == null || destination == null) return;
    unawaited(_openSelectedDestinationInGoogleMaps(origin, destination));
  }

  void _openSelectedRoute() {
    final destination = _selectedDestination;
    if (destination == null) return;
    unawaited(() async {
      final opened = await _openSelectedNavigation(destination);
      if (opened) return;
      final origin = _userLocation;
      if (origin == null) return;
      await _openSelectedDestinationInGoogleMaps(origin, destination);
    }());
  }
}

class _PolylineValue {
  const _PolylineValue({required this.value, required this.nextIndex});

  final int value;
  final int nextIndex;
}

class _RouteResult {
  const _RouteResult({required this.points, required this.summary});

  factory _RouteResult.empty(maps.LatLng origin, maps.LatLng destination) {
    return _RouteResult(
      points: [origin, destination],
      summary: const _RouteSummary(distanceText: '', durationText: ''),
    );
  }

  final List<maps.LatLng> points;
  final _RouteSummary summary;
}

class _RouteSummary {
  const _RouteSummary({required this.distanceText, required this.durationText});

  final String distanceText;
  final String durationText;
}
