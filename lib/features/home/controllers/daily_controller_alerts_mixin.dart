part of '../screens/daily_activity_screen.dart';

mixin DailyControllerAlertsMixin on State<DailyActivityScreen>, DailyControllerAlertsCoreMixin {
  Future<void> _scheduleSehriNotification(DateTime sehriTime) async {
    if (!sehriAlertEnabledNotifier.value) return;
    await _scheduleMealNotification(
      id: sehriNotificationId,
      channelId: 'sehri_alert_channel',
      channelName: 'Sehri Alerts',
      channelDescription: 'Alert when Sehri time starts',
      at: sehriTime,
      title: _localizedSehriAlertTitle(),
      body: _localizedSehriAlertBody(),
      payload: 'sehri',
    );
  }

  Future<void> _schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime at,
  }) async {
    if (!prayerAlertsEnabledNotifier.value) return;
    await _scheduleMealNotification(
      id: id,
      channelId: 'prayer_alert_channel',
      channelName: 'Prayer Alerts',
      channelDescription: 'Alert when prayer time starts',
      at: at,
      title: '$prayerName Prayer Alert',
      body: 'It is time for $prayerName prayer.',
      payload: 'prayer_${prayerName.toLowerCase()}',
    );
  }

  Future<void> _cancelPrayerNotifications() async {
    if (!localNotificationsInitialized) return;
    await localNotificationsPlugin.cancel(fajrNotificationId);
    await localNotificationsPlugin.cancel(dzuhrNotificationId);
    await localNotificationsPlugin.cancel(ashrNotificationId);
    await localNotificationsPlugin.cancel(maghribNotificationId);
    await localNotificationsPlugin.cancel(ishaNotificationId);
  }

  Future<void> _refreshPrayerAlertScheduling() async {
    try {
      if (!prayerAlertsEnabledNotifier.value) {
        await _cancelPrayerNotifications();
        return;
      }

      final schedule = _todaySchedule;
      if (schedule == null) return;

      await _schedulePrayerNotification(
        id: fajrNotificationId,
        prayerName: 'Fajr',
        at: schedule.fajr,
      );
      await _schedulePrayerNotification(
        id: dzuhrNotificationId,
        prayerName: 'Zuhr',
        at: schedule.dzuhr,
      );
      await _schedulePrayerNotification(
        id: ashrNotificationId,
        prayerName: 'Asr',
        at: schedule.ashr,
      );
      await _schedulePrayerNotification(
        id: maghribNotificationId,
        prayerName: 'Maghrib',
        at: schedule.maghrib,
      );
      await _schedulePrayerNotification(
        id: ishaNotificationId,
        prayerName: 'Isha',
        at: schedule.isha,
      );
    } catch (e) {
      debugPrint('Prayer alert scheduling failed: $e');
    }
  }

  Future<void> _scheduleIftarNotification(DateTime iftarTime) async {
    if (!iftarAlertEnabledNotifier.value) return;
    await _scheduleMealNotification(
      id: iftarNotificationId,
      channelId: 'iftar_alert_channel',
      channelName: 'Iftar Alerts',
      channelDescription: 'Alert when Iftar time starts',
      at: iftarTime,
      title: _localizedIftarAlertTitle(),
      body: _localizedIftarAlertBody(),
      payload: 'iftar',
    );
  }

  Future<void> _cancelSehriNotification() async {
    if (!localNotificationsInitialized) return;
    await localNotificationsPlugin.cancel(sehriNotificationId);
  }

  Future<void> _cancelIftarNotification() async {
    if (!localNotificationsInitialized) return;
    await localNotificationsPlugin.cancel(iftarNotificationId);
  }

  Future<void> _refreshMealAlertScheduling() async {
    try {
      if (_nextSehriAt != null) {
        if (sehriAlertEnabledNotifier.value) {
          await _scheduleSehriNotification(_nextSehriAt!);
        } else {
          await _cancelSehriNotification();
        }
      }

      if (_nextIftarAt != null) {
        if (iftarAlertEnabledNotifier.value) {
          await _scheduleIftarNotification(_nextIftarAt!);
        } else {
          await _cancelIftarNotification();
        }
      }
    } catch (e) {
      debugPrint('Meal alert scheduling failed: $e');
    }
  }

  Future<void> _scheduleTahajjudNotification(DateTime tahajjudTime) async {
    if (!tahajjudAlertEnabledNotifier.value) return;
    await _scheduleMealNotification(
      id: tahajjudNotificationId,
      channelId: 'tahajjud_alert_channel',
      channelName: 'Tahajjud Reminders',
      channelDescription: 'Reminder for the last third of the night',
      at: tahajjudTime,
      title: _localizedTahajjudAlertTitle(),
      body: _localizedTahajjudAlertBody(),
      payload: 'tahajjud',
    );
  }

  Future<void> _cancelTahajjudNotification() async {
    if (!localNotificationsInitialized) return;
    await localNotificationsPlugin.cancel(tahajjudNotificationId);
  }

  Future<void> _refreshTahajjudAlertScheduling() async {
    try {
      final at = _nextTahajjudTimeForSchedule();
      if (at == null) return;
      if (tahajjudAlertEnabledNotifier.value) {
        await _scheduleTahajjudNotification(at);
      } else {
        await _cancelTahajjudNotification();
      }
    } catch (e) {
      debugPrint('Tahajjud alert scheduling failed: $e');
    }
  }

}
