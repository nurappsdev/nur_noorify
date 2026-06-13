part of '../screens/surah_detail_screen.dart';

/// Reusable sub-pieces of an ayah card: the action header row, the rich
/// Arabic text with word highlighting, and the active-word resolver.
mixin SurahDetailAyahPartsMixin
    on State<SurahDetailScreen>, SurahDetailStateMixin, SurahDetailDataMixin {
  int _activeWordIndexForAyah(int ayahIndex, String arabicText) {
    final hasPlaybackStarted = _isPlaying || _position > Duration.zero;
    if (!hasPlaybackStarted) return -1;
    if (_timingSegments.isEmpty || arabicText.trim().isEmpty) return -1;
    final timing = _timingSegmentForAyah(ayahIndex);
    if (timing == null || timing.wordSegments.isEmpty) return -1;

    final currentMs = _position.inMilliseconds;
    for (final word in timing.wordSegments) {
      if (currentMs >= word.fromMs && currentMs <= word.toMs) {
        return word.wordIndex;
      }
    }

    if (currentMs > timing.wordSegments.last.toMs) {
      return timing.wordSegments.last.wordIndex;
    }
    if (currentMs < timing.wordSegments.first.fromMs) {
      return timing.wordSegments.first.wordIndex;
    }
    return -1;
  }

  Widget _buildArabicAyahText({
    required String arabic,
    required int highlightedWordIndex,
  }) {
    final baseStyle = TextStyle(
      fontSize: 33.sp,
      height: 1.55,
      fontWeight: FontWeight.w500,
      color: _screenTextPrimary,
    );

    final cleaned = arabic.trim();
    if (cleaned.isEmpty) {
      return const SizedBox.shrink();
    }

    if (highlightedWordIndex < 0) {
      return Text(
        cleaned,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: baseStyle,
      );
    }

    final words = cleaned.split(RegExp(r'\s+'));
    if (words.isEmpty) {
      return Text(
        cleaned,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: baseStyle,
      );
    }

    final maxWordIndex = words.length - 1;
    final safeWordIndex = highlightedWordIndex.clamp(0, maxWordIndex);

    final spans = <InlineSpan>[];
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final isHighlighted = i == safeWordIndex;
      spans.add(
        TextSpan(
          text: i == words.length - 1 ? word : '$word ',
          style: baseStyle.copyWith(
            color: isHighlighted ? _accent : _screenTextPrimary,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
            backgroundColor: isHighlighted
                ? (_isDarkTheme
                      ? const Color(0x552EB8E6)
                      : const Color(0x331EA8B8))
                : Colors.transparent,
          ),
        ),
      );
    }

    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      text: TextSpan(children: spans),
    );
  }

  Widget _buildAyahCardHeader({
    required int index,
    required bool highlighted,
    required bool hasBookmark,
    required bool isSingleAyahPlaying,
    required VoidCallback onPlayAyah,
    required VoidCallback onBookmarkTap,
  }) {
    final ayahNumberBg = highlighted
        ? (_isDarkTheme ? const Color(0xFF2EB8E6) : const Color(0xFF1EA8B8))
        : (_isDarkTheme ? const Color(0x402EB8E6) : const Color(0x331EA8B8));

    return Row(
      children: [
        Container(
          width: 30.r,
          height: 30.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ayahNumberBg,
            shape: BoxShape.circle,
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: const Color(0x662EB8E6),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Text(
            _toBanglaDigits((index + 1).toString()),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.sp,
              color: highlighted
                  ? (_isDarkTheme
                        ? const Color(0xFF082734)
                        : Colors.white)
                  : _accent,
            ),
          ),
        ),
        const Spacer(),
        Container(
          width: 34.r,
          height: 34.r,
          decoration: BoxDecoration(
            color: hasBookmark
                ? (_isDarkTheme
                      ? const Color(0x332EB8E6)
                      : const Color(0x211EA8B8))
                : (_isDarkTheme
                      ? const Color(0x221D3037)
                      : const Color(0x120E3853)),
            borderRadius: BorderRadius.circular(999.r),
            border: Border.all(color: _glassBorder),
          ),
          child: IconButton(
            tooltip: hasBookmark
                ? 'Edit bookmark note'
                : 'Bookmark this ayah',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            onPressed: onBookmarkTap,
            icon: Icon(
              hasBookmark
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              size: 20.sp,
              color: hasBookmark ? _accent : _screenTextMuted,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          width: 34.r,
          height: 34.r,
          decoration: BoxDecoration(
            color: _isDarkTheme
                ? const Color(0x2D2EB8E6)
                : const Color(0x251EA8B8),
            borderRadius: BorderRadius.circular(999.r),
            border: Border.all(color: _glassBorder),
          ),
          child: IconButton(
            tooltip: isSingleAyahPlaying
                ? 'Playing this ayah'
                : 'Play this ayah',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            onPressed: onPlayAyah,
            icon: Icon(
              isSingleAyahPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              size: 21.sp,
              color: _accent,
            ),
          ),
        ),
      ],
    );
  }
}
