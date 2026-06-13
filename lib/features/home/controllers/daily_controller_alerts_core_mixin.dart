part of '../screens/daily_activity_screen.dart';

mixin DailyControllerAlertsCoreMixin on State<DailyActivityScreen>, DailyControllerScheduleDataMixin {
  Future<void> _scheduleMealNotification({
    required int id,
    required String channelId,
    required String channelName,
    required String channelDescription,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (!localNotificationsInitialized) return;
    _ensureTimezoneInitializedForScheduling();
    var scheduled = tz.TZDateTime.from(at, tz.local);
    final nowTz = tz.TZDateTime.now(tz.local);
    if (scheduled.isBefore(nowTz)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final tone = alertToneNotifier.value;
    NotificationDetails detailsForTone(AppAlertTone value) {
      final valuePlaySound = alertTonePlaySound(value);
      return NotificationDetails(
        android: AndroidNotificationDetails(
          channelIdForTone(channelId, tone: value),
          channelName,
          channelDescription: '$channelDescription (${alertToneLabel(value)})',
          importance: Importance.max,
          priority: Priority.high,
          playSound: valuePlaySound,
          sound: alertToneSound(value),
          audioAttributesUsage: alertToneUsage(value),
        ),
        iOS: DarwinNotificationDetails(presentSound: valuePlaySound),
      );
    }

    Future<void> scheduleWithDetails(
      NotificationDetails details, {
      required AndroidScheduleMode mode,
    }) async {
      await localNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: mode,
        payload: payload,
      );
    }

    final details = detailsForTone(tone);

    try {
      await scheduleWithDetails(
        details,
        mode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException catch (e) {
      // Android 13/14 may block exact alarms unless special permission is granted.
      if (e.code == 'exact_alarms_not_permitted') {
        await scheduleWithDetails(
          details,
          mode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } else if (tone == AppAlertTone.adhan) {
        // If raw adhan sound is missing/invalid, fallback to default tone.
        final fallback = detailsForTone(AppAlertTone.appDefault);
        try {
          await scheduleWithDetails(
            fallback,
            mode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } on PlatformException catch (fallbackError) {
          if (fallbackError.code == 'exact_alarms_not_permitted') {
            await scheduleWithDetails(
              fallback,
              mode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
          } else {
            rethrow;
          }
        }
      } else {
        rethrow;
      }
    }
  }

  void _ensureTimezoneInitializedForScheduling() {
    try {
      // Accessing tz.local throws if local location was never configured.
      tz.local;
    } catch (_) {
      try {
        tz_data.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {
        // Keep scheduling flow from crashing even in test environments.
      }
    }
  }

}
