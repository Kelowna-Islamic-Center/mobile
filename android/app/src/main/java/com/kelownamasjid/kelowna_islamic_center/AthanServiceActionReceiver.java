package com.kelownamasjid.kelowna_islamic_center;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class AthanServiceActionReceiver extends BroadcastReceiver {
  public static final String ACTION_STOP_ATHAN = "com.kelownamasjid.kelowna_islamic_center.action.STOP_ATHAN";

  @Override
  public void onReceive(Context context, Intent intent) {
    if (intent == null || !ACTION_STOP_ATHAN.equals(intent.getAction())) {
      return;
    }

    context.stopService(new Intent(context, AthanAudioForegroundService.class));
  }
}
