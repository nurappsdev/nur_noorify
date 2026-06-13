part of '../screens/surah_detail_screen.dart';

/// The bottom audio player card: title, reciter selector, seek bar and controls.
mixin SurahDetailAudioCardMixin
    on
        State<SurahDetailScreen>,
        SurahDetailStateMixin,
        SurahDetailViewCardsMixin,
        SurahDetailSingleAyahMixin,
        SurahDetailAudioControlsMixin {
  Widget _buildReciterSelector(QuranSurahDetail detail) {
    final hasReciters = detail.audioByReciter.isNotEmpty;
    if (!hasReciters) {
      return Text(
        'No audio source found for this Surah.',
        style: TextStyle(
          color: _isDarkTheme
              ? const Color(0xFFDEA1A1)
              : const Color(0xFF8F4343),
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Reciter',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: _glassBorder),
        ),
        labelStyle: TextStyle(
          color: _screenTextMuted,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 4.h,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          dropdownColor: _isDarkTheme
              ? const Color(0xFF10242B)
              : Colors.white,
          style: TextStyle(
            color: _screenTextPrimary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
          value: _selectedReciter?.id,
          items: detail.audioByReciter
              .map(
                (reciter) => DropdownMenuItem<int>(
                  value: reciter.id,
                  child: Text(
                    reciter.reciter,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: _onReciterChanged,
        ),
      ),
    );
  }

  Widget _buildAudioCard(QuranSurahDetail detail) {
    final reciter = _selectedReciter;
    final hasReciters = detail.audioByReciter.isNotEmpty;
    final playbackUrl = reciter == null ? null : _playbackUrlFor(reciter);
    final isCached =
        playbackUrl != null && _cachedAudioUrls.contains(playbackUrl);
    final hasExactTiming =
        _timingSegments.isNotEmpty &&
        _timingAudioUrl != null &&
        _timingRecitationId != null;

    final durationMs = _duration.inMilliseconds;
    final maxMs = durationMs > 0 ? durationMs : 1;
    final currentMs = _position.inMilliseconds.clamp(0, maxMs);

    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
        child: _buildGlassPanel(
          borderRadius: BorderRadius.all(Radius.circular(28.r)),
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${detail.surahName} - ${_toBanglaDigits(detail.surahNo.toString())}',
                      style: TextStyle(
                        color: _screenTextPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hide player',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _showBottomPlayer = false),
                    icon: Icon(Icons.close_rounded, color: _screenTextMuted),
                  ),
                ],
              ),
              if (_usingCachedContent) ...[
                SizedBox(height: 2.h),
                Text(
                  'Offline saved content',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: _screenTextMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              SizedBox(height: 6.h),
              _buildReciterSelector(detail),
              SizedBox(height: 8.h),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  activeTrackColor: _accent,
                  inactiveTrackColor: _isDarkTheme
                      ? const Color(0x334A7D72)
                      : const Color(0xFFAED2C8),
                  thumbColor: _accent,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                ),
                child: Slider(
                  value: currentMs.toDouble(),
                  min: 0,
                  max: maxMs.toDouble(),
                  onChanged: durationMs > 0
                      ? (value) =>
                            _player.seek(Duration(milliseconds: value.round()))
                      : null,
                ),
              ),
              Row(
                children: [
                  Text(
                    _formatDuration(_position),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: _screenTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDuration(_duration),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: _screenTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                hasExactTiming
                    ? 'Exact ayah timing sync enabled'
                    : 'Approximate sync for this reciter',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: _screenTextMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              _buildAudioControls(hasReciters: hasReciters, isCached: isCached),
            ],
          ),
        ),
      ),
    );
  }
}
