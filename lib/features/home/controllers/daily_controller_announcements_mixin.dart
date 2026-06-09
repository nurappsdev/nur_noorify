part of '../screens/daily_activity_screen.dart';

mixin DailyControllerAnnouncementsMixin on State<DailyActivityScreen>, DailyControllerLoadersMixin {
  Future<void> _showAnnouncementModalIfNeeded() async {
    if (_announcementModalChecked || _announcementModalFetchInProgress) return;
    if (Firebase.apps.isEmpty) {
      _announcementModalChecked = true;
      return;
    }
    final hasInternet = await NetworkUtils.hasInternet();
    if (!hasInternet) {
      _announcementModalChecked = true;
      return;
    }
    _announcementModalFetchInProgress = true;
    try {
      final announcement = await AnnouncementService.instance
          .fetchLatestActiveModalAnnouncement();
      if (!mounted) return;
      if (!_isCurrentRouteActive()) return;
      _announcementModalChecked = true;
      if (announcement == null) return;
      if (DailyControllerStateMixin._lastShownAnnouncementId ==
          announcement.id) {
        return;
      }
      DailyControllerStateMixin._lastShownAnnouncementId = announcement.id;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_isCurrentRouteActive()) return;
        _openAnnouncementDialog(announcement);
      });
    } catch (e) {
      debugPrint('Announcement modal loading failed: $e');
    } finally {
      _announcementModalFetchInProgress = false;
    }
  }

  void _openAnnouncementDialog(AnnouncementItem item) {
    if (!_isCurrentRouteActive()) return;
    final title = item.localizedTitle(_isBangla);
    final message = item.localizedMessage(_isBangla);
    final posterUrl = item.posterUrl?.trim();
    final hasPoster = _isNetworkImageUrl(posterUrl);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            title.isEmpty
                ? (_isBangla
                      ? '\u0997\u09c1\u09b0\u09c1\u09a4\u09cd\u09ac\u09aa\u09c2\u09b0\u09cd\u09a3 \u0998\u09cb\u09b7\u09a3\u09be'
                      : 'Important Announcement')
                : title,
          ),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasPoster) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        posterUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    message.isEmpty
                        ? (_isBangla
                              ? '\u09a8\u09a4\u09c1\u09a8 \u0986\u09aa\u09a1\u09c7\u099f \u09aa\u09c7\u09a4\u09c7 \u0986\u09ae\u09be\u09a6\u09c7\u09b0 \u09b8\u09be\u09a5\u09c7 \u09a5\u09be\u0995\u09c1\u09a8\u0964'
                              : 'Stay connected for the latest app update.')
                        : message,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                _isBangla
                    ? '\u09ac\u09a8\u09cd\u09a7 \u0995\u09b0\u09c1\u09a8'
                    : 'Close',
              ),
            ),
          ],
        );
      },
    );
  }

}
