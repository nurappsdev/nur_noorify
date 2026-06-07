part of '../screens/surah_detail_screen.dart';

/// The play / stop / offline-download button row of the bottom audio player.
mixin SurahDetailAudioControlsMixin
    on
        State<SurahDetailScreen>,
        SurahDetailStateMixin,
        SurahDetailAudioMixin,
        SurahDetailSingleAyahMixin {
  Widget _buildAudioControls({
    required bool hasReciters,
    required bool isCached,
  }) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: hasReciters && !_isPreparingAudio
                ? _togglePlayPause
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: _isDarkTheme
                  ? const Color(0xFF082736)
                  : Colors.white,
            ),
            icon: _isPreparingAudio
                ? SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
            label: Text(_isPlaying ? 'Pause' : 'Play'),
          ),
        ),
        SizedBox(width: 8.w),
        OutlinedButton.icon(
          onPressed: _isPlaying || _position > Duration.zero
              ? _stopAudio
              : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: _screenTextPrimary,
            side: BorderSide(color: _glassBorder),
          ),
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Stop'),
        ),
        SizedBox(width: 8.w),
        FilledButton.tonalIcon(
          onPressed: hasReciters && !_isDownloadingAudio
              ? _downloadSelectedAudio
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: _isDarkTheme
                ? const Color(0xFF16353C)
                : const Color(0xFFDAEFF5),
            foregroundColor: _screenTextPrimary,
          ),
          icon: _isDownloadingAudio
              ? SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isCached
                      ? Icons.download_done_rounded
                      : Icons.download_rounded,
                ),
          label: Text(isCached ? 'Saved' : 'Offline'),
        ),
      ],
    );
  }
}
