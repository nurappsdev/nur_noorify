part of '../screens/surah_detail_screen.dart';

/// The translucent surah app bar with title, bookmarks and audio actions.
mixin SurahDetailAppbarMixin
    on
        State<SurahDetailScreen>,
        SurahDetailStateMixin,
        SurahDetailSheetsMixin {
  PreferredSizeWidget _buildAppBar({
    required String headerArabicName,
    required int headerAyahTo,
  }) {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: _screenTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 96,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(_didDownloadAudio),
        icon: Container(
          width: 36.r,
          height: 36.r,
          decoration: BoxDecoration(
            color: _isDarkTheme
                ? const Color(0x332EB8E6)
                : const Color(0x1A1EA8B8),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back_rounded, color: _screenTextPrimary),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            headerArabicName,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _screenTextPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 24.sp,
              height: 1,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            widget.chapter.surahName,
            style: TextStyle(
              color: _screenTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18.sp,
            ),
          ),
          Text(
            'Ayah 1-$headerAyahTo',
            style: TextStyle(
              color: _screenTextMuted,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(14),
        child: Padding(
          padding: EdgeInsets.only(bottom: 6.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88.w,
                height: 2.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999.r),
                  gradient: LinearGradient(
                    colors: [
                      _accent.withValues(alpha: 0),
                      _accent.withValues(alpha: 0.85),
                      _accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Bookmarks',
          onPressed: _openBookmarksScreen,
          icon: _bookmarksByAyahNo.isNotEmpty
              ? Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 36.r,
                      height: 36.r,
                      decoration: BoxDecoration(
                        color: _isDarkTheme
                            ? const Color(0x332EB8E6)
                            : const Color(0x1A1EA8B8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.bookmarks_rounded,
                        color: _screenTextPrimary,
                      ),
                    ),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD54F),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                )
              : Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: _isDarkTheme
                        ? const Color(0x332EB8E6)
                        : const Color(0x1A1EA8B8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bookmarks_outlined,
                    color: _screenTextPrimary,
                  ),
                ),
        ),
        IconButton(
          tooltip: 'Audio player',
          onPressed: _detail == null
              ? null
              : () => setState(() => _showBottomPlayer = true),
          icon: Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: _isDarkTheme
                  ? const Color(0x332EB8E6)
                  : const Color(0x1A1EA8B8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.headphones_rounded,
              color: _screenTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
