package com.kelownamasjid.kelowna_islamic_center;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;

/**
 * Marks prayer schedules as dirty after system events that can break exact timing for iqamaah and athan alerts.
 * Dart checks this flag and runs the notification reconcile function on startup/resume within the prayer_alert_scheduler_service.
 */
public class PrayerAlertReconcileReceiver extends BroadcastReceiver {
  private static final String FLUTTER_PREFS = "FlutterSharedPreferences";
  private static final String DIRTY_KEY = "flutter.prayerAlertNativeDirty";

  @Override
  public void onReceive(Context context, Intent intent) {
    SharedPreferences prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE);
    prefs.edit().putBoolean(DIRTY_KEY, true).apply();
  }
}
