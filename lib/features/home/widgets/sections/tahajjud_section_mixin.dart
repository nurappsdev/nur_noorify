part of '../../screens/daily_activity_screen.dart';

/// The Tahajjud reminder card shown during the last third of the night, with
/// its dedicated moonlight palette and the remind-me toggle.
mixin DailyTahajjudSectionMixin
    on
        State<DailyActivityScreen>,
        DailyActivityControllerMixin,
        DailyActivityViewBaseMixin {
  // Moonlight palette for the nighttime section, independent of the app theme
  // so the night vibe reads the same in light and dark mode.
  static const Color _moonInk = Color(0xFFCFE0FF);
  static const Color _moonInkSoft = Color(0xFF9FB6E0);
  static const Color _moonGlow = Color(0xFFBFD2FF);
  static const Color _moonGold = Color(0xFFE9D8A6);

  Widget _buildTahajjudReminderCard() {
    final tahajjudClock = _skyClock(_tahajjudTime());
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF1B1142), Color(0xFF23215C), Color(0xFF15244F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0x55B79CF0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55382C7A),
              blurRadius: 26,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            // A few static stars for the distinct night vibe.
            const Positioned(
              top: 12,
              right: 22,
              child: Icon(Icons.star_rounded, size: 9, color: Color(0x88FFFFFF)),
            ),
            const Positioned(
              top: 30,
              right: 48,
              child: Icon(Icons.star_rounded, size: 6, color: Color(0x66FFFFFF)),
            ),
            const Positioned(
              bottom: 18,
              right: 16,
              child: Icon(Icons.star_rounded, size: 7, color: Color(0x55FFFFFF)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFE9D8A6), Color(0xFFC9A24B)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x88E9D8A6),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.nightlight_round,
                          size: 18,
                          color: Color(0xFF231A04),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _text('Tahajjud Reminder', 'তাহাজ্জুদের আহ্বান'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _moonInk,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'التهجد',
                                  style: TextStyle(
                                    color: _moonGold,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _text(
                                'Last third of the night',
                                'রাতের শেষ তৃতীয়াংশ',
                              ),
                              style: const TextStyle(
                                color: _moonInkSoft,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Text(
                    _text(
                      '“Our Lord descends to the lowest heaven in the last third of the night…” — stand, pray, and ask.',
                      '“আমাদের রব রাতের শেষ তৃতীয়াংশে নিকটবর্তী আকাশে অবতরণ করেন…” — উঠুন, নামাজ পড়ুন ও দোয়া করুন।',
                    ),
                    style: const TextStyle(
                      color: _moonInk,
                      fontSize: 12,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: _moonGlow,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _text('Recommended', 'প্রস্তাবিত'),
                        style: const TextStyle(
                          color: _moonInkSoft,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tahajjudClock,
                        style: const TextStyle(
                          color: _moonInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      _buildTahajjudReminderToggle(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTahajjudReminderToggle() {
    return ValueListenableBuilder<bool>(
      valueListenable: tahajjudAlertEnabledNotifier,
      builder: (context, enabled, _) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              tahajjudAlertEnabledNotifier.value = !enabled;
              unawaited(saveAppPreferences());
            },
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: enabled
                    ? const LinearGradient(
                        colors: [Color(0xFFE9D8A6), Color(0xFFC9A24B)],
                      )
                    : null,
                color: enabled ? null : const Color(0x332C3C72),
                border: Border.all(
                  color: enabled
                      ? const Color(0x00000000)
                      : const Color(0x66B79CF0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    enabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    size: 14,
                    color: enabled ? const Color(0xFF231A04) : _moonInk,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    enabled
                        ? _text('On', 'চালু')
                        : _text('Remind me', 'মনে করিয়ে দিন'),
                    style: TextStyle(
                      color: enabled ? const Color(0xFF231A04) : _moonInk,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
