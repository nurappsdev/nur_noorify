import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:first_project/features/asmaul_husna/models/asma_name.dart';
import 'package:first_project/features/asmaul_husna/services/asma_service.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';

class AsmaScreen extends StatefulWidget {
  const AsmaScreen({super.key});

  @override
  State<AsmaScreen> createState() => _AsmaScreenState();
}

class _AsmaScreenState extends State<AsmaScreen> {
  final AsmaService _asmaService = AsmaService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  String _query = '';
  List<AsmaName> _names = const [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadAsmaNames();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() => _query = _searchController.text.trim().toLowerCase());
  }

  Future<void> _loadAsmaNames() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final names = await _asmaService.loadAsmaNames();
      if (!mounted) return;
      setState(() {
        _names = names;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<AsmaName> get _filteredNames {
    if (_query.isEmpty) return _names;
    return _names
        .where((item) {
          return item.id.toString().contains(_query) ||
              item.arabic.contains(_query) ||
              item.transliteration.toLowerCase().contains(_query) ||
              item.englishMeaning.toLowerCase().contains(_query) ||
              item.banglaName.toLowerCase().contains(_query) ||
              item.banglaMeaning.toLowerCase().contains(_query);
        })
        .toList(growable: false);
  }

  void _onTapPlay(AsmaName item) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audio playback integration is next step.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredNames = _filteredNames;
    final glass = NoorifyGlassTheme(context);

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              _AsmaHeader(
                searchController: _searchController,
                total: _names.length,
                shown: filteredNames.length,
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: glass.accent),
                      )
                    : _error != null
                    ? _AsmaErrorView(error: _error!, onRetry: _loadAsmaNames)
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 10.h),
                        itemCount: filteredNames.length,
                        separatorBuilder: (_, _) => SizedBox(height: 10.h),
                        itemBuilder: (context, index) {
                          final item = filteredNames[index];
                          final hasAudio = (item.audio ?? '').trim().isNotEmpty;
                          return _AsmaNameCard(
                            item: item,
                            hasAudio: hasAudio,
                            onPlay: () => _onTapPlay(item),
                          );
                        },
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

class _AsmaHeader extends StatelessWidget {
  const _AsmaHeader({
    required this.searchController,
    required this.total,
    required this.shown,
  });

  final TextEditingController searchController;
  final int total;
  final int shown;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 0),
      child: NoorifyGlassCard(
        padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
        radius: BorderRadius.circular(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Asma Ul Husna',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: glass.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: glass.isDark
                        ? const Color(0x332EB8E6)
                        : const Color(0x1F1EA8B8),
                    borderRadius: BorderRadius.circular(999.r),
                    border: Border.all(color: glass.glassBorder),
                  ),
                  child: Text(
                    '$shown/$total',
                    style: TextStyle(
                      color: glass.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              '99 Beautiful Names of Allah',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: glass.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: searchController,
              style: TextStyle(color: glass.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search name, meaning, or number',
                hintStyle: TextStyle(color: glass.textMuted),
                prefixIcon: Icon(Icons.search_rounded, color: glass.textMuted),
                filled: true,
                fillColor: glass.isDark
                    ? const Color(0x4412272E)
                    : const Color(0xECFFFFFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: glass.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: glass.glassBorder),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 10.h,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AsmaErrorView extends StatelessWidget {
  const _AsmaErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: glass.textSecondary),
            ),
            SizedBox(height: 10.h),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: glass.accent,
                foregroundColor: glass.isDark
                    ? const Color(0xFF032F35)
                    : Colors.white,
              ),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AsmaNameCard extends StatelessWidget {
  const _AsmaNameCard({
    required this.item,
    required this.hasAudio,
    required this.onPlay,
  });

  final AsmaName item;
  final bool hasAudio;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return NoorifyGlassCard(
      padding: EdgeInsets.all(12.r),
      radius: BorderRadius.circular(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.r,
                height: 34.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: glass.isDark
                      ? const Color(0x332EB8E6)
                      : const Color(0x221EA8B8),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  item.id.toString(),
                  style: TextStyle(
                    color: glass.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: hasAudio ? 'Play audio' : 'No audio yet',
                onPressed: hasAudio ? onPlay : null,
                style: IconButton.styleFrom(
                  backgroundColor: glass.isDark
                      ? const Color(0x3316383E)
                      : const Color(0x221EA8B8),
                  foregroundColor: glass.accent,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Center(
            child: Text(
              item.arabic,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 31.sp,
                fontWeight: FontWeight.w600,
                color: glass.isDark
                    ? const Color(0xFFEAF5FF)
                    : const Color(0xFF21465D),
                height: 1.2,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            item.transliteration,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: glass.accentSoft,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            item.englishMeaning,
            style: TextStyle(fontSize: 13.sp, color: glass.textSecondary),
          ),
          SizedBox(height: 2.h),
          Text(
            '${item.banglaName} - ${item.banglaMeaning}',
            style: TextStyle(fontSize: 13.sp, color: glass.textMuted),
          ),
        ],
      ),
    );
  }
}
