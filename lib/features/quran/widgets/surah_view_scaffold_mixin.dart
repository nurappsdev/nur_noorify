part of '../screens/surah_detail_screen.dart';

/// Top-level scaffold composition and the scrollable ayah list body.
mixin SurahDetailScaffoldMixin
    on
        State<SurahDetailScreen>,
        SurahDetailStateMixin,
        SurahDetailDataMixin,
        SurahDetailBookmarkMixin,
        SurahDetailSheetsMixin,
        SurahDetailSingleAyahMixin,
        SurahDetailAyahPartsMixin,
        SurahDetailAyahCardMixin,
        SurahDetailViewCardsMixin,
        SurahDetailAudioCardMixin,
        SurahDetailAppbarMixin {
  @override
  Widget build(BuildContext context) {
    final detailForHeader = _detail;
    final headerArabicName = detailForHeader == null
        ? widget.chapter.surahNameArabic
        : (detailForHeader.surahNameArabic.trim().isEmpty
              ? widget.chapter.surahNameArabic
              : detailForHeader.surahNameArabic);
    final headerAyahTo = detailForHeader == null
        ? math.max(widget.chapter.totalAyah, 1)
        : math.max(
            detailForHeader.arabicAyahs.length,
            detailForHeader.bengaliAyahs.length,
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_didDownloadAudio);
      },
      child: Scaffold(
        backgroundColor: _bgBottom,
        appBar: _buildAppBar(
          headerArabicName: headerArabicName,
          headerAyahTo: headerAyahTo,
        ),
        bottomNavigationBar: _detail != null && _showBottomPlayer
            ? _buildAudioCard(_detail!)
            : null,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_bgTop, _bgMid, _bgBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -90,
            child: Container(
              width: 250.r,
              height: 250.r,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x332EB8E6), Color(0x00000000)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 220.h,
            right: -110,
            child: Container(
              width: 260.r,
              height: 260.r,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x222EB8E6), Color(0x00000000)],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Center(child: CircularProgressIndicator(color: _accent))
          else if (_error != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _screenTextPrimary),
                  ),
                  SizedBox(height: 10.h),
                  FilledButton(
                    onPressed: _loadSurahDetail,
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: _isDarkTheme
                          ? const Color(0xFF082736)
                          : Colors.white,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          else
            Builder(
              builder: (context) {
                final detail = _detail!;
                final totalAyah = math.max(
                  detail.arabicAyahs.length,
                  math.max(
                    detail.bengaliAyahs.length,
                    detail.englishAyahs.length,
                  ),
                );
                final activeAyahIndex = _activeAyahIndex(totalAyah);
                _maybeAutoScrollToAyah(activeAyahIndex);
                _jumpToInitialAyahIfNeeded();
                if (activeAyahIndex >= 0) {
                  _trackLastReadAyah(activeAyahIndex + 1);
                }

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    _showBottomPlayer ? 20 : 24,
                  ),
                  itemCount: totalAyah + 1,
                  separatorBuilder: (_, index) =>
                      SizedBox(height: index == 0 ? 12 : 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildSurahIntroCard(
                        detail: detail,
                        totalAyah: totalAyah,
                        activeAyahIndex: activeAyahIndex,
                      );
                    }

                    final ayahIndex = index - 1;
                    final arabic = ayahIndex < detail.arabicAyahs.length
                        ? detail.arabicAyahs[ayahIndex]
                        : '';
                    final bangla = ayahIndex < detail.bengaliAyahs.length
                        ? _repairMojibake(detail.bengaliAyahs[ayahIndex])
                        : '';
                    final english = ayahIndex < detail.englishAyahs.length
                        ? _repairMojibake(detail.englishAyahs[ayahIndex])
                        : '';
                    final useEnglishTranslation =
                        _translationLanguage.toLowerCase() == 'english';
                    final translation = !_showTranslation
                        ? ''
                        : (useEnglishTranslation
                              ? (english.isEmpty ? bangla : english)
                              : bangla);
                    final bookmark = _bookmarkForAyah(ayahIndex + 1);
                    final wordHighlightIndex = _activeWordIndexForAyah(
                      ayahIndex,
                      arabic,
                    );

                    return _buildAyahCard(
                      itemKey: _keyForAyahItem(ayahIndex),
                      index: ayahIndex,
                      arabic: arabic,
                      bengali: translation,
                      bookmark: bookmark,
                      highlighted: ayahIndex == activeAyahIndex,
                      highlightedWordIndex: wordHighlightIndex,
                      onTap: () => _openAyahTafsirSheet(ayahIndex),
                      onPlayAyah: () => _playSingleAyah(ayahIndex),
                      onBookmarkTap: () =>
                          _openAyahBookmarkSheet(ayahIndex),
                      isSingleAyahPlaying:
                          _singleAyahMode &&
                          _singleAyahIndex == ayahIndex &&
                          _isPlaying,
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
