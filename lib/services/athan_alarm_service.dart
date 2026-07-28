import "dart:io";

import "package:flutter/services.dart";

class AthanAlarmService {
  static const MethodChannel _channel = MethodChannel("com.kelownamasjid.kelowna_islamic_center/athan_alarm");

  static Future<bool> isAvailable() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      bool? supported = await _channel.invokeMethod<bool>("isAthanAlarmServiceAvailable");
      return supported ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> scheduleAthanAlarm({
    required int id,
    required DateTime triggerAt,
    required String title,
    required String body,
    required String soundResName,
  }) async {
    if (!Platform.isAndroid) {
      return;
    }

    await _channel.invokeMethod<void>("scheduleAthanAlarm", {
      "id": id,
      "triggerAtMillis": triggerAt.millisecondsSinceEpoch,
      "title": title,
      "body": body,
      "soundResName": soundResName,
    });
  }

  static Future<void> cancelAthanAlarm(int id) async {
    if (!Platform.isAndroid) {
      return;
    }

    await _channel.invokeMethod<void>("cancelAthanAlarm", {"id": id});
  }

  static Future<void> cancelAthanAlarms(List<int> ids) async {
    if (!Platform.isAndroid) {
      return;
    }

    await _channel.invokeMethod<void>("cancelAthanAlarms", {"ids": ids});
  }

  static Future<bool> hasScheduledAthanAlarm() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      bool? hasAny = await _channel.invokeMethod<bool>("hasScheduledAthanAlarm");
      return hasAny ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> triggerTestAthanNow({
    required String title,
    required String body,
    required String soundResName,
  }) async {
    if (!Platform.isAndroid) {
      return;
    }

    await _channel.invokeMethod<void>("triggerTestAthanNow", {
      "title": title,
      "body": body,
      "soundResName": soundResName,
    });
  }
}
