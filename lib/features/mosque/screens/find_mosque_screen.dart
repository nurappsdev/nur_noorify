import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:first_project/features/mosque/models/mosque_item.dart';
import 'package:first_project/features/mosque/services/mosque_service.dart';

/// Shows an OpenStreetMap map (via flutter_map) centred on the user, with
/// pinch / button zoom and markers for the nearby mosques. Tapping a mosque
/// opens its details and lets the user route to it in Google Maps.
class FindMosqueScreen extends StatefulWidget {
  const FindMosqueScreen({super.key});

  @override
  State<FindMosqueScreen> createState() => _FindMosqueScreenState();
}

class _FindMosqueScreenState extends State<FindMosqueScreen> {
  // Baitul Mukarram, Dhaka — used as a fallback when location is unavailable.
  static const LatLng _fallbackCenter = LatLng(23.7308, 90.4128);
  static const double _initialZoom = 14;
  static const double _minZoom = 4;
  static const double _maxZoom = 18;

  final MapController _mapController = MapController();
  final MosqueService _mosqueService = MosqueService();

  LatLng _center = _fallbackCenter;
  LatLng? _userLocation;
  List<MosqueItem> _mosques = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final position = await _resolveUserPosition();
    final center = position != null
        ? LatLng(position.latitude, position.longitude)
        : _fallbackCenter;

    if (!mounted) return;
    setState(() {
      _center = center;
      _userLocation = position == null ? null : center;
    });
    _mapController.move(center, _initialZoom);

    await _loadMosques(center);
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

  Future<void> _loadMosques(LatLng center) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final mosques = await _mosqueService.fetchNearbyMosques(
        latitude: center.latitude,
        longitude: center.longitude,
      );
      if (!mounted) return;
      setState(() {
        _mosques = mosques;
        _isLoading = false;
      });
    } on MosqueLookupException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load nearby mosques.';
        _isLoading = false;
      });
    }
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final next = (camera.zoom + delta).clamp(_minZoom, _maxZoom);
    _mapController.move(camera.center, next);
  }

  void _recenterOnUser() {
    final user = _userLocation;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location is not available.')),
      );
      return;
    }
    _mapController.move(user, _initialZoom);
  }

  Future<void> _openInGoogleMaps(MosqueItem mosque) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query='
      '${mosque.latitude},${mosque.longitude}',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  void _showMosqueDetails(MosqueItem mosque) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.mosque_rounded, color: theme.colorScheme.primary),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      mosque.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                mosque.address,
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 4.h),
              Text(
                '${mosque.distanceKm.toStringAsFixed(1)} km away',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    unawaited(_openInGoogleMaps(mosque));
                  },
                  icon: const Icon(Icons.directions_rounded),
                  label: const Text('Open in Google Maps'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    final user = _userLocation;
    if (user != null) {
      markers.add(
        Marker(
          point: user,
          width: 28.r,
          height: 28.r,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6),
              ],
            ),
          ),
        ),
      );
    }

    for (final mosque in _mosques) {
      markers.add(
        Marker(
          point: LatLng(mosque.latitude, mosque.longitude),
          width: 40.r,
          height: 40.r,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _showMosqueDetails(mosque),
            child: Icon(
              Icons.mosque_rounded,
              color: Colors.teal.shade700,
              size: 34.r,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Mosque'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : () => _loadMosques(_center),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _initialZoom,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.noorify.app',
                maxZoom: _maxZoom,
              ),
              MarkerLayer(markers: _buildMarkers()),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          if (_isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
          if (_error != null) _buildErrorBanner(),
          Positioned(
            right: 16.w,
            bottom: 24.h,
            child: Column(
              children: [
                _mapButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom in',
                  onPressed: () => _zoomBy(1),
                ),
                SizedBox(height: 10.h),
                _mapButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom out',
                  onPressed: () => _zoomBy(-1),
                ),
                SizedBox(height: 10.h),
                _mapButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'My location',
                  onPressed: _recenterOnUser,
                ),
              ],
            ),
          ),
          if (!_isLoading && _error == null)
            Positioned(
              left: 16.w,
              bottom: 24.h,
              child: _resultChip(),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Positioned(
      left: 16.w,
      right: 16.w,
      top: 16.h,
      child: Material(
        borderRadius: BorderRadius.circular(12.r),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          child: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  _error ?? '',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _loadMosques(_center),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultChip() {
    return Material(
      borderRadius: BorderRadius.circular(999.r),
      color: Theme.of(context).colorScheme.surface,
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        child: Text(
          '${_mosques.length} mosque(s) nearby',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
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
}
