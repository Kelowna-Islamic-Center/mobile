package com.kelownamasjid.kelowna_islamic_center;

import android.app.Notification;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.media.MediaPlayer;
import android.os.IBinder;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

public class AthanService extends Service {

    private MediaPlayer player;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && "STOP_ATHAN".equals(intent.getAction())) {
            stopAthan();
            stopSelf();
            return START_NOT_STICKY;
        }

        String channelId = intent != null ? intent.getStringExtra("channelId") : null;
        String title = intent != null ? intent.getStringExtra("title") : null;
        String body = intent != null ? intent.getStringExtra("body") : null;

        if (channelId == null) channelId = "athan_channel";
        if (title == null) title = "Prayer Time";
        if (body == null) body = "Playing Athan";

        // Intent to launch Flutter MainActivity when notification is pressed
        Intent launchIntent = new Intent(this, MainActivity.class);
        launchIntent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);

        PendingIntent contentPendingIntent = PendingIntent.getActivity(
                this,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );

        // Intent that fires when the notification is dismissed
        Intent stopIntent = new Intent(this, AthanService.class);
        stopIntent.setAction("STOP_ATHAN");

        PendingIntent deletePendingIntent = PendingIntent.getService(
                this,
                1,
                stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );

        // Notification with press + dismiss actions
        Notification notification = new NotificationCompat.Builder(this, channelId)
                .setContentTitle(title)
                .setContentText(body)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setOngoing(true)
                .setContentIntent(contentPendingIntent) // opens app when pressed
                .setDeleteIntent(deletePendingIntent)   // stops Athan when dismissed
                .build();

        startForeground(1, notification);

        // Play Athan audio from res/raw
        player = MediaPlayer.create(this, R.raw.athan_full);
        if (player != null) {
            player.setOnCompletionListener(mp -> stopSelf());
            player.start();
        }

        return START_NOT_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        stopAthan();
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private void stopAthan() {
        if (player != null) {
            if (player.isPlaying()) {
                player.stop();
            }
            player.release();
            player = null;
        }
    }
}
