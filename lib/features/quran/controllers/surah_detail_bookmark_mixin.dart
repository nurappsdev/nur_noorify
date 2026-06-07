part of '../screens/surah_detail_screen.dart';

/// Ayah bookmark storage, last-read tracking and the bookmark editor sheet.
mixin SurahDetailBookmarkMixin
    on State<SurahDetailScreen>, SurahDetailStateMixin {
  Future<void> _loadBookmarksForCurrentSurah() async {
    final items = await _bookmarks.readBySurah(widget.chapter.surahNo);
    if (!mounted) return;
    final map = <int, QuranAyahBookmark>{};
    for (final item in items) {
      map[item.ayahNo] = item;
    }
    setState(() => _bookmarksByAyahNo = map);
  }

  QuranAyahBookmark? _bookmarkForAyah(int ayahNo) {
    return _bookmarksByAyahNo[ayahNo];
  }

  Future<void> _saveAyahBookmark({
    required int ayahNo,
    required String note,
  }) async {
    final detail = _detail;
    if (detail == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _bookmarks.upsert(
      QuranAyahBookmark(
        surahNo: detail.surahNo,
        surahName: detail.surahName,
        ayahNo: ayahNo,
        note: note,
        updatedAtMillis: now,
      ),
    );
    await _loadBookmarksForCurrentSurah();
  }

  Future<void> _removeAyahBookmark(int ayahNo) async {
    await _bookmarks.remove(surahNo: widget.chapter.surahNo, ayahNo: ayahNo);
    await _loadBookmarksForCurrentSurah();
  }

  void _scrollToAyah(int ayahIndex, {bool animated = true}) {
    final key = _ayahItemKeys[ayahIndex];
    final contextForAyah = key?.currentContext;
    if (contextForAyah == null) return;
    Scrollable.ensureVisible(
      contextForAyah,
      duration: animated ? const Duration(milliseconds: 260) : Duration.zero,
      curve: Curves.easeOutCubic,
      alignment: 0.16,
    );
  }

  void _trackLastReadAyah(int ayahNo) {
    if (ayahNo <= 0 || _lastSavedAyahNo == ayahNo) return;
    _lastSavedAyahNo = ayahNo;
    unawaited(
      _lastRead.saveLastRead(surahNo: widget.chapter.surahNo, ayahNo: ayahNo),
    );
  }

  void _jumpToInitialAyahIfNeeded() {
    if (_didJumpToInitialAyah) return;
    final initialAyahNo = widget.initialAyahNo;
    if (initialAyahNo == null || initialAyahNo <= 0) return;
    _didJumpToInitialAyah = true;
    _trackLastReadAyah(initialAyahNo);
    final ayahIndex = initialAyahNo - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 140));
      if (!mounted) return;
      _scrollToAyah(ayahIndex, animated: false);
    });
  }

  Future<void> _openAyahBookmarkSheet(int ayahIndex) async {
    final detail = _detail;
    if (detail == null) return;
    final ayahNo = ayahIndex + 1;
    _trackLastReadAyah(ayahNo);
    final existing = _bookmarkForAyah(ayahNo);
    final noteController = TextEditingController(text: existing?.note ?? '');

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_t('Ayah', 'আয়াত')} ${_toBanglaDigits(ayahNo.toString())} ${_t('Bookmark', 'বুকমার্ক')}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: BrandColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _t(
                    'Add your note for this ayah...',
                    'এই আয়াতের জন্য আপনার নোট লিখুন...',
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FBFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: BrandColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: BrandColors.border),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  if (existing != null) ...[
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(sheetContext).pop('remove'),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(_t('Remove', 'মুছুন')),
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(sheetContext).pop('save'),
                      icon: const Icon(Icons.bookmark_rounded),
                      label: Text(
                        existing == null
                            ? _t('Save Bookmark', 'বুকমার্ক সেভ করুন')
                            : _t('Update', 'আপডেট করুন'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (action == null || !mounted) {
      noteController.dispose();
      return;
    }

    if (action == 'remove') {
      await _removeAyahBookmark(ayahNo);
      if (!mounted) {
        noteController.dispose();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('Bookmark removed', 'বুকমার্ক সরানো হয়েছে'))),
      );
      noteController.dispose();
      return;
    }

    final note = noteController.text.trim();
    await _saveAyahBookmark(ayahNo: ayahNo, note: note);
    if (!mounted) {
      noteController.dispose();
      return;
    }
    final message = note.isEmpty
        ? _t('Ayah bookmarked', 'আয়াত বুকমার্ক করা হয়েছে')
        : _t('Bookmark note saved', 'বুকমার্ক নোট সেভ হয়েছে');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    noteController.dispose();
  }
}
