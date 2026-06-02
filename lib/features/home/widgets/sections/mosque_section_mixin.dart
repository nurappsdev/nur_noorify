part of '../../screens/daily_activity_screen.dart';

/// The "Nearby Mosques" preview card, backed by the cached Find Mosque results.
mixin DailyMosqueSectionMixin
    on
        State<DailyActivityScreen>,
        DailyActivityControllerMixin,
        DailyActivityViewBaseMixin {
  String _localizedDistance(double km) {
    final raw = km.toStringAsFixed(1);
    return _isBangla ? '${_toBanglaDigits(raw)} km' : '$raw km';
  }

  Widget _buildMosquePreviewCard() {
    final items = _nearbyMosquePreview.take(3).toList(growable: false);
    final hasData = items.isNotEmpty;

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _text('Nearby Mosques', 'নিকটবর্তী মসজিদ'),
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _openFindMosque,
                style: TextButton.styleFrom(
                  foregroundColor: _accentStrong,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(_text('View all', 'সব দেখুন')),
              ),
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _openFindMosque,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              constraints: const BoxConstraints(minHeight: 132),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: _isDarkTheme
                      ? const [Color(0xFF1A3045), Color(0xFF142435)]
                      : const [Color(0xFFF6FBFF), Color(0xFFE6F1F8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _isDarkTheme
                      ? const Color(0x334F7590)
                      : const Color(0xFFCFDFEA),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  children: [
                    if (hasData) ...[
                      for (final item in items) ...[
                        _buildMosquePreviewPill(
                          name: item.name,
                          distance: _localizedDistance(item.distanceKm),
                        ),
                        if (item != items.last) const SizedBox(height: 8),
                      ],
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 10, 4, 14),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_searching_rounded,
                              size: 18,
                              color: _textWeak,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _text(
                                  'Tap to sync your nearest mosque list',
                                  'নিকটবর্তী মসজিদের তালিকা সিঙ্ক করতে ট্যাপ করুন',
                                ),
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _accentStrong,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _text(
                            hasData ? 'Updated list' : 'Find Mosque',
                            hasData ? 'আপডেটেড তালিকা' : 'মসজিদ খুঁজুন',
                          ),
                          style: TextStyle(
                            color: _isDarkTheme
                                ? const Color(0xFF042A31)
                                : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_nearbyMosquePreviewUpdatedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              _text(
                'Last synced from Find Mosque',
                'Find Mosque থেকে সর্বশেষ সিঙ্ক',
              ),
              style: TextStyle(
                color: _textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMosquePreviewPill({
    required String name,
    required String distance,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _isDarkTheme ? const Color(0xB2122231) : const Color(0xEFFFFFFF),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: _isDarkTheme
              ? const Color(0x334F7590)
              : const Color(0xFFD1E1EC),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.location_city_rounded, size: 16, color: _textWeak),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            distance,
            style: TextStyle(
              color: _accentStrong,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
