import "dart:convert";
import "dart:io";
import "package:intl/intl.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:http/http.dart" as http;
import "package:shared_preferences_android/shared_preferences_android.dart";
import "package:shared_preferences_ios/shared_preferences_ios.dart";
import "package:workmanager/workmanager.dart";

import "../config.dart";
import "../structs/prayer_item.dart";


class ApiFetchService {
  // Unique background task string
  static const String taskUniqueName = "apiBackgroundFetchTask";

  static Future<void> initBackgroundService() async {
    // Periodic Task that keeps checking for next Iqamah to schedule notification for
    await Workmanager().registerPeriodicTask(
        "2", 
        taskUniqueName,
        constraints: Constraints(networkType: NetworkType.connected), // Requires network connection
        frequency: const Duration(hours: 8), // Slow api requests, every 8 hours should be enough
        existingWorkPolicy: ExistingWorkPolicy.keep
    );
  }

  // Set local time data to updated prayer times from firebase functions api
  static Future<void> updateSharedPreferencesTimes() async {

    // Init SharedPreferences
    if (Platform.isAndroid) SharedPreferencesAndroid.registerWith();
    if (Platform.isIOS) SharedPreferencesIOS.registerWith();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    http.Response apiResponse;
    http.Response apiResponseForNextDay;

    // Server request
    try {
      apiResponse = await http.get(Uri.parse(Config.apiLink)).timeout(const Duration(seconds: 30)); // BCMA API Request
      apiResponseForNextDay = await http.get(Uri.parse(Config.apiLinkForNextDay)).timeout(const Duration(seconds: 30));

      String timeStamp = DateFormat("yyyy-MM-dd").format(DateTime.now());

      List<String> timesList = PrayerItem.toJsonStringFromList(
        await PrayerItem.listFromFetchedJson(
          jsonDecode(apiResponse.body)
        )
      );

      List<String> timesNextDayList = PrayerItem.toJsonStringFromList(
        await PrayerItem.listFromFetchedJson(
          jsonDecode(apiResponseForNextDay.body)
        )
      );
      
      // Set local data to server data
      if (apiResponse.statusCode == 200) {
        await prefs.setString("prayerTimeStamp", timeStamp); // Cache server date
        await prefs.setStringList("prayerTimes", timesList); // Cache server data for today's times
        await prefs.setStringList("prayerTimesNextDay", timesNextDayList); // Cache server data for tomorrow's times
      }
    } catch(e) {
      return;
    }
  }
}