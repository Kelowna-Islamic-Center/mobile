import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PrayerItem {
  final String startTime;
  final String iqamahTime;
  final String id;
  String? name;

  PrayerItem({required this.id, required this.startTime, required this.iqamahTime, this.name});

  static Future<List<PrayerItem>> listFromFetchedJson(List<dynamic> json) async {
    List<PrayerItem> parsedList = [];

    for (int i = 0; i < json.length; i++) {
      dynamic item = json[i];

      parsedList.add(PrayerItem(
          id: item['id'],
          name: await _getLocalizedName(item['id']),
          startTime: item['start'],
          iqamahTime: item['iqamah']));
    }

    return parsedList;
  }

  static List<String> toJsonStringFromList(List<PrayerItem> list) {
    List<String> jsonList = [];

    for (int i = 0; i < list.length; i++) {
      jsonList.add('{"id":"${list[i].id}", "start":"${list[i].startTime}", "iqamah":"${list[i].iqamahTime}"}');
    }
    return jsonList;
  }

  static Future<String> _getLocalizedName(String id) async {
    final appLocalizations = await AppLocalizations.delegate
      .load(Locale(Platform.localeName.substring(0, 2)));

    switch (id.toLowerCase()) {
      case "fajr":
        return appLocalizations.fajr;
      case "shurooq":
        return appLocalizations.shurooq;
      case "duhr":
        return appLocalizations.duhr;
      case "asr":
        return appLocalizations.asr;
      case "maghrib":
        return appLocalizations.maghrib;
      case "isha":
        return appLocalizations.isha;
      case "jumuah":
        return appLocalizations.jumuah;
      default:
        return appLocalizations.unknownPrayer;
    }
  }
}
