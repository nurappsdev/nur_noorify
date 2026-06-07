part of '../screens/surah_detail_screen.dart';

/// Tafsir bottom sheet and the bookmarks list screen launcher.
mixin SurahDetailSheetsMixin
    on
        State<SurahDetailScreen>,
        SurahDetailStateMixin,
        SurahDetailBookmarkMixin {
  Future<void> _openAyahTafsirSheet(int ayahIndex) async {
    final detail = _detail;
    if (detail == null) return;

    final ayahNo = ayahIndex + 1;
    _trackLastReadAyah(ayahNo);
    final tafsirFuture = _tafsir.fetchBanglaTafsir(
      surahNo: detail.surahNo,
      ayahNo: ayahNo,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final sheetHeight = MediaQuery.of(sheetContext).size.height * 0.82;
        return Container(
          height: sheetHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: FutureBuilder<QuranAyahTafsir>(
            future: tafsirFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12.h),
                      Text(
                        'Loading and saving Bangla tafsir...',
                        style: TextStyle(color: BrandColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return Padding(
                  padding: EdgeInsets.all(20.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Ayah ${_toBanglaDigits(ayahNo.toString())} Tafsir',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: BrandColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Please check your internet connection and try again. After the first successful load, the tafsir will be saved offline for future access.',
                        style: TextStyle(
                          fontSize: 14.sp,
                          height: 1.5,
                          color: BrandColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final tafsir = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 12.w, 8.h),
                    child: Row(
                      children: [
                        Text(
                          'Ayah ${_toBanglaDigits(ayahNo.toString())} Tafsir',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: BrandColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 10.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            tafsir.resourceName,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: BrandColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (tafsir.fromOfflineCache)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: BrandColors.tintBackgroundStrong,
                              borderRadius: BorderRadius.circular(999.r),
                            ),
                            child: Text(
                              'Downloaded',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: BrandColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 20.h),
                      children: [
                        SelectableText(
                          tafsir.text,
                          style: TextStyle(
                            fontSize: 16.sp,
                            height: 1.75,
                            color: BrandColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openBookmarksScreen() async {
    final items = _bookmarksByAyahNo.values.toList(growable: false)
      ..sort((a, b) => a.ayahNo.compareTo(b.ayahNo));
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('No bookmarks in this surah', 'এই সূরায় কোনো বুকমার্ক নেই'),
          ),
        ),
      );
      return;
    }

    final selected = await Navigator.of(context).push<QuranAyahBookmark>(
      MaterialPageRoute<QuranAyahBookmark>(
        builder: (_) => QuranBookmarksScreen(bookmarks: items),
      ),
    );

    if (selected == null) return;
    final ayahIndex = selected.ayahNo - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToAyah(ayahIndex);
    });
  }
}
