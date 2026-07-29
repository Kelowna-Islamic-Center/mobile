package com.kelownamasjid.kelowna_islamic_center;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class AthanAlarmReceiver extends BroadcastReceiver {
  @Override
  public void onReceive(Context context, Intent intent) {
    int id = intent.getIntExtra(AthanAlarmScheduler.EXTRA_ALARM_ID, Math.abs((int) System.currentTimeMillis()));
    String title = intent.getStringExtra(AthanAlarmScheduler.EXTRA_TITLE);
    String body = intent.getStringExtra(AthanAlarmScheduler.EXTRA_BODY);
    String soundRes = intent.getStringExtra(AthanAlarmScheduler.EXTRA_SOUND_RES);

    AthanAlarmScheduler.markFired(context, id);

    AthanAlarmScheduler.startAthanAudioNow(
      context,
      id,
      title == null ? "Athan Reminder" : title,
      body == null ? "Prayer time" : body,
      soundRes == null ? "athan_default" : soundRes
    );
  }
}
