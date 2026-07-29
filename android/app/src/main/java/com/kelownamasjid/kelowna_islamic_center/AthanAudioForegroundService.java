package com.kelownamasjid.kelowna_islamic_center;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.media.AudioAttributes;
import android.media.AudioFocusRequest;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.os.Build;
import android.os.IBinder;
import android.os.PowerManager;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

public class AthanAudioForegroundService extends Service {
  private static final String CHANNEL_ID = "athan_playback_channel";
  private static final String CHANNEL_NAME = "Athan Playback";

  private MediaPlayer mediaPlayer;
  private AudioManager audioManager;
  private AudioFocusRequest audioFocusRequest;

  @Override
  public void onCreate() {
    super.onCreate();
    audioManager = (AudioManager) getSystemService(AUDIO_SERVICE);
    ensureNotificationChannel();
  }

  @Override
  public int onStartCommand(Intent intent, int flags, int startId) {
    if (intent == null) {
      stopSelf();
      return START_NOT_STICKY;
    }

    int alarmId = intent.getIntExtra(AthanAlarmScheduler.EXTRA_ALARM_ID, Math.abs((int) System.currentTimeMillis()));
    String title = intent.getStringExtra(AthanAlarmScheduler.EXTRA_TITLE);
    String body = intent.getStringExtra(AthanAlarmScheduler.EXTRA_BODY);
    String soundResName = intent.getStringExtra(AthanAlarmScheduler.EXTRA_SOUND_RES);

    Notification notification = buildForegroundNotification(
      alarmId,
      title == null ? "Athan Reminder" : title,
      body == null ? "Prayer time" : body
    );

    startForeground(alarmId, notification);
    playAthan(soundResName == null ? "athan_full" : soundResName);

    return START_NOT_STICKY;
  }

  @Override
  public void onDestroy() {
    releasePlayer();
    abandonAudioFocus();
    super.onDestroy();
  }

  @Nullable
  @Override
  public IBinder onBind(Intent intent) {
    return null;
  }

  private void playAthan(String soundResName) {
    releasePlayer();

    int soundResId = getResources().getIdentifier(soundResName, "raw", getPackageName());
    if (soundResId == 0) {
      soundResId = getResources().getIdentifier("athan_full", "raw", getPackageName());
    }

    requestAudioFocus();

    mediaPlayer = MediaPlayer.create(this, soundResId);
    if (mediaPlayer == null) {
      stopSelf();
      return;
    }

    AudioAttributes attributes = new AudioAttributes.Builder()
      .setUsage(AudioAttributes.USAGE_ALARM)
      .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
      .build();

    mediaPlayer.setAudioAttributes(attributes);
    mediaPlayer.setWakeMode(this, PowerManager.PARTIAL_WAKE_LOCK);
    mediaPlayer.setOnCompletionListener(player -> stopSelf());
    mediaPlayer.setOnErrorListener((player, what, extra) -> {
      stopSelf();
      return true;
    });
    mediaPlayer.start();
  }

  private void releasePlayer() {
    if (mediaPlayer == null) {
      return;
    }

    if (mediaPlayer.isPlaying()) {
      mediaPlayer.stop();
    }

    mediaPlayer.release();
    mediaPlayer = null;
  }

  private void requestAudioFocus() {
    if (audioManager == null) {
      return;
    }

    AudioAttributes attributes = new AudioAttributes.Builder()
      .setUsage(AudioAttributes.USAGE_ALARM)
      .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
      .build();

    audioFocusRequest = new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
      .setAudioAttributes(attributes)
      .build();

    audioManager.requestAudioFocus(audioFocusRequest);
  }

  private void abandonAudioFocus() {
    if (audioManager == null) {
      return;
    }

    if (audioFocusRequest != null) {
      audioManager.abandonAudioFocusRequest(audioFocusRequest);
      audioFocusRequest = null;
    }
  }

  private Notification buildForegroundNotification(int alarmId, String title, String body) {
    PendingIntent contentPendingIntent = PendingIntent.getActivity(
      this,
      alarmId,
      new Intent(this, MainActivity.class)
        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP),
      PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
    );

    PendingIntent stopPendingIntent = PendingIntent.getBroadcast(
      this,
      alarmId,
      new Intent(this, AthanServiceActionReceiver.class)
        .setAction(AthanServiceActionReceiver.ACTION_STOP_ATHAN),
      PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
    );

    PendingIntent dismissPendingIntent = PendingIntent.getBroadcast(
      this,
      alarmId + 1,
      new Intent(this, AthanServiceActionReceiver.class)
        .setAction(AthanServiceActionReceiver.ACTION_DISMISS_ATHAN),
      PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
    );

    return new NotificationCompat.Builder(this, CHANNEL_ID)
      .setSmallIcon(R.mipmap.ic_launcher)
      .setContentTitle(title)
      .setContentText(body)
      .setPriority(NotificationCompat.PRIORITY_HIGH)
      .setCategory(NotificationCompat.CATEGORY_ALARM)
      .setContentIntent(contentPendingIntent)
      .setOngoing(false)
      .setDeleteIntent(dismissPendingIntent)
      .setAutoCancel(false)
      .addAction(0, "Stop", stopPendingIntent)
      .build();
  }

  private void ensureNotificationChannel() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
      return;
    }

    NotificationManager notificationManager = getSystemService(NotificationManager.class);
    if (notificationManager == null) {
      return;
    }

    NotificationChannel channel = new NotificationChannel(
      CHANNEL_ID,
      CHANNEL_NAME,
      NotificationManager.IMPORTANCE_HIGH
    );

    channel.setDescription("Foreground playback for Athan alerts");
    channel.setLockscreenVisibility(Notification.VISIBILITY_PUBLIC);
    notificationManager.createNotificationChannel(channel);
  }
}
