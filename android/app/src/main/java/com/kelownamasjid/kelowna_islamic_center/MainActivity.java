package com.kelownamasjid.kelowna_islamic_center;

import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.List;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
	private static final String ATHAN_ALARM_CHANNEL = "com.kelownamasjid.kelowna_islamic_center/athan_alarm";

	@Override
	public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
		super.configureFlutterEngine(flutterEngine);

		new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), ATHAN_ALARM_CHANNEL)
			.setMethodCallHandler((MethodCall call, MethodChannel.Result result) -> {
				switch (call.method) {
					case "isAthanAlarmServiceAvailable":
						result.success(true);
						return;
					case "scheduleAthanAlarm": {
						Integer id = call.argument("id");
						Long triggerAtMillis = call.argument("triggerAtMillis");
						String title = call.argument("title");
						String body = call.argument("body");
						String soundResName = call.argument("soundResName");

						if (id == null || triggerAtMillis == null || title == null || body == null) {
							result.error("bad_args", "Missing required scheduleAthanAlarm arguments", null);
							return;
						}

						AthanAlarmScheduler.scheduleAthanAlarm(
							this,
							id,
							triggerAtMillis,
							title,
							body,
							soundResName == null ? "athan_full" : soundResName
						);

						result.success(null);
						return;
					}
					case "cancelAthanAlarm": {
						Integer id = call.argument("id");
						if (id == null) {
							result.error("bad_args", "Missing id", null);
							return;
						}

						AthanAlarmScheduler.cancelAthanAlarm(this, id);
						result.success(null);
						return;
					}
					case "cancelAthanAlarms": {
						List<Integer> ids = new ArrayList<>();
						List<?> rawIds = call.argument("ids");
						if (rawIds != null) {
							for (Object rawId : rawIds) {
								if (rawId instanceof Integer) {
									ids.add((Integer) rawId);
								}
							}
						}

						AthanAlarmScheduler.cancelAthanAlarms(this, ids);
						result.success(null);
						return;
					}
					case "hasScheduledAthanAlarm":
						result.success(AthanAlarmScheduler.hasScheduledAthanAlarm(this));
						return;
					case "triggerTestAthanNow": {
						String title = call.argument("title");
						String body = call.argument("body");
						String soundResName = call.argument("soundResName");

						AthanAlarmScheduler.startAthanAudioNow(
							this,
							Math.abs((int) System.currentTimeMillis()),
							title == null ? "Athan Reminder" : title,
							body == null ? "Test Athan alert" : body,
							soundResName == null ? "athan_full" : soundResName
						);

						result.success(null);
						return;
					}
					default:
						result.notImplemented();
				}
			});
	}
}
