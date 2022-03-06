import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/gradient_button.dart';
import '../structs/prayer_item.dart';


// TODO: Background checking service
// TODO: Fix overflow

// Get Updated paryer times from server and firestore
Future<Map<String, dynamic>> fetchTimes() async {

  final prefs = await SharedPreferences.getInstance();
  http.Response apiResponse;
  dynamic fsSnapshot;

  int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  Future<Map<String, dynamic>> loadLocalData() async {
    String? timeStamp = prefs.getString('prayerTimeStamp');
    List<dynamic>? rawJSON = prefs.getStringList('prayerTimes');

    // If server has never been contacted, just set timeStamp to today
    timeStamp ??= DateFormat("yyyy-MM-dd").format(DateTime.now());
    
    // If local data is empty and device offline
    if (rawJSON == null) {
      return {
        "timeStampDiff": DateTime.now().difference(DateFormat("yyyy-MM-dd hh:mm:ss").parse(timeStamp)).inDays,
        "data": <PrayerItem> [
          const PrayerItem(name: "Fajr", startTime: "No Internet", iqamahTime: "No Internet"),
          const PrayerItem(name: "Shurooq", startTime: "No Internet", iqamahTime: "No Internet"),
          const PrayerItem(name: "Duhr", startTime: "No Internet", iqamahTime: "No Internet"),
          const PrayerItem(name: "Asr", startTime: "No Internet", iqamahTime: "No Internet"),
          const PrayerItem(name: "Maghrib", startTime: "No Internet", iqamahTime: "No Internet"),
          const PrayerItem(name: "Isha", startTime: "No Internet", iqamahTime: "No Internet"),
          const PrayerItem(name: "Jumuah", startTime: "No Internet", iqamahTime: "No Internet")
        ]
      };
    } else {
      // If local data contains cached data
      List<dynamic> parsedList = [];
      for (int i = 0; i < rawJSON.length; i++) {
        parsedList.add(jsonDecode(rawJSON[i]));
      }

      return {
        "timeStampDiff": daysBetween(DateFormat("yyyy-MM-dd").parse(timeStamp), DateTime.now()),
        "data": PrayerItem.listFromFetchedJson(parsedList)!
      };
    }
  }

  // Server request
  try {
    apiResponse = await http.get(Uri.parse('https://api.kelownaislamiccenter.org/files/php/data-fetch.php')).timeout(const Duration(seconds: 15)); // BCMA API Request
    fsSnapshot = await FirebaseFirestore.instance.collection('prayers').get(); // Firebase request
    
    // Set local data to server data
    if (apiResponse.statusCode == 200) {
      await prefs.setString("prayerTimeStamp", DateFormat("yyyy-MM-dd").format(DateTime.now()));
      await prefs.setStringList("prayerTimes", PrayerItem.toJsonStringFromList(PrayerItem.listFromFetchedJson(jsonDecode(apiResponse.body), fsSnapshot)));
    }

    return await loadLocalData(); // Load sharedPreferences data
  } catch(e) {
    return await loadLocalData(); // Load sharedPreferences data
  }
}


// Calculate nearest prayer time (highlighted prayer time)
Map<String, int> getActivePrayer(List<PrayerItem> timeList) {
  final DateTime now = DateTime.now();
  final int nowTotalMinutes = now.hour * 60 + now.minute; // Current time in minutes

  int getClosestTime(bool isIqamahTimes) {
    int activeIndex = 0;
    int initDiff = 999999;

    for (int i = 0; i < timeList.length; i++) {
      if (timeList[i].startTime == "No Internet" ||
          timeList[i].iqamahTime == "No Internet") continue;

      int today = DateTime.now().weekday; // Today's day of the week
      if (i == 2 && today == DateTime.friday) continue; // Skip if Duhr on Friday
      if (i == 6 && today != DateTime.friday) continue; // Skip if Jumuah on Other days

      // Parse string into different time parts
      List<String> stringSplit = isIqamahTimes
          ? timeList[i].iqamahTime.split(':')
          : timeList[i].startTime.split(':');
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
      int difference = (totalMinutes - nowTotalMinutes).abs(); // Difference between currentime and a prayerTime

      if (difference <= initDiff) {
        initDiff = difference; // Set lowest difference
        activeIndex = i; // Set active index to the current index
      }
    }

    return activeIndex;
  }

  return {"iqamah": getClosestTime(true), "start": getClosestTime(false)};
}





class PrayerPage extends StatefulWidget {
  const PrayerPage({Key? key}) : super(key: key);

  @override
  State<PrayerPage> createState() => _PrayerWidgetState();
}


class _PrayerWidgetState extends State<PrayerPage> {

  late Future<Map<String, dynamic>> fetchedData;

  Timer? timer;
  String _timeString = "...";
  bool _isAthanActive = false; // If athan times are selected
  Map<String, dynamic> _highlightedIndexes = {"iqamah": "...", "start": "..."}; // Selected prayerItem indexes that will be highlighted

  @override
  void initState() {
    fetchedData = fetchTimes(); // Set to latest Prayer Times
    _updateTimeDisplay();
    timer = Timer.periodic(const Duration(seconds: 10), (Timer t) => _updateTimeDisplay()); // Realtime Clock timer
    super.initState();
  }

  @override
  void dispose() {
    timer!.cancel();
    super.dispose();
  }

  // Clock and highlight checker update
  void _updateTimeDisplay() async {
    final String dateTime = DateFormat('KK:mm - EEE. d MMMM').format(DateTime.now()).toString();
    setState(() {
      _timeString = dateTime;
      fetchedData.then((value) => 
        _highlightedIndexes = getActivePrayer(value["data"]));
    });
  }
    
