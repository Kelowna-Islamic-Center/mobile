package com.kelownamasjid.kelowna_islamic_center;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public final class AthanAlarmScheduler {
  public static final String EXTRA_ALARM_ID = "alarm_id";
  public static final String EXTRA_TITLE = "title";
  public static final String EXTRA_BODY = "body";
  public static final String EXTRA_SOUND_RES = "sound_res";

  private static final String PREFS = "athan_alarm_prefs";
  private static final String KEY_IDS = "scheduled_athan_ids";

  private AthanAlarmScheduler() {}

  public static void scheduleAthanAlarm(
    Context context,
    int id,
    long triggerAtMillis,
    String title,
    String body,
    String soundResName
  ) {
    AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
    if (alarmManager == null) {
      return;
    }

    PendingIntent pendingIntent = buildAlarmPendingIntent(context, id, title, body, soundResName);

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent);
    } else {
      alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent);
    }

    addScheduledId(context, id);
  }

  public static void cancelAthanAlarm(Context context, int id) {
    AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
    if (alarmManager != null) {
      PendingIntent pendingIntent = buildAlarmPendingIntent(context, id, "", "", "athan_default");
      alarmManager.cancel(pendingIntent);
      pendingIntent.cancel();
    }

    removeScheduledId(context, id);
  }

  public static void cancelAthanAlarms(Context context, List<Integer> ids) {
    if (ids == null || ids.isEmpty()) {
      ids = new ArrayList<>(readScheduledIds(context));
    }

    for (int id : ids) {
      cancelAthanAlarm(context, id);
    }
  }

  public static boolean hasScheduledAthanAlarm(Context context) {
    return !readScheduledIds(context).isEmpty();
  }

  public static void markFired(Context context, int id) {
    removeScheduledId(context, id);
  }

  public static void startAthanAudioNow(Context context, int id, String title, String body, String soundResName) {
    Intent serviceIntent = new Intent(context, AthanAudioForegroundService.class)
      .putExtra(EXTRA_ALARM_ID, id)
      .putExtra(EXTRA_TITLE, title)
      .putExtra(EXTRA_BODY, body)
      .putExtra(EXTRA_SOUND_RES, soundResName);

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      context.startForegroundService(serviceIntent);
    } else {
      context.startService(serviceIntent);
    }
  }

  private static PendingIntent buildAlarmPendingIntent(
    Context context,
    int id,
    String title,
    String body,
    String soundResName
  ) {
    Intent receiverIntent = new Intent(context, AthanAlarmReceiver.class)
      .putExtra(EXTRA_ALARM_ID, id)
      .putExtra(EXTRA_TITLE, title)
      .putExtra(EXTRA_BODY, body)
      .putExtra(EXTRA_SOUND_RES, soundResName);

    return PendingIntent.getBroadcast(
      context,
      id,
      receiverIntent,
      PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
    );
  }

  private static SharedPreferences prefs(Context context) {
    return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
  }

  private static Set<Integer> readScheduledIds(Context context) {
    Set<String> raw = prefs(context).getStringSet(KEY_IDS, new HashSet<>());
    Set<Integer> ids = new HashSet<>();

    for (String value : raw) {
      try {
        ids.add(Integer.parseInt(value));
      } catch (NumberFormatException ignored) {
      }
    }

    return ids;
  }

  private static void addScheduledId(Context context, int id) {
    Set<String> raw = new HashSet<>(prefs(context).getStringSet(KEY_IDS, new HashSet<>()));
    raw.add(String.valueOf(id));
    prefs(context).edit().putStringSet(KEY_IDS, raw).apply();
  }

  private static void removeScheduledId(Context context, int id) {
    Set<String> raw = new HashSet<>(prefs(context).getStringSet(KEY_IDS, new HashSet<>()));
    raw.remove(String.valueOf(id));
    prefs(context).edit().putStringSet(KEY_IDS, raw).apply();
  }
}
