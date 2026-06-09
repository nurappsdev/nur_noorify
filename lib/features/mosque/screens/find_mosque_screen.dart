import 'dart:async';
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
import 'package:first_project/features/mosque/utils/mosque_utils.dart';
import 'package:first_project/features/mosque/widgets/mosque_empty_state.dart';
import 'package:first_project/features/mosque/widgets/mosque_list_item.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

enum _FallbackReason { none, appOff, serviceDisabled, denied, deniedForever, error }

class FindMosqueScreen extends StatefulWidget {
  const FindMosqueScreen({super.key});
  @override
  State<FindMosqueScreen> createState() => _FindMosqueScreenState();
}

class _FindMosqueScreenState extends State<FindMosqueScreen> {
  final MosqueService _mosqueService = MosqueService();
  final MosqueLocationService _locService = MosqueLocationService();
  final MosqueResultsCacheService _resCache = MosqueResultsCacheService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true, _hasCustom = false, _usingFallback = false, _showRetry = false;
  String? _error, _notice;
  DateTime? _lastUpdate;
  String _query = '', _label = 'Detecting...';
  double? _lat, _lng;
  List<MosqueItem> _mosques = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim().toLowerCase()));
    useDeviceLocationNotifier.addListener(_onLocPrefChanged);
    _init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    useDeviceLocationNotifier.removeListener(_onLocPrefChanged);
    super.dispose();
  }

  void _onLocPrefChanged() { if (!_hasCustom) _refresh(force: true); }

  Future<void> _init() async {
    final s = await _locService.load();
    if (!mounted) return;
    if (s != null) { setState(() { _lat = s.latitude; _lng = s.longitude; _label = s.label; _hasCustom = true; }); await _refresh(); return; }
    await _refresh(force: true);
  }

  Future<void> _refresh({bool force = false}) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = (_hasCustom && _lat != null) ? (lat: _lat!, lng: _lng!, label: _label, usingFallback: false, reason: _FallbackReason.none) : (force || _lat == null) ? await _resolve() : (lat: _lat!, lng: _lng!, label: _label, usingFallback: _usingFallback, reason: _FallbackReason.none);
      final items = await _mosqueService.fetchNearbyMosques(latitude: res.lat, longitude: res.lng, radiusMeters: 5000);
      await _resCache.save(queryLatitude: res.lat, queryLongitude: res.lng, radiusMeters: 5000, items: items);
      final n = _noticeFor(res.reason);
      if (mounted) setState(() { _lat = res.lat; _lng = res.lng; _label = res.label; _usingFallback = res.usingFallback; _mosques = items; _lastUpdate = DateTime.now(); _notice = _hasCustom ? null : n.m; _showRetry = _hasCustom ? false : n.r; _isLoading = false; });
    } catch (e) {
      var m = MosqueUtils.text('Could not load mosques.', 'মসজিদ লোড করা যায়নি।');
      if (e is MosqueLookupException && (e.type == MosqueLookupErrorType.network || e.type == MosqueLookupErrorType.server)) {
        final c = await _resCache.load();
        if (c != null && mounted) { setState(() { _mosques = c.items; _lastUpdate = c.updatedAt; _notice = MosqueUtils.text('Offline mode', 'অফলাইন মোড'); _showRetry = true; _isLoading = false; }); return; }
      }
      if (mounted) setState(() { _error = m; _showRetry = true; _isLoading = false; });
    }
  }

  ({String? m, bool r}) _noticeFor(_FallbackReason reason) {
    switch (reason) {
      case _FallbackReason.appOff: return (m: MosqueUtils.text('Location off.', 'লোকেশন বন্ধ।'), r: true);
      case _FallbackReason.serviceDisabled: return (m: MosqueUtils.text('Service disabled.', 'সার্ভিস বন্ধ।'), r: true);
      case _FallbackReason.denied: return (m: MosqueUtils.text('Permission denied.', 'পারমিশন নেই।'), r: true);
      case _FallbackReason.deniedForever: return (m: MosqueUtils.text('Permission denied forever.', 'পারমিশন নেই।'), r: true);
      case _FallbackReason.error: return (m: MosqueUtils.text('Detection error.', 'শনাক্ত করা যায়নি।'), r: true);
      default: return (m: null, r: false);
    }
  }

  Future<_ResolvedLoc> _resolve() async {
    const dLat = 23.7286, dLng = 90.4106, dLab = 'Baitul Mukarram, Dhaka';
    if (!useDeviceLocationNotifier.value) return (lat: dLat, lng: dLng, label: dLab, usingFallback: true, reason: _FallbackReason.appOff);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return (lat: dLat, lng: dLng, label: dLab, usingFallback: true, reason: _FallbackReason.serviceDisabled);
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied) return (lat: dLat, lng: dLng, label: dLab, usingFallback: true, reason: _FallbackReason.denied);
      if (p == LocationPermission.deniedForever) return (lat: dLat, lng: dLng, label: dLab, usingFallback: true, reason: _FallbackReason.deniedForever);
      final pos = await Geolocator.getCurrentPosition();
      final lab = await _resolveLabel(pos.latitude, pos.longitude);
      return (lat: pos.latitude, lng: pos.longitude, label: lab, usingFallback: false, reason: _FallbackReason.none);
    } catch (_) { return (lat: dLat, lng: dLng, label: dLab, usingFallback: true, reason: _FallbackReason.error); }
  }

  Future<String> _resolveLabel(double lat, double lng) async {
    try {
      final p = await placemarkFromCoordinates(lat, lng);
      if (p.isEmpty) return MosqueUtils.text('Current location', 'বর্তমান লোকেশন');
      final city = p.first.locality ?? p.first.subAdministrativeArea ?? MosqueUtils.text('Current location', 'বর্তমান লোকেশন');
      return p.first.country != null ? '$city, ${p.first.country}' : city;
    } catch (_) { return MosqueUtils.text('Current location', 'বর্তমান লোকেশন'); }
  }

  Future<void> _openSetLoc() async {
    final res = await Navigator.of(context).push<LocationSelection>(MaterialPageRoute(builder: (_) => SetLocationScreen(initialLatitude: _lat ?? 23.7286, initialLongitude: _lng ?? 90.4106, initialLabel: _label)));
    if (res == null) return;
    setState(() { _lat = res.latitude; _lng = res.longitude; _label = res.label; _hasCustom = true; _usingFallback = false; _notice = null; });
    await _locService.save(latitude: res.latitude, longitude: res.longitude, label: res.label);
    await _refresh();
  }

  Future<void> _onDir(MosqueItem i) async {
    final d = '${i.latitude},${i.longitude}';
    final u = [Uri.parse('google.navigation:q=$d'), Uri.parse('geo:$d?q=$d(${Uri.encodeComponent(i.name)})'), Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$d&travelmode=driving')];
    for (final uri in u) { try { if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return; } catch (_) {} }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(MosqueUtils.text('Error opening map.', 'ম্যাপ খোলা যায়নি।'))));
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final items = _query.isEmpty ? _mosques : _mosques.where((i) => i.name.toLowerCase().contains(_query) || i.address.toLowerCase().contains(_query)).toList();
    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(children: [
            Expanded(child: Stack(children: [
              RefreshIndicator(color: glass.accent, onRefresh: () => _refresh(force: true), child: ListView(padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 94.h), children: [
                Row(children: [
                  Material(color: glass.isDark ? const Color(0x332EB8E6) : const Color(0x221EA8B8), shape: const CircleBorder(), child: IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18.sp))),
                  SizedBox(width: 8.w), Text(MosqueUtils.text('Nearest Mosque', 'নিকটবর্তী মসজিদ'), style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700, color: glass.textPrimary)),
                ]),
                SizedBox(height: 8.h),
                NoorifyGlassCard(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h), radius: BorderRadius.circular(18.r), child: Row(children: [
                  Expanded(child: TextField(controller: _searchController, decoration: InputDecoration(hintText: MosqueUtils.text('Search', 'খুঁজুন'), border: InputBorder.none, isDense: true, prefixIcon: Icon(Icons.search_rounded, size: 20.sp)))),
                  IconButton.filledTonal(onPressed: _openSetLoc, icon: Icon(Icons.map_outlined, size: 20.sp)),
                ])),
                SizedBox(height: 14.h),
                if (_lastUpdate != null) Row(children: [Icon(Icons.update_rounded, size: 14.sp, color: glass.textMuted), SizedBox(width: 6.w), Expanded(child: Text('${MosqueUtils.text('Updated', 'আপডেট')}: ${MosqueUtils.lastUpdatedLabel(_lastUpdate!)}', style: TextStyle(fontSize: 11.5.sp, color: glass.textMuted, fontWeight: FontWeight.w600)))]),
                if (_notice != null) Container(margin: EdgeInsets.only(top: 2.h, bottom: 10.h), padding: EdgeInsets.all(8.r), decoration: BoxDecoration(color: glass.isDark ? const Color(0x2E8E6A1E) : const Color(0xFFFFF8E8), borderRadius: BorderRadius.circular(12.r)), child: Row(children: [Icon(Icons.info_outline_rounded, size: 16.sp), SizedBox(width: 8.w), Expanded(child: Text(_notice!, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600))), if (_showRetry) TextButton(onPressed: () => _refresh(force: true), child: Text(MosqueUtils.text('Retry', 'আবার')))])),
                if (_isLoading) Padding(padding: EdgeInsets.only(top: 28.h), child: Center(child: CircularProgressIndicator(color: glass.accent)))
                else if (_error != null) MosqueEmptyState(icon: Icons.wifi_off_rounded, title: MosqueUtils.text('Error loading mosques.', 'মসজিদ লোড করা যায়নি।'), subtitle: _error!, onRetry: () => _refresh(force: true))
                else if (items.isEmpty) MosqueEmptyState(icon: Icons.search_off_rounded, title: MosqueUtils.text('No results.', 'ফলাফল পাওয়া যায়নি।'), subtitle: MosqueUtils.text('Try changing radius.', 'রেডিয়াস বদলে দেখুন।'))
                else ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: items.length, separatorBuilder: (_, __) => Divider(height: 1.h, color: glass.glassBorder), itemBuilder: (_, i) => MosqueListItem(item: items[i], onTapDirection: () => _onDir(items[i]))),
              ])),
              Positioned(right: 10.w, bottom: 10.h, child: FloatingActionButton(onPressed: () => _refresh(force: true), mini: true, child: Icon(Icons.my_location_rounded, color: glass.accent))),
            ])),
            bottomNav(context, 1),
          ]),
        ),
      ),
    );
  }
}

typedef _ResolvedLoc = ({double lat, double lng, String label, bool usingFallback, _FallbackReason reason});
