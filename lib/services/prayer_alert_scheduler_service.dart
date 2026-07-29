import "dart:convert";
import "dart:io";
import "dart:ui";

import "package:flutter_timezone/flutter_timezone.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:flutter/services.dart";
import "package:intl/intl.dart";
import "package:kelowna_islamic_center/config.dart";
import "package:kelowna_islamic_center/l10n/app_localizations.dart";
import "package:kelowna_islamic_center/services/athan_alarm_service.dart";
import "package:kelowna_islamic_center/structs/prayer_item.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:timezone/data/latest.dart" as tz;
import "package:timezone/timezone.dart" as tz;
import "package:workmanager/workmanager.dart";

class PrayerAlertSchedulerService {
  static const String taskUniqueName = "prayerAlertSchedulerTaskV2";
  static const String managedIdsKey = "scheduledPrayerAlertIdsV2";
  static const String nativeDirtyKey = "prayerAlertNativeDirty";
  // Key for native Android Athan scheduling state. If true, the app will not schedule prayer alerts in the background to avoid dual scheduling.
  static const String nativeAthanActiveKey = "nativeAthanSchedulingActive"; 
  // Fingerprint of the last scheduled prayer alerts. If this fingerprint changes, the app will reschedule prayer alerts. 
  // Ensures that user changes that affect prayer alerts (e.g. language, iqamah offset, etc.) are reflected in the scheduled notifications.
  static const String scheduleFingerprintKey = "scheduledPrayerAlertFingerprintV2";

  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  static Future<void> initBackgroundService() async {
    await Workmanager().registerPeriodicTask(
      taskUniqueName,
      taskUniqueName,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(seconds: 30),
    );
  }

  // Reschedules prayer alerts based on the current prayer times and user preferences.
  static Future<void> reconcileSchedules({ bool force = false, bool fromBackground = false }) async {
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await _initNotifications();

    bool athanEnabled = prefs.getBool("athanTimeAlert") ?? true;
    bool iqamahEnabled = prefs.getBool("iqamahTimeAlert") ?? true;
    int iqamahOffsetMinutes = prefs.getInt("iqamahTimeAlertTime") ?? 15;

    String athanAudio = prefs.getString("athanAudio") ?? "athan_default";
    bool useNativeAthanOnAndroid = Platform.isAndroid && await AthanAlarmService.isAvailable();
    bool nativeAthanWasActive = prefs.getBool(nativeAthanActiveKey) ?? false;

    // Workmanager runs in a background isolate where custom Activity channels may not be attached.
    // When native Athan scheduling is already active, skip background reconcile to avoid dual scheduling.
    if (fromBackground && Platform.isAndroid && nativeAthanWasActive && !useNativeAthanOnAndroid) {
      return;
    }

    List<PrayerItem> todayItems = _readPrayerItemsFromPrefs(prefs, key: "prayerTimes");
    List<PrayerItem> nextDayItems = _readPrayerItemsFromPrefs(prefs, key: "prayerTimesNextDay");

    if (todayItems.isEmpty && nextDayItems.isEmpty) {
      await _cancelManagedNotifications(prefs);
      return;
    }

    // Localization so notification follow user language preference.
    String localeCode = prefs.getString("locale") ?? PlatformDispatcher.instance.locale.languageCode;
    String fingerprint = _buildScheduleFingerprint(
      localeCode: localeCode,
      athanEnabled: athanEnabled,
      iqamahEnabled: iqamahEnabled,
      iqamahOffsetMinutes: iqamahOffsetMinutes,
      athanAudio: athanAudio,
      todayItems: todayItems,
      nextDayItems: nextDayItems,
    );

    List<PendingNotificationRequest> pendingRequests = await _notifications.pendingNotificationRequests();
    
    bool hasManagedPending = pendingRequests.any((request) => request.payload?.startsWith("prayer_alert_v2:") ?? false,);
    bool hasNativeAthanPending = useNativeAthanOnAndroid && await AthanAlarmService.hasScheduledAthanAlarm();

    // If not forced and not from background, and there is not change in user preferences, skip rescheduling.
    if (!force && !fromBackground && prefs.getString(scheduleFingerprintKey) == fingerprint) {
      return;
    }

    // If not forced but from background, and there is not change in user preferences, skip rescheduling.
    if (!force && fromBackground && (hasManagedPending || hasNativeAthanPending) && prefs.getString(scheduleFingerprintKey) == fingerprint) {
      return;
    }

    await _cancelManagedNotifications(prefs);

    AppLocalizations l10n = await AppLocalizations.delegate.load(Locale(localeCode));
    DateTime now = DateTime.now();

    await _schedulePrayerDay(
      date: now,
      prayerItems: todayItems,
      athanEnabled: athanEnabled,
      iqamahEnabled: iqamahEnabled,
      iqamahOffsetMinutes: iqamahOffsetMinutes,
      athanAudio: athanAudio,
      useNativeAthanOnAndroid: useNativeAthanOnAndroid,
      l10n: l10n,
      append: true,
    );

    if (nextDayItems.isNotEmpty) {
      await _schedulePrayerDay(
        date: now.add(const Duration(days: 1)),
        prayerItems: nextDayItems,
        athanEnabled: athanEnabled,
        iqamahEnabled: iqamahEnabled,
        iqamahOffsetMinutes: iqamahOffsetMinutes,
        athanAudio: athanAudio,
        useNativeAthanOnAndroid: useNativeAthanOnAndroid,
        l10n: l10n,
        append: true,
      );
    }

    // Re-read managed ids generated by _schedulePrayerDay and persist a schedule fingerprint.
    List<String> managedIds = prefs.getStringList(managedIdsKey) ?? <String>[];
    await prefs.setStringList(managedIdsKey, managedIds);
    await prefs.setString(scheduleFingerprintKey, fingerprint);

    if (Platform.isAndroid) {
      await prefs.setBool(nativeAthanActiveKey, useNativeAthanOnAndroid && athanEnabled);
    }
  }

