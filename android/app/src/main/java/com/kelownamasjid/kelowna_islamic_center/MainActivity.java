package com.kelownamasjid.kelowna_islamic_center;

import android.content.Intent;
import android.os.Build;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "com.kelownamasjid.athan";

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    if (call.method.equals("startAndroidAthanService")) {
                        String channelId = call.argument("channelId");
                        String title = call.argument("title");
                        String text = call.argument("text");

                        Intent serviceIntent = new Intent(this, AthanService.class);
                        serviceIntent.putExtra("channelId", channelId);
                        serviceIntent.putExtra("title", title);
                        serviceIntent.putExtra("text", text);

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent);
                        } else {
                            startService(serviceIntent);
                        }

                        result.success(null);
                    } else {
                        result.notImplemented();
                    }
                }
            );
    }
}
