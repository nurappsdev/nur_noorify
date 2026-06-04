import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class LocationSelection {
  const LocationSelection({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final double latitude;
  final double longitude;
  final String label;
}

class SetLocationScreen extends StatefulWidget {
  const SetLocationScreen({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.initialLabel,
  });

  final double initialLatitude;
  final double initialLongitude;
  final String initialLabel;

  @override
  State<SetLocationScreen> createState() => _SetLocationScreenState();
}

class _SetLocationScreenState extends State<SetLocationScreen> {
  static final _tileCachingProvider =
      BuiltInMapCachingProvider.getOrCreateInstance(
        maxCacheSize: 300 * 1024 * 1024,
        overrideFreshAge: const Duration(days: 14),
      );

  final TextEditingController _searchController = TextEditingController();
  late final MapController _mapController;
  late LatLng _selectedPoint;
  late String _selectedLabel;
  bool _resolvingLabel = false;
  bool _locatingCurrent = false;

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
    for (var i = 0; i < 2; i++) {
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

  String _text(String en, String bn) {
    if (!_isBangla) return en;
    final repaired = _repairMojibake(bn);
    if (_looksMojibake(repaired)) return en;
    return _containsBangla(repaired) ? repaired : en;
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedPoint = LatLng(widget.initialLatitude, widget.initialLongitude);
    _selectedLabel = widget.initialLabel;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onTapMap(LatLng point) async {
    setState(() => _selectedPoint = point);
    await _resolveLabelFromCoordinates(point);
  }

  Future<void> _resolveLabelFromCoordinates(LatLng point) async {
    if (_searchController.text.trim().isNotEmpty) return;
    setState(() => _resolvingLabel = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (placemarks.isEmpty) return;
      final place = placemarks.first;
      final city =
          place.locality ??
          place.subAdministrativeArea ??
          place.administrativeArea;
      final country = place.country;
      if (!mounted) return;
      setState(() {
        if (city != null && city.trim().isNotEmpty) {
          _selectedLabel = country == null || country.trim().isEmpty
              ? city.trim()
              : '${city.trim()}, ${country.trim()}';
        }
      });
    } catch (_) {
      // Keep existing label if reverse-geocode fails.
    } finally {
      if (mounted) {
        setState(() => _resolvingLabel = false);
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_locatingCurrent) return;
    setState(() => _locatingCurrent = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _text(
                'Please enable phone location service.',
                'ফোনের লোকেশন সার্ভিস চালু করুন।',
              ),
            ),
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _text(
                'Location permission denied on this device.',
                'এই ডিভাইসে লোকেশন পারমিশন বন্ধ আছে।',
              ),
            ),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final point = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _selectedPoint = point);
      _mapController.move(point, 15.5);
      await _resolveLabelFromCoordinates(point);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Could not read current location.',
              'বর্তমান লোকেশন পড়া যায়নি।',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _locatingCurrent = false);
      }
    }
  }

  void _confirmSelection() {
    final typed = _searchController.text.trim();
    final label = typed.isEmpty ? _selectedLabel : typed;
    Navigator.of(context).pop(
      LocationSelection(
        latitude: _selectedPoint.latitude,
        longitude: _selectedPoint.longitude,
        label: label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final latText = _selectedPoint.latitude.toStringAsFixed(3);
    final lngText = _selectedPoint.longitude.toStringAsFixed(3);

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 10.h),
                child: Row(
                  children: [
                    Material(
                      color: glass.isDark
                          ? const Color(0x332EB8E6)
                          : const Color(0x221EA8B8),
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
                    SizedBox(width: 8.w),
                    Text(
                      _text('Location', 'লোকেশন'),
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: glass.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 0.h, 14.w, 10.h),
                child: NoorifyGlassCard(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                  radius: BorderRadius.circular(18.r),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: glass.textPrimary),
                    decoration: InputDecoration(
                      hintText: _text('Search', 'খুঁজুন'),
                      hintStyle: TextStyle(color: glass.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20.sp,
                        color: glass.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 0.h, 14.w, 8.h),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _locatingCurrent ? null : _useCurrentLocation,
                    icon: _locatingCurrent
                        ? SizedBox(
                            width: 14.r,
                            height: 14.r,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: glass.accent,
                            ),
                          )
                        : Icon(
                            Icons.my_location_rounded,
                            size: 16.sp,
                            color: glass.accent,
                          ),
                    label: Text(
                      _text(
                        'Use current location',
                        'বর্তমান লোকেশন ব্যবহার করুন',
                      ),
                      style: TextStyle(
                        color: glass.accent,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22.r),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _selectedPoint,
                            initialZoom: 15.5,
                            minZoom: 3,
                            maxZoom: 19,
                            onTap: (tapPosition, point) => _onTapMap(point),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.noorify.app',
                              tileProvider: NetworkTileProvider(
                                cachingProvider: _tileCachingProvider,
                              ),
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  width: 30.w,
                                  height: 44.h,
                                  point: _selectedPoint,
                                  child: const _PinMarker(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0.w,
                      right: 0.w,
                      top: 170.h,
                      child: Center(
                        child: NoorifyGlassCard(
                          radius: BorderRadius.circular(12.r),
                          padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 8.h),
                          child: SizedBox(
                            width: 196.w,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 14.sp,
                                      color: Color(0xFFF05555),
                                    ),
                                    SizedBox(width: 4.w),
                                    Expanded(
                                      child: Text(
                                        _selectedLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5.sp,
                                          fontWeight: FontWeight.w700,
                                          color: glass.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  _text(
                                    'Lat: $latText, Long:$lngText',
                                    'অক্ষাংশ: $latText, দ্রাঘিমাংশ: $lngText',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: glass.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_resolvingLabel)
                                  Padding(
                                    padding: EdgeInsets.only(top: 4.h),
                                    child: SizedBox(
                                      width: 12.r,
                                      height: 12.r,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.8,
                                        color: glass.accent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20.w,
                      right: 20.w,
                      bottom: 84.h,
                      child: SizedBox(
                        height: 42.h,
                        child: FilledButton(
                          onPressed: _confirmSelection,
                          style: FilledButton.styleFrom(
                            backgroundColor: glass.accent,
                            foregroundColor: glass.isDark
                                ? const Color(0xFF072734)
                                : Colors.white,
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            _text('Choose Location', 'লোকেশন নির্বাচন করুন'),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16.sp / 1.15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 14.w,
                      bottom: 76.h,
                      child: Material(
                        color: glass.isDark
                            ? const Color(0xEE112233)
                            : Colors.white.withValues(alpha: 0.96),
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: IconButton(
                          onPressed: _useCurrentLocation,
                          icon: Icon(
                            Icons.my_location_rounded,
                            color: glass.accent,
                            size: 21.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              bottomNav(context, 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinMarker extends StatelessWidget {
  const _PinMarker();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22.w,
      height: 34.h,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0.h,
            child: Container(
              width: 22.r,
              height: 22.r,
              decoration: const BoxDecoration(
                color: Color(0xFFF04444),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.location_on_rounded,
                  size: 12.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0.h,
            child: Container(
              width: 6.w,
              height: 10.h,
              decoration: BoxDecoration(
                color: Color(0xFFF04444),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8.r)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