  @override
  Widget build(BuildContext context) =>
      Scaffold(
        body: Column(children: [
          // Top Time Area
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(0.0),
            padding: const EdgeInsets.all(35.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: _isAthanActive ? [ Colors.amber, Colors.red ] : [ Colors.green, Colors.teal ] // Switch colours based on athan and iqamah selection
              ),
              image: const DecorationImage(
                image: AssetImage('assets/images/pattern_bitmap.png'),
                repeat: ImageRepeat.repeat
              )
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_timeString, style: const TextStyle(
                  fontSize: 22.0,
                  color: Colors.white
                )),
                Text(_isAthanActive
                    ? "Start Times - \u062a\u0648\u0642\u064a\u062a \u0627\u0644\u0623\u0630\u0627\u0646"
                    : "Iqamaah Times - \u062a\u0648\u0642\u064a\u062a \u0627\u0644\u0625\u0642\u0627\u0645\u0629",
                  style: const TextStyle(
                    color: Colors.white
                  )
                )
              ]
            )
          ),

          Expanded(child: Container(
              transform: Matrix4.translationValues(0.0, -15.0, 0.0),
              child: Column(children: [
                // Athaan and Iqaamah Buttons
                  Container(
                      padding: const EdgeInsets.all(15.0),
                      decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(15.0)),
                          color: Colors.white),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                              child: RaisedGradientButton(
                                  onPressed: () {
                                    if (_isAthanActive) setState(() => _isAthanActive = false);
                                  },
                                  enabled: _isAthanActive ? false : true,
                                  text: "Iqamaah")),
                          const SizedBox(width: 20),
                          Expanded(
                              child: RaisedGradientButton(
                                  onPressed: () {
                                    if (!_isAthanActive) setState(() => _isAthanActive = true);
                                  },
                                  enabled: _isAthanActive ? true : false,
                                  gradient: const LinearGradient(
                                      colors: [Colors.amber, Colors.red]),
                                  text: "Start/Athan"))
                        ],
                      )),

                  // Prayer Items List
                  FutureBuilder<Map<String, dynamic>>(
                      future: fetchedData,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        dynamic data = snapshot.data!["data"];

                        return Column(children: [

                            /* Offline message if offline */
                            if (snapshot.data!["timeStampDiff"] > 0)
                              Container(
                                  margin: const EdgeInsets.fromLTRB(15, 17, 15, 17),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Container(
                                        padding: const EdgeInsets.fromLTRB(15, 17, 15, 17),
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10.0),
                                            color: Colors.yellow[800],
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  spreadRadius: 1,
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2))
                                            ]),
                                        child: Row(children: [
                                          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 35),
                                          const SizedBox(width: 10.0),
                                          Flexible(
                                              child: Text(
                                                  "These times are " + snapshot.data!["timeStampDiff"].toString() + " days old. Connect to the Internet to get the latest times.",
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13)))
                                        ])),
                                  )),

                          
                            /* Prayer Times List */
                            ListView.builder(
                                scrollDirection: Axis.vertical,
                                shrinkWrap: true,
                                itemCount: data.length,
                                itemBuilder: (context, index) {
                                  // Set either athan or iqamah time based on user selection
                                  String _selectedTime = _isAthanActive
                                      ? data[index].startTime
                                      : data[index].iqamahTime;

                                  return ListTile(
                                      visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                                      title: Container(
                                          padding: const EdgeInsets.fromLTRB(
                                              15, 17, 15, 17),
                                          decoration: BoxDecoration(
                                            gradient: (_isAthanActive)
                                                ? (_highlightedIndexes["start"] == index)
                                                    ? const LinearGradient(
                                                        colors: [Colors.amber, Colors.red])
                                                    : null
                                                : (_highlightedIndexes["iqamah"] == index)
                                                    ? const LinearGradient(
                                                        colors: [Colors.green,Colors.teal])
                                                    : null,
                                            boxShadow:
                                                (_highlightedIndexes["start"] == index || _highlightedIndexes["iqamah"] == index)
                                                    ? [BoxShadow(
                                                          color: Colors.grey.withOpacity(0.6),
                                                          spreadRadius: 2,
                                                          blurRadius: 5,
                                                          offset: const Offset(0, 2)),]
                                                    : null,
                                            image: (_highlightedIndexes["start"] == index || _highlightedIndexes["iqamah"] == index)
                                                ? const DecorationImage(
                                                    image: AssetImage('assets/images/pattern_bitmap.png'),
                                                    repeat: ImageRepeat.repeat)
                                                : null,
                                            borderRadius: BorderRadius.circular(8),
                                          ),

                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(data[index].name,
                                                  style: TextStyle(
                                                      fontFamily: 'Bebas',
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 1.5,
                                                      color: (_highlightedIndexes["start"] == index || _highlightedIndexes["iqamah"] == index)
                                                          ? Colors.white
                                                          : Colors.black54)),
                                              Text(_selectedTime,
                                                  style: TextStyle(
                                                      fontFamily: 'Bebas',
                                                      fontSize: 22,
                                                      letterSpacing: 1.5,
                                                      color: (_highlightedIndexes["start"] == index || _highlightedIndexes["iqamah"] == index)
                                                          ? Colors.white
                                                          : Colors.black87)),
                                            ],
                                          )));
                                } // Load as many prayer widgets as required
                                )
                          ]);
                      })
              ],)
          ))
        ])
      );
}