  // If the native side of the app has been marked as dirty, this method will reconcile the schedules and reset the dirty flag.
  static Future<void> reconcileIfNativeDirty() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool nativeDirty = prefs.getBool(nativeDirtyKey) ?? false;
    if (!nativeDirty) {
      return;
    }

    await prefs.setBool(nativeDirtyKey, false);
    await reconcileSchedules(force: true);
  }

  static Future<void> _schedulePrayerDay({
    required DateTime date,
    required List<PrayerItem> prayerItems,
    required bool athanEnabled,
    required bool iqamahEnabled,
    required int iqamahOffsetMinutes,
    required String athanAudio,
    required bool useNativeAthanOnAndroid,
    required AppLocalizations l10n,
    required bool append
  }) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();
    List<int> managedIds = <int>[];

    for (PrayerItem prayerItem in prayerItems) {
      if (prayerItem.id.toLowerCase() == "shurooq") {
        continue;
      }

      if (prayerItem.id.toLowerCase() == "jumuah" && date.weekday != DateTime.friday) {
        continue;
      }

      if (prayerItem.id.toLowerCase() == "duhr" && date.weekday == DateTime.friday) {
        continue;
      }

      if (athanEnabled) {
        DateTime? athanTime = _parsePrayerTimeForDate(prayerItem.startTime, date);

        if (athanTime != null && athanTime.isAfter(now)) {

          int athanId = _notificationId(date: date, prayerId: prayerItem.id, kind: "athan");

          String title = "${l10n.athanReminder}: ${_localizedPrayerName(l10n, prayerItem.id)}";
          String body = _localizedPrayerName(l10n, prayerItem.id);

          if (Platform.isAndroid && useNativeAthanOnAndroid) {
            // Try to use the native implementation of Athan scheduling for Android.
            try {
              await AthanAlarmService.scheduleAthanAlarm(
                id: athanId,
                triggerAt: athanTime,
                title: title,
                body: body,
                soundResName: athanAudio,
              );
            // Default notification if it fails, this usually doesn't play audio
            } on MissingPluginException {
              await _scheduleAthanNotificationFallback(
                athanId: athanId,
                athanTime: athanTime,
                athanAudio: athanAudio,
                title: title,
                body: body,
              );
            } on PlatformException {
              await _scheduleAthanNotificationFallback(
                athanId: athanId,
                athanTime: athanTime,
                athanAudio: athanAudio,
                title: title,
                body: body,
              );
            }
          // For iOS, use just notification scheduling
          } else {
            await _scheduleAthanNotificationFallback(
              athanId: athanId,
              athanTime: athanTime,
              athanAudio: athanAudio,
              title: title,
              body: body,
            );
          }

          managedIds.add(athanId);
        }
      }

      if (iqamahEnabled) {
        DateTime? iqamahTime = _parsePrayerTimeForDate(prayerItem.iqamahTime, date);

        if (iqamahTime != null) {
          DateTime reminderTime = iqamahTime.subtract(Duration(minutes: iqamahOffsetMinutes));
          
          if (reminderTime.isAfter(now)) {

            int iqamahId = _notificationId(date: date, prayerId: prayerItem.id, kind: "iqamah");

            await _notifications.zonedSchedule(
              id: iqamahId,
              title: "${l10n.iqamaahReminder}: ${_localizedPrayerName(l10n, prayerItem.id)}",
              body: "${l10n.minutes(iqamahOffsetMinutes.toString())} • ${_localizedPrayerName(l10n, prayerItem.id)}",
              scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
              notificationDetails: NotificationDetails(
                android: AndroidNotificationDetails(
                  Config.iqamahAlertChannel.id,
                  Config.iqamahAlertChannel.name,
                  channelDescription: Config.iqamahAlertChannel.description,
                  importance: Importance.high,
                  priority: Priority.high,
                  category: AndroidNotificationCategory.reminder,
                ),
                iOS: const DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                  interruptionLevel: InterruptionLevel.timeSensitive,
                ),
              ),
              payload: "prayer_alert_v2:iqamah:$iqamahId",
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            );

            managedIds.add(iqamahId);
          }
        }
      }
    }

    if (append) {
      List<String> current = prefs.getStringList(managedIdsKey) ?? <String>[];
      List<String> nextIds = <String>{...current, ...managedIds.map((id) => id.toString())}.toList();
      await prefs.setStringList(managedIdsKey, nextIds);
    }
  }

  // Cancels all managed notifications and clears the managed ids and schedule fingerprint from shared preferences. Just in case API fails.
  static Future<void> _cancelManagedNotifications(SharedPreferences prefs) async {
    List<String> managedIds = prefs.getStringList(managedIdsKey) ?? <String>[];
    List<int> parsedIds = <int>[];

    for (String idText in managedIds) {
      int? id = int.tryParse(idText);
      if (id != null) {
        parsedIds.add(id);
        await _notifications.cancel(id: id);
      }
    }

    if (Platform.isAndroid) {
      try {
        await AthanAlarmService.cancelAthanAlarms(parsedIds);
      } on MissingPluginException {
        // Ignore when native channel is unavailable.
      } on PlatformException {
        // Keep iqamah notification cancellations even if native alarm cancel fails.
      }
    }

    await prefs.setStringList(managedIdsKey, <String>[]);
    await prefs.remove(scheduleFingerprintKey);
    await prefs.setBool(nativeAthanActiveKey, false);
  }

  // Notification scheduling using notifications only used for athan when native android implementation doesn't work or if it's iOS
  static Future<void> _scheduleAthanNotificationFallback({
    required int athanId,
    required DateTime athanTime,
    required String athanAudio,
    required String title,
    required String body,
  }) async {
    String iosSoundFileName = "${athanAudio}_short.caf";

    await _notifications.zonedSchedule(
      id: athanId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(athanTime, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          Config.athanAlertChannel.id,
          Config.athanAlertChannel.name,
          channelDescription: Config.athanAlertChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          sound: RawResourceAndroidNotificationSound(athanAudio),
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: iosSoundFileName,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: "prayer_alert_v2:athan:$athanId",
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }


  static List<PrayerItem> _readPrayerItemsFromPrefs(SharedPreferences prefs, { required String key }) {
    List<String> raw = prefs.getStringList(key) ?? <String>[];
    List<PrayerItem> items = <PrayerItem>[];

    for (String row in raw) {
      try {
        Map<String, dynamic> decoded = jsonDecode(row);
        items.add(
          PrayerItem(
            id: decoded["id"],
            startTime: decoded["start"],
            iqamahTime: decoded["iqamah"],
          ),
        );
      } catch (_) {
        // Ignore broken prayer items and keep scheduling from last valid rows.
      }
    }

    return items;
  }

  static DateTime? _parsePrayerTimeForDate(String value, DateTime date) {
    if (value == "No Internet") {
      return null;
    }

    try {
      DateTime parsed = DateFormat("h:m a").parse(value);
      return DateTime(
        date.year,
        date.month,
        date.day,
        parsed.hour,
        parsed.minute,
      );
    } catch (_) {
      return null;
    }
  }

  static String _localizedPrayerName(AppLocalizations l10n, String prayerId) {
    switch (prayerId.toLowerCase()) {
      case "fajr":
        return l10n.fajr;
      case "shurooq":
        return l10n.shurooq;
      case "duhr":
        return l10n.duhr;
      case "asr":
        return l10n.asr;
      case "maghrib":
        return l10n.maghrib;
      case "isha":
        return l10n.isha;
      case "jumuah":
        return l10n.jumuah;
      default:
        return l10n.unknownPrayer;
    }
  }

  static int _notificationId({ required DateTime date, required String prayerId, required String kind }) {
    String token = "${date.year}-${date.month}-${date.day}-$prayerId-$kind-v2";
    return token.hashCode & 0x7fffffff;
  }

  static String _buildScheduleFingerprint({
    required String localeCode,
    required bool athanEnabled,
    required bool iqamahEnabled,
    required int iqamahOffsetMinutes,
    required String athanAudio,
    required List<PrayerItem> todayItems,
    required List<PrayerItem> nextDayItems,
  }) {
    String encode(List<PrayerItem> items) => items.map((item) => "${item.id}|${item.startTime}|${item.iqamahTime}").join(";");

    return [
      localeCode,
      athanEnabled,
      iqamahEnabled,
      iqamahOffsetMinutes,
      athanAudio,
      encode(todayItems),
      encode(nextDayItems),
    ].join("::");
  }

  // Initializes the notification plugin and sets the local timezone. Should only run once per app lifecycle.
  static Future<void> _initNotifications() async {
    if (_isInitialized) {
      return;
    }

    // ** Potential Change **: Use Kelowna time exclusively instead of local timezone
    tz.initializeTimeZones();
    try {
      TimezoneInfo timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      // Fall back to Kelowna timezone if local timezone resolution fails.
      tz.setLocalLocation(tz.getLocation("America/Vancouver"));
    }

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings("@mipmap/ic_launcher");
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();

    await _notifications.initialize(settings: const InitializationSettings(android: androidInit, iOS: iosInit));

    if (Platform.isAndroid) {
      AndroidFlutterLocalNotificationsPlugin? androidPlugin =_notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(Config.athanAlertChannel);
      await androidPlugin?.createNotificationChannel(Config.iqamahAlertChannel);
    }

    _isInitialized = true;
  }



  // Runs a user-facing preview: native Athan alarm on Android, notification fallback on iOS.
  static Future<void> triggerAthanNotificationPreview({
    required String title,
    required String body,
  }) async {
    await _initNotifications();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String athanAudio = prefs.getString("athanAudio") ?? "athan_default";

    if (Platform.isAndroid && await AthanAlarmService.isAvailable()) {
      await AthanAlarmService.triggerTestAthanNow(
        title: title,
        body: body,
        soundResName: athanAudio,
      );
      return;
    }

    int id = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    await _scheduleAthanNotificationFallback(
      athanId: id,
      athanTime: DateTime.now().add(const Duration(seconds: 1)),
      athanAudio: athanAudio,
      title: title,
      body: body,
    );
  }
}
