package com.kelownamasjid.kelowna_islamic_center;

import android.content.Intent;
import android.os.Parcel;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingBackgroundService;

import java.util.Map;

public class FirebaseAthanMessagingService extends FirebaseMessagingService {

    @Override
    public void onMessageReceived(@NonNull RemoteMessage message) {

        Map<String, String> data = message.getData();
        if (data == null || data.isEmpty()) {
            return;
        }

        String action = data.get("action");

        if ("play_athan".equals(action)) {
            String channelId = data.get("channelId");
            String title = data.get("title");
            String text = data.get("text");

            Intent svcIntent = new Intent(getApplicationContext(), AthanService.class);
            svcIntent.setAction("START_ATHAN");
            if (channelId != null) svcIntent.putExtra("channelId", channelId);
            if (title != null) svcIntent.putExtra("title", title);
            if (text != null) svcIntent.putExtra("text", text);

            ContextCompat.startForegroundService(getApplicationContext(), svcIntent);
        }

        super.onMessageReceived(message);
    }
}
