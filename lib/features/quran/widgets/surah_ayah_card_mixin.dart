part of '../screens/surah_detail_screen.dart';

/// The full ayah card: number/actions header, Arabic, translation, tafsir hint
/// and an optional bookmark note.
mixin SurahDetailAyahCardMixin
    on
        State<SurahDetailScreen>,
        SurahDetailStateMixin,
        SurahDetailAyahPartsMixin {
  Widget _buildAyahCard({
    Key? itemKey,
    required int index,
    required String arabic,
    required String bengali,
    required QuranAyahBookmark? bookmark,
    required bool highlighted,
    required int highlightedWordIndex,
    required VoidCallback onTap,
    required VoidCallback onPlayAyah,
    required VoidCallback onBookmarkTap,
    required bool isSingleAyahPlaying,
  }) {
    final hasBookmark = bookmark != null;
    final bookmarkNote = bookmark?.note.trim() ?? '';
    final hideBanglaInHifz = _hifzModeEnabled && _hifzHideBanglaMeaning;
    final ayahContainerBorder = highlighted
        ? const Color(0x8846BDEB)
        : (_isDarkTheme ? const Color(0x334E789D) : const Color(0xFFCCE0EE));
    final ayahContainerBg = highlighted
        ? (_isDarkTheme ? const Color(0xB01B2D33) : const Color(0xFFFCFEFF))
        : (_isDarkTheme ? const Color(0xA014242B) : const Color(0xFFFDFEFF));
    final ayahContainerGradient = _isDarkTheme
        ? null
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: highlighted
                ? const [Color(0xFFFEFFFF), Color(0xFFF3FAFF)]
                : const [Color(0xFFFEFFFF), Color(0xFFF6FBFF)],
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: AnimatedContainer(
          key: itemKey,
          duration: const Duration(milliseconds: 260),
          padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
          decoration: BoxDecoration(
            color: ayahContainerBg,
            gradient: ayahContainerGradient,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: ayahContainerBorder,
              width: highlighted ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isDarkTheme
                    ? const Color(0x26000000)
                    : const Color(0x120E3853),
                blurRadius: highlighted ? 16 : 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (!_isDarkTheme)
                Positioned(
                  left: -26,
                  top: -28,
                  child: IgnorePointer(
                    child: Container(
                      width: 180.w,
                      height: 74.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999.r),
                        gradient: const LinearGradient(
                          colors: [Color(0x45FFFFFF), Color(0x00FFFFFF)],
                        ),
                      ),
                    ),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAyahCardHeader(
                    index: index,
                    highlighted: highlighted,
                    hasBookmark: hasBookmark,
                    isSingleAyahPlaying: isSingleAyahPlaying,
                    onPlayAyah: onPlayAyah,
                    onBookmarkTap: onBookmarkTap,
                  ),
                  if (arabic.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _buildArabicAyahText(
                        arabic: arabic,
                        highlightedWordIndex: highlighted
                            ? highlightedWordIndex
                            : -1,
                      ),
                    ),
                  ],
                  if (bengali.isNotEmpty && !hideBanglaInHifz) ...[
                    SizedBox(height: 7.h),
                    Text(
                      bengali,
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.62,
                        color: _screenTextPrimary,
                      ),
                    ),
                  ],
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 14.sp,
                        color: _screenTextMuted,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Tap for Bangla tafsir (saved offline)',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: _screenTextMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (bookmarkNote.isNotEmpty) ...[
                    SizedBox(height: 7.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: _isDarkTheme
                            ? const Color(0x332EB8E6)
                            : const Color(0x221EA8B8),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: _glassBorder),
                      ),
                      child: Text(
                        bookmarkNote,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: _screenTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
