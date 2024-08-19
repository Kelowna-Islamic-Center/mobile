import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kelowna_islamic_center/config.dart';
import 'package:kelowna_islamic_center/structs/prayer_item.dart';

class PrayerController {

  // Get Updated prayer times from server and firestore
  static Future<Map<String, dynamic>> fetchPrayerTimes() async {
    final prefs = await SharedPreferences.getInstance();
    http.Response apiResponse;
    http.Response apiResponseForNextDay;

    int daysBetween(DateTime from, DateTime to) {
      from = DateTime(from.year, from.month, from.day);
      to = DateTime(to.year, to.month, to.day);
      return (to.difference(from).inHours / 24).round();
    }

    Future<Map<String, dynamic>> loadLocalData() async {
      String? timeStamp = prefs.getString('prayerTimeStamp');
      List<dynamic>? rawJSON = prefs.getStringList('prayerTimes');
      List<dynamic>? rawJSONForNextDay =
          prefs.getStringList('prayerTimesNextDay');

      // If server has never been contacted, just set timeStamp to today
      timeStamp ??= DateFormat("yyyy-MM-dd").format(DateTime.now());

      // If local data for today or tomorrow is empty and device offline
      if (rawJSON == null || rawJSONForNextDay == null) {
        List<PrayerItem> noInternetList = <PrayerItem>[
          const PrayerItem(
              name: "Fajr",
              startTime: "No Internet",
              iqamahTime: "No Internet"),
          const PrayerItem(
              name: "Shurooq",
              startTime: "No Internet",
              iqamahTime: "No Internet"),
          const PrayerItem(
              name: "Duhr",
              startTime: "No Internet",
              iqamahTime: "No Internet"),
          const PrayerItem(
              name: "Asr", startTime: "No Internet", iqamahTime: "No Internet"),
          const PrayerItem(
              name: "Maghrib",
              startTime: "No Internet",
              iqamahTime: "No Internet"),
          const PrayerItem(
              name: "Isha",
              startTime: "No Internet",
              iqamahTime: "No Internet"),
          const PrayerItem(
              name: "Jumuah",
              startTime: "No Internet",
              iqamahTime: "No Internet")
        ];

        return {
          "timeStampDiff": -1,
          "data": noInternetList,
          "dataForNextDay": noInternetList
        };
      } else {
        // If local data contains cached data
        List<dynamic> parsedList = [];
        for (int i = 0; i < rawJSON.length; i++) {
          parsedList.add(jsonDecode(rawJSON[i]));
        }

        // If local data for next day contains cached data
        List<dynamic> parsedListForNextDay = [];
        for (int i = 0; i < rawJSONForNextDay.length; i++) {
          parsedListForNextDay.add(jsonDecode(rawJSONForNextDay[i]));
        }

        return {
          "timeStampDiff": daysBetween(
              DateFormat("yyyy-MM-dd").parse(timeStamp), DateTime.now()),
          "data": PrayerItem.listFromFetchedJson(parsedList)!,
          "dataForNextDay":
              PrayerItem.listFromFetchedJson(parsedListForNextDay)!
        };
      }
    }

    final localData = await loadLocalData();

    // Server request
    try {
      // Update local data only if times are outdated
      if (localData["timeStampDiff"] > 0 || localData["timeStampDiff"] == -1) {
        apiResponse = await http
            .get(Uri.parse(Config.apiLink))
            .timeout(const Duration(seconds: 20)); // API Request for today
        apiResponseForNextDay = await http
            .get(Uri.parse(Config.apiLinkForNextDay))
            .timeout(const Duration(seconds: 20)); // API Request for tomorrow

        // Set local data to server data
        if (apiResponse.statusCode == 200) {
          await prefs.setString(
              "prayerTimeStamp",
              DateFormat("yyyy-MM-dd")
                  .format(DateTime.now())); // Cache server date
          await prefs.setStringList(
              "prayerTimes",
              PrayerItem.toJsonStringFromList(PrayerItem.listFromFetchedJson(
                  jsonDecode(apiResponse.body)))); // Cache server data
          await prefs.setStringList(
              "prayerTimesNextDay",
              PrayerItem.toJsonStringFromList(PrayerItem.listFromFetchedJson(
                  jsonDecode(
                      apiResponseForNextDay.body)))); // Cache server data
        }

        return await loadLocalData(); // Reload localData after update
      } else {
        return localData;
      }
    } catch (e) {
      return localData;
    }
  }

// Calculate nearest prayer time (highlighted prayer time)
  static Map<String, int> getActivePrayer(List<PrayerItem> timeList) {
    final DateTime now = DateTime.now();
    final int nowTotalMinutes =
        now.hour * 60 + now.minute; // Current time in minutes

    int getClosestTime(bool isAthanTimes) {
      int activeIndex = 0;
      int initDiff = 999999;

      for (int i = 0; i < timeList.length; i++) {
        if (timeList[i].startTime == "No Internet" ||
            timeList[i].iqamahTime == "No Internet") continue;

        int today = DateTime.now().weekday; // Today's day of the week
        if (i == 2 && today == DateTime.friday) {
          continue; // Skip if Duhr on Friday
        }

        if (i == 6 && today != DateTime.friday) {
          continue; // Skip Jumuah on days that are not Friday
        }

        // Parse string into different time parts
        List<String> stringSplit = isAthanTimes
            ? timeList[i].startTime.split(':')
            : timeList[i].iqamahTime.split(':');
        int hour = int.parse(stringSplit[0]);
        int minute = int.parse(stringSplit[1].split(' ')[0]);
        String amPM = stringSplit[1].split(' ')[1];

        hour = (hour == 12 && amPM.toLowerCase() == "am" ||
                amPM.toLowerCase() == "a.m.")
            ? 0
            : hour; // If midnight then set 12 to 0
        hour = (hour != 12 && amPM.toLowerCase() == "pm" ||
                amPM.toLowerCase() == "p.m.")
            ? hour + 12
            : hour; // Add 12 hours if PM

        int totalMinutes = hour * 60 + minute;
        int difference = (totalMinutes - nowTotalMinutes)
            .abs(); // Difference between current time and a prayerTime

        if (difference <= initDiff) {
          initDiff = difference; // Set lowest difference
          activeIndex = i; // Set active index to the current index
        }
      }

      return activeIndex;
    }

    return {"iqamah": getClosestTime(false), "start": getClosestTime(true)};
  }
}