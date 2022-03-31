import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:shared_preferences_ios/shared_preferences_ios.dart';
import 'package:workmanager/workmanager.dart';

import '../structs/prayer_item.dart';


class ApiFetchService {
  // Unique background task string
  static const String taskUniqueName = "apiBackgroundFetchTask";

  Future<void> initBackgroundService() async {
    // Periodic Task that keeps checking for next Iqamah to schedule notification for
    await Workmanager().registerPeriodicTask(
        "0", 
        taskUniqueName,
        constraints: Constraints(networkType: NetworkType.connected), // Requires network connection
        frequency: const Duration(hours: 8), // Slow api requests, every 8 hours should be enough
    );
  }

  // Set local time data to updated prayer times from firebase functions api
  Future<void> updateSharedPreferencesTimes() async {

    // Init SharedPreferences
    if (Platform.isAndroid) SharedPreferencesAndroid.registerWith();
    if (Platform.isIOS) SharedPreferencesIOS.registerWith();
    final prefs = await SharedPreferences.getInstance();

    http.Response apiResponse;

    // Server request
    try {
      apiResponse = await http.get(Uri.parse('https://us-central1-kelownaislamiccenter.cloudfunctions.net/apiFetch')).timeout(const Duration(seconds: 20)); // BCMA API Request
      
      // Set local data to server data
      if (apiResponse.statusCode == 200) {
        await prefs.setString("prayerTimeStamp", DateFormat("yyyy-MM-dd").format(DateTime.now())); // Cache server date
        await prefs.setStringList("prayerTimes", PrayerItem.toJsonStringFromList(PrayerItem.listFromFetchedJson(jsonDecode(apiResponse.body)))); // Cache server data
        print("Successfully fetched server data from background");
      }
    } catch(e) {
      print("Error, couldn't load data");
    }
  }
}

/*

// Handle Background Tasks
Future<void> initalizeWorkManager() async {
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  await Workmanager().registerOneOffTask(
      "1", PrayerFetchService.fetchBackground,
      constraints: Constraints(networkType: NetworkType.connected),
      initialDelay: const Duration(seconds: 30));
  // await Workmanager().registerPeriodicTask(
  //   "1",
  //   PrayerFetchService.fetchBackground,
  //   frequency: const Duration(hours: 4),
  //   constraints: Constraints(
  //     networkType: NetworkType.connected,
  //   ),
  // );
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Task: $task");
    print("Registered Name: ${PrayerFetchService.fetchBackground}");
    switch (task) {
      case PrayerFetchService.fetchBackground:
        PrayerFetchService.updateLocalTimes();
        break;
    }
    return Future.value(true);
  });
}

await initalizeWorkManager();
 */