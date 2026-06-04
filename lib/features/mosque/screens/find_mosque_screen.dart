import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:first_project/features/mosque/models/mosque_item.dart';
import 'package:first_project/features/mosque/services/mosque_location_service.dart';
import 'package:first_project/features/mosque/services/mosque_results_cache_service.dart';
import 'package:first_project/features/mosque/services/mosque_service.dart';
import 'package:first_project/features/mosque/screens/set_location_screen.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

enum _LocationFallbackReason {
  none,
  appSettingOff,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  error,
}

class FindMosqueScreen extends StatefulWidget {
  const FindMosqueScreen({super.key});

  @override
  State<FindMosqueScreen> createState() => _FindMosqueScreenState();
}

class _FindMosqueScreenState extends State<FindMosqueScreen> {
  static const _fallbackLat = 23.7286;
  static const _fallbackLng = 90.4106;
  static const _fallbackLabel = 'Baitul Mukarram, Dhaka';

  final MosqueService _mosqueService = MosqueService();
  final MosqueLocationService _locationService = MosqueLocationService();
  final MosqueResultsCacheService _resultsCache = MosqueResultsCacheService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  String? _noticeMessage;
  bool _showNoticeRetry = false;
  DateTime? _lastUpdatedAt;
  bool _showingCachedData = false;
  String _query = '';
  final int _selectedRadius = 5000;
  double? _latitude;
  double? _longitude;
  bool _hasCustomLocation = false;
  bool _usingFallbackLocation = false;
  String _locationLabel = 'Detecting location...';
  List<MosqueItem> _mosques = const [];

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
    _searchController.addListener(_onSearchChanged);
    useDeviceLocationNotifier.addListener(_onLocationPreferenceChanged);
    _initializeScreen();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    useDeviceLocationNotifier.removeListener(_onLocationPreferenceChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() => _query = _searchController.text.trim().toLowerCase());
  }

  void _onLocationPreferenceChanged() {
    if (_hasCustomLocation) return;
    _refreshMosques(forceResolveLocation: true);
  }

  List<MosqueItem> get _visibleMosques {
    if (_query.isEmpty) return _mosques;
    return _mosques
        .where((item) {
          return item.name.toLowerCase().contains(_query) ||
              item.address.toLowerCase().contains(_query);
        })
        .toList(growable: false);
  }

  Future<void> _initializeScreen() async {
    final saved = await _locationService.load();
    if (!mounted) return;

    if (saved != null) {
      setState(() {
        _latitude = saved.latitude;
        _longitude = saved.longitude;
        _locationLabel = saved.label;
        _hasCustomLocation = true;
        _usingFallbackLocation = false;
      });
      await _refreshMosques();
      return;
    }

    await _refreshMosques(forceResolveLocation: true);
  }

  ({String? message, bool showRetry}) _noticeForFallback(
    _LocationFallbackReason reason,
  ) {
    switch (reason) {
      case _LocationFallbackReason.none:
        return (message: null, showRetry: false);
      case _LocationFallbackReason.appSettingOff:
        return (
          message: _text(
            'Use device location is off. Showing fallback location (Dhaka).',
            'ডিভাইস লোকেশন বন্ধ আছে। বিকল্প লোকেশন (ঢাকা) দেখানো হচ্ছে।',
          ),
          showRetry: true,
        );
      case _LocationFallbackReason.serviceDisabled:
        return (
          message: _text(
            'Phone location service is off. Showing fallback location (Dhaka).',
            'ফোনের লোকেশন সার্ভিস বন্ধ। বিকল্প লোকেশন (ঢাকা) দেখানো হচ্ছে।',
          ),
          showRetry: true,
        );
      case _LocationFallbackReason.permissionDenied:
        return (
          message: _text(
            'Location permission denied. Showing fallback location (Dhaka).',
            'লোকেশন পারমিশন পাওয়া যায়নি। বিকল্প লোকেশন (ঢাকা) দেখানো হচ্ছে।',
          ),
          showRetry: true,
        );
      case _LocationFallbackReason.permissionDeniedForever:
        return (
          message: _text(
            'Location permission is permanently denied. Showing fallback location (Dhaka).',
            'লোকেশন পারমিশন স্থায়ীভাবে বন্ধ। বিকল্প লোকেশন (ঢাকা) দেখানো হচ্ছে।',
          ),
          showRetry: true,
        );
      case _LocationFallbackReason.error:
        return (
          message: _text(
            'Could not detect location. Showing fallback location (Dhaka).',
            'লোকেশন শনাক্ত করা যায়নি। বিকল্প লোকেশন (ঢাকা) দেখানো হচ্ছে।',
          ),
          showRetry: true,
        );
    }
  }

  Future<void> _refreshMosques({bool forceResolveLocation = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hasAnyCachedLocation = _latitude != null && _longitude != null;
      final shouldUseCustomLocation =
          _hasCustomLocation && hasAnyCachedLocation;
      final shouldReuseCached =
          hasAnyCachedLocation && !forceResolveLocation && !_hasCustomLocation;

      final resolved = shouldUseCustomLocation
          ? (
              lat: _latitude!,
              lng: _longitude!,
              label: _locationLabel,
              usingFallbackLocation: false,
              reason: _LocationFallbackReason.none,
            )
          : shouldReuseCached
          ? (
              lat: _latitude!,
              lng: _longitude!,
              label: _locationLabel,
              usingFallbackLocation: _usingFallbackLocation,
              reason: _LocationFallbackReason.none,
            )
          : await _resolveCoordinates();

      final items = await _mosqueService.fetchNearbyMosques(
        latitude: resolved.lat,
        longitude: resolved.lng,
        radiusMeters: _selectedRadius,
      );
      await _resultsCache.save(
        queryLatitude: resolved.lat,
        queryLongitude: resolved.lng,
        radiusMeters: _selectedRadius,
        items: items,
      );

      final notice = _noticeForFallback(resolved.reason);
      if (!mounted) return;
      setState(() {
        _latitude = resolved.lat;
        _longitude = resolved.lng;
        _locationLabel = resolved.label;
        _usingFallbackLocation = resolved.usingFallbackLocation;
        _mosques = items;
        _lastUpdatedAt = DateTime.now();
        _showingCachedData = false;
        _noticeMessage = _hasCustomLocation ? null : notice.message;
        _showNoticeRetry = _hasCustomLocation ? false : notice.showRetry;
        _isLoading = false;
      });
    } catch (e) {
      var message = _text(
        'Could not load nearby mosques. Please try again.',
        'নিকটবর্তী মসজিদ লোড করা যায়নি। আবার চেষ্টা করুন।',
      );
      var loadedFromCache = false;
      MosqueCachedResults? cached;
      if (e is MosqueLookupException) {
        message = e.message;
        if (e.type == MosqueLookupErrorType.network ||
            e.type == MosqueLookupErrorType.server) {
          cached = await _resultsCache.load();
          if (cached != null && cached.items.isNotEmpty) {
            loadedFromCache = true;
          }
        }
      }
      if (!mounted) return;

      if (loadedFromCache && cached != null) {
        final cachedResults = cached;
        final cachedTime = TimeOfDay.fromDateTime(cachedResults.updatedAt);
        final hour = cachedTime.hourOfPeriod == 0
            ? 12
            : cachedTime.hourOfPeriod;
        final minute = cachedTime.minute.toString().padLeft(2, '0');
        final suffix = cachedTime.period == DayPeriod.am ? 'AM' : 'PM';
        final dateLabel =
            '${cachedResults.updatedAt.year}-${cachedResults.updatedAt.month.toString().padLeft(2, '0')}-${cachedResults.updatedAt.day.toString().padLeft(2, '0')}';
        setState(() {
          _mosques = cachedResults.items;
          _lastUpdatedAt = cachedResults.updatedAt;
          _showingCachedData = true;
          _error = null;
          _noticeMessage = _text(
            'Offline mode: showing last saved mosque list ($dateLabel $hour:$minute $suffix).',
            'অফলাইন মোড: সর্বশেষ সেভ করা মসজিদ তালিকা দেখানো হচ্ছে ($dateLabel $hour:$minute $suffix)।',
          );
          _showNoticeRetry = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = message;
          _showNoticeRetry = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openSetLocation() async {
    final lat = _latitude ?? _fallbackLat;
    final lng = _longitude ?? _fallbackLng;
    final label = _locationLabel.trim().isEmpty
        ? _fallbackLabel
        : _locationLabel;

    final result = await Navigator.of(context).push<LocationSelection>(
      MaterialPageRoute<LocationSelection>(
        builder: (_) => SetLocationScreen(
          initialLatitude: lat,
          initialLongitude: lng,
          initialLabel: label,
        ),
      ),
    );

    if (!mounted || result == null) return;
    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
      _locationLabel = result.label;
      _hasCustomLocation = true;
      _usingFallbackLocation = false;
      _noticeMessage = null;
      _showNoticeRetry = false;
    });
    await _locationService.save(
      latitude: result.latitude,
      longitude: result.longitude,
      label: result.label,
    );
    await _refreshMosques();
  }

  Future<
    ({
      double lat,
      double lng,
      String label,
      bool usingFallbackLocation,
      _LocationFallbackReason reason,
    })
  >
  _resolveCoordinates() async {
    if (!useDeviceLocationNotifier.value) {
      return (
        lat: _fallbackLat,
        lng: _fallbackLng,
        label: _fallbackLabel,
        usingFallbackLocation: true,
        reason: _LocationFallbackReason.appSettingOff,
      );
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (
          lat: _fallbackLat,
          lng: _fallbackLng,
          label: _fallbackLabel,
          usingFallbackLocation: true,
          reason: _LocationFallbackReason.serviceDisabled,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return (
          lat: _fallbackLat,
          lng: _fallbackLng,
          label: _fallbackLabel,
          usingFallbackLocation: true,
          reason: _LocationFallbackReason.permissionDenied,
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return (
          lat: _fallbackLat,
          lng: _fallbackLng,
          label: _fallbackLabel,
          usingFallbackLocation: true,
          reason: _LocationFallbackReason.permissionDeniedForever,
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
        reason: _LocationFallbackReason.none,
      );
    } catch (_) {
      return (
        lat: _fallbackLat,
        lng: _fallbackLng,
        label: _fallbackLabel,
        usingFallbackLocation: true,
        reason: _LocationFallbackReason.error,
      );
    }
  }

  Future<String> _resolveLocationLabel(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) {
        return _text('Current location', 'বর্তমান লোকেশন');
      }
      final place = placemarks.first;
      final city =
          place.locality ??
          place.subAdministrativeArea ??
          place.administrativeArea ??
          _text('Current location', 'বর্তমান লোকেশন');
      final country = place.country;
      if (country == null || country.isEmpty) return city;
      return '$city, $country';
    } catch (_) {
      return _text('Current location', 'বর্তমান লোকেশন');
    }
  }

  String _distanceText(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    if (km >= 10) return '${km.toStringAsFixed(0)} km';
    return '${km.toStringAsFixed(1)} km';
  }

  Future<void> _onTapDirection(MosqueItem item) async {
    final destination =
        '${item.latitude.toStringAsFixed(6)},${item.longitude.toStringAsFixed(6)}';
    final encodedName = Uri.encodeComponent(item.name);
    final launchCandidates = <Uri>[
      Uri.parse('google.navigation:q=$destination'),
      Uri.parse('geo:$destination?q=$destination($encodedName)'),
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving',
      ),
    ];

    for (final uri in launchCandidates) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      } catch (_) {
        // Try next URI fallback.
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text(
            'Could not open map app on this device.',
            'এই ডিভাইসে ম্যাপ অ্যাপ খোলা যায়নি।',
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onRetry,
  }) {
    final glass = NoorifyGlassTheme(context);
    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: NoorifyGlassCard(
        padding: EdgeInsets.all(16.r),
        radius: BorderRadius.circular(16.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: glass.textSecondary),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: glass.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: glass.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (onRetry != null) ...[
                    SizedBox(height: 10.h),
                    SizedBox(
                      height: 30.h,
                      child: FilledButton(
                        onPressed: onRetry,
                        style: FilledButton.styleFrom(
                          backgroundColor: glass.accent,
                          foregroundColor: glass.isDark
                              ? const Color(0xFF072734)
                              : Colors.white,
                          textStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.sp,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(_text('Retry', 'আবার চেষ্টা করুন')),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMosqueThumbnail() {
    final glass = NoorifyGlassTheme(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: SizedBox(
        width: 64.r,
        height: 64.r,
        child: Image.asset(
          'assets/images/header-bg.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: glass.isDark
                  ? const Color(0x33214255)
                  : const Color(0xFFE8F0F5),
              alignment: Alignment.center,
              child: Icon(
                Icons.location_city_rounded,
                color: glass.textSecondary,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMosqueRow(MosqueItem item) {
    final glass = NoorifyGlassTheme(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildMosqueThumbnail(),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: glass.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  item.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: glass.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 7.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: glass.isDark
                        ? const Color(0x2A2EB8E6)
                        : const Color(0x221EA8B8),
                    borderRadius: BorderRadius.circular(1000.r),
                  ),
                  child: Text(
                    _distanceText(item.distanceKm),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: glass.accentSoft,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          SizedBox(
            height: 34.h,
            child: FilledButton.icon(
              onPressed: () => _onTapDirection(item),
              style: FilledButton.styleFrom(
                backgroundColor: glass.accent,
                foregroundColor: glass.isDark
                    ? const Color(0xFF072734)
                    : Colors.white,
                shape: const StadiumBorder(),
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                minimumSize: Size(0.w, 34.h),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(Icons.near_me_rounded, size: 14.sp),
              label: Text(
                _text('Direction', 'দিকনির্দেশ'),
                style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMosqueList() {
    final glass = NoorifyGlassTheme(context);
    final items = _visibleMosques;
    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.only(top: 28.h),
        child: Center(
          child: SizedBox(
            width: 24.r,
            height: 24.r,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: glass.accent,
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return _buildEmptyState(
        icon: Icons.wifi_off_rounded,
        title: _text(
          'Could not load nearest mosques.',
          'নিকটবর্তী মসজিদ লোড করা যায়নি।',
        ),
        subtitle: _error!,
        onRetry: () => _refreshMosques(forceResolveLocation: true),
      );
    }

    if (items.isEmpty) {
      final subtitle = _query.isEmpty
          ? _text(
              'Try changing radius or refreshing location.',
              'রেডিয়াস বদলে দেখুন বা লোকেশন রিফ্রেশ করুন।',
            )
          : _text(
              'No mosque matches your search.',
              'আপনার খোঁজার সাথে মিলে এমন মসজিদ পাওয়া যায়নি।',
            );
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: _text('No result found', 'কোনো ফলাফল পাওয়া যায়নি'),
        subtitle: subtitle,
        onRetry: _showNoticeRetry
            ? () => _refreshMosques(forceResolveLocation: true)
            : null,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1.h, thickness: 1, color: glass.glassBorder),
      itemBuilder: (context, index) => _buildMosqueRow(items[index]),
    );
  }

  Widget _buildNoticeBanner() {
    final glass = NoorifyGlassTheme(context);
    final message = _noticeMessage;
    if (message == null || message.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(top: 2.h, bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: glass.isDark ? const Color(0x2E8E6A1E) : const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: glass.isDark
              ? const Color(0x4FB58B34)
              : const Color(0xFFF0DDA9),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16.sp,
            color: glass.isDark
                ? const Color(0xFFE5BE70)
                : const Color(0xFF9A7A27),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.sp,
                color: glass.isDark
                    ? const Color(0xFFF2D8A1)
                    : const Color(0xFF8A6B24),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_showNoticeRetry)
            TextButton(
              onPressed: () => _refreshMosques(forceResolveLocation: true),
              style: TextButton.styleFrom(
                foregroundColor: glass.isDark
                    ? const Color(0xFFE5BE70)
                    : const Color(0xFF8A6B24),
                textStyle: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
                minimumSize: Size(0.w, 24.h),
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 0.h),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(_text('Retry', 'আবার চেষ্টা করুন')),
            ),
        ],
      ),
    );
  }

  String _lastUpdatedLabel(DateTime value) {
    final time = TimeOfDay.fromDateTime(value);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    final date =
        '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    return '$date $hour:$minute $suffix';
  }

  Widget _buildLastUpdatedHeader() {
    final glass = NoorifyGlassTheme(context);
    final updatedAt = _lastUpdatedAt;
    if (updatedAt == null) return const SizedBox.shrink();

    final prefix = _showingCachedData
        ? _text('Last updated (cached)', 'সর্বশেষ আপডেট (ক্যাশড)')
        : _text('Last updated', 'সর্বশেষ আপডেট');
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(Icons.update_rounded, size: 14.sp, color: glass.textMuted),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              '$prefix: ${_lastUpdatedLabel(updatedAt)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5.sp,
                color: glass.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    RefreshIndicator(
                      color: glass.accent,
                      onRefresh: () =>
                          _refreshMosques(forceResolveLocation: true),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 94.h),
                        children: [
                          Row(
                            children: [
                              Material(
                                color: glass.isDark
                                    ? const Color(0x332EB8E6)
                                    : const Color(0x221EA8B8),
                                shape: const CircleBorder(),
                                child: IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () =>
                                      Navigator.of(context).maybePop(),
                                  icon: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 18.sp,
                                    color: glass.textPrimary,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                _text('Nearest Mosque', 'নিকটবর্তী মসজিদ'),
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w700,
                                  color: glass.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          NoorifyGlassCard(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 8.h,
                            ),
                            radius: BorderRadius.circular(18.r),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    style: TextStyle(color: glass.textPrimary),
                                    decoration: InputDecoration(
                                      hintText: _text('Search', 'খুঁজুন'),
                                      hintStyle: TextStyle(
                                        color: glass.textMuted,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 10.h,
                                          ),
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        size: 20.sp,
                                        color: glass.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                IconButton.filledTonal(
                                  tooltip: _text(
                                    'Set location',
                                    'লোকেশন সেট করুন',
                                  ),
                                  onPressed: _openSetLocation,
                                  style: IconButton.styleFrom(
                                    backgroundColor: glass.isDark
                                        ? const Color(0x332EB8E6)
                                        : const Color(0x221EA8B8),
                                    foregroundColor: glass.accent,
                                  ),
                                  icon: Icon(
                                    Icons.map_outlined,
                                    size: 20.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 14.h),
                          _buildLastUpdatedHeader(),
                          _buildNoticeBanner(),
                          _buildMosqueList(),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 10.w,
                      bottom: 10.h,
                      child: Material(
                        color: glass.isDark
                            ? const Color(0xEE112233)
                            : Colors.white.withValues(alpha: 0.95),
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: IconButton(
                          onPressed: () =>
                              _refreshMosques(forceResolveLocation: true),
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
              bottomNav(context, 1),
            ],
          ),
        ),
      ),
    );
  }
}
