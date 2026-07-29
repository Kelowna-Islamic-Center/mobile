package com.kelownamasjid.kelowna_islamic_center;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class AthanServiceActionReceiver extends BroadcastReceiver {
  public static final String ACTION_STOP_ATHAN = "com.kelownamasjid.kelowna_islamic_center.action.STOP_ATHAN";
  public static final String ACTION_DISMISS_ATHAN = "com.kelownamasjid.kelowna_islamic_center.action.DISMISS_ATHAN";

  @Override
  public void onReceive(Context context, Intent intent) {
    if (intent == null) {
      return;
    }

    String action = intent.getAction();
    if (!ACTION_STOP_ATHAN.equals(action) && !ACTION_DISMISS_ATHAN.equals(action)) {
      return;
    }

    context.stopService(new Intent(context, AthanAudioForegroundService.class));
  }
}
