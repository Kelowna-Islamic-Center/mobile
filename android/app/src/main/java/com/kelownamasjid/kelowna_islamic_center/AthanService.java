package com.kelownamasjid.kelowna_islamic_center;

import android.app.Notification;
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
        String channelId = intent.getStringExtra("channelId");
        String title = intent.getStringExtra("title");
        String text = intent.getStringExtra("text");

        if (channelId == null) channelId = "athan_channel";
        if (title == null) title = "Prayer Time";
        if (text == null) text = "Playing Athan";

        // Use existing notification channel; do not create a new one
        Notification notification = new NotificationCompat.Builder(this, channelId)
                .setContentTitle(title)
                .setContentText(text)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setPriority(NotificationCompat.PRIORITY_MIN)
                .setOngoing(true)
                .build();

        startForeground(1, notification);

        // Play Athan audio from res/raw
        player = MediaPlayer.create(this, R.raw.athan_full); // MP3 or WAV
        player.setOnCompletionListener(mp -> stopSelf());
        player.start();

        return START_NOT_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (player != null) {
            player.release();
            player = null;
        }
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
