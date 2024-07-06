import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:kelowna_islamic_center/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../widgets/gradient_button.dart';
import '../structs/prayer_item.dart';


// Get Updated paryer times from server and firestore
Future<Map<String, dynamic>> fetchTimes() async {

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
    List<dynamic>? rawJSONForNextDay = prefs.getStringList('prayerTimesNextDay');

    // If server has never been contacted, just set timeStamp to today
    timeStamp ??= DateFormat("yyyy-MM-dd").format(DateTime.now());
    
    // If local data for today or tomorrow is empty and device offline
    if (rawJSON == null || rawJSONForNextDay == null) {
      List<PrayerItem> noInternetList = <PrayerItem> [
          const PrayerItem(name: "Fajr", startTime: "No Internet", iqamahTime: "No Internet"),
          const PrayerItem(name: "Shurooq", startTime: "No Internet", iqamahTime: "No Internet"),
          const PrayerItem(name: "Duhr", startTime: "No Internet", iqamahTime: "No Internet"),
          const PrayerItem(name: "Asr", startTime: "No Internet", iqamahTime: "No Internet"),
          const PrayerItem(name: "Maghrib", startTime: "No Internet", iqamahTime: "No Internet"),
          const PrayerItem(name: "Isha", startTime: "No Internet", iqamahTime: "No Internet"),
          const PrayerItem(name: "Jumuah", startTime: "No Internet", iqamahTime: "No Internet")
        ];
      return {
        "timeStampDiff": DateTime.now().difference(DateFormat("yyyy-MM-dd").parse(timeStamp)).inDays,
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
        "timeStampDiff": daysBetween(DateFormat("yyyy-MM-dd").parse(timeStamp), DateTime.now()),
        "data": PrayerItem.listFromFetchedJson(parsedList)!,
        "dataForNextDay": PrayerItem.listFromFetchedJson(parsedListForNextDay)!
      };
    }
  }

  // Server request
  try {
    apiResponse = await http.get(Uri.parse(Config.apiLink)).timeout(const Duration(seconds: 20)); // BCMA API Request for today
    apiResponseForNextDay = await http.get(Uri.parse(Config.apiLinkForNextDay)).timeout(const Duration(seconds: 20)); // BCMA API Request for tomorrow
    
    // Set local data to server data
    if (apiResponse.statusCode == 200) {
      await prefs.setString("prayerTimeStamp", DateFormat("yyyy-MM-dd").format(DateTime.now())); // Cache server date
      await prefs.setStringList("prayerTimes", PrayerItem.toJsonStringFromList(PrayerItem.listFromFetchedJson(jsonDecode(apiResponse.body)))); // Cache server data
      await prefs.setStringList("prayerTimesNextDay", PrayerItem.toJsonStringFromList(PrayerItem.listFromFetchedJson(jsonDecode(apiResponseForNextDay.body)))); // Cache server data
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

      hour = (hour == 12 && amPM.toLowerCase() == "am" || amPM.toLowerCase() == "a.m.")
          ? 0
          : hour; // If midnight then set 12 to 0
      hour = (hour != 12 && amPM.toLowerCase() == "pm" || amPM.toLowerCase() == "p.m.")
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

  return {
    "iqamah": getClosestTime(true), 
    "start": getClosestTime(false)
  };
}





class PrayerPage extends StatefulWidget {
  const PrayerPage({Key? key}) : super(key: key);

  @override
  State<PrayerPage> createState() => _PrayerWidgetState();
}


class _PrayerWidgetState extends State<PrayerPage> {

  late Future<Map<String, dynamic>> fetchedData;

  String _selectedDay = "Today";
  Timer? _timer;
  String _timeString = "...";
  bool _isAthanActive = false; // If athan times are selected
  Map<String, dynamic> _highlightedIndexes = {"iqamah": "...", "start": "..."}; // Selected prayerItem indexes that will be highlighted

  @override
  void initState() {
    super.initState();

    fetchedData = fetchTimes(); // Set to latest Prayer Times
    _updateTimeDisplay();
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer t) => _updateTimeDisplay()); // Realtime Clock timer
  }

  @override
  void dispose() {
    super.dispose();
    _timer!.cancel();
  }

  // Clock and highlight checker update
  void _updateTimeDisplay() async {
    final String dateTime = DateFormat.jm().addPattern(' - EEE. d MMMM').format(DateTime.now()).toString();
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
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/pattern_bitmap.png'),
                repeat: ImageRepeat.repeat
              )
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_timeString, style: const TextStyle(
                  fontSize: 24.0,
                )),
                Text(_isAthanActive
                    ? "Start Times - \u062a\u0648\u0642\u064a\u062a \u0627\u0644\u0623\u0630\u0627\u0646"
                    : "Iqamaah Times - \u062a\u0648\u0642\u064a\u062a \u0627\u0644\u0625\u0642\u0627\u0645\u0629",
                  style: const TextStyle(
                    fontSize: 17.0
                  )
                )
              ]
            )
          ),

          Expanded(child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(15.0), topRight: Radius.circular(15.0)),
            ),
            transform: Matrix4.translationValues(0.0, -15.0, 0.0),
            child: SingleChildScrollView(child: 
              Column(children: [
                // Today and
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(
                      "Show times for:".toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.normal,
                        letterSpacing: 2.0,
                        fontSize: 19.0
                      )
                    ),
                    trailing: DropdownButton<String>(
                      value: _selectedDay,
                      items: <String>["Today", "Tomorrow"].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      onChanged: (value) { 
                        setState(() {
                          _selectedDay = value!;
                        });
                      }
                  )
                )),
                // Athaan and Iqaamah Buttons
                Container(
                  padding: const EdgeInsets.fromLTRB(15.0, 0, 15.0, 15.0),
                  child: 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                            child: RaisedGradientButton(
                                onPressed: () {
                                  if (_isAthanActive) setState(() => _isAthanActive = false);
                                },
                                enabled: !_isAthanActive,
                                text: "Iqamaah")),
                        const SizedBox(width: 20),
                        Expanded(
                            child: RaisedGradientButton(
                                onPressed: () {
                                  if (!_isAthanActive) setState(() => _isAthanActive = true);
                                },
                                enabled: _isAthanActive,
                                text: "Start/Athan"))
                      ],
                    ),
                ),
                
                // Prayer Items List
                FutureBuilder<Map<String, dynamic>>(
                    future: fetchedData,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      dynamic data = (_selectedDay.toLowerCase() == "today") ? snapshot.data!["data"] : snapshot.data!["dataForNextDay"]; // Set to either today or tomorrow's time based on user selection

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
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                // Set either athan or iqamah time based on user selection
                                String _selectedTime = _isAthanActive ? data[index].startTime : data[index].iqamahTime;

                                return ListTile(
                                    visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                                    title: Container(
                                        padding: const EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                          gradient:
                                              ((_highlightedIndexes["start"] == index || _highlightedIndexes["iqamah"] == index) && !(_selectedDay.toLowerCase() == "tomorrow"))
                                                  ? AppTheme.gradient : null,
                                              
                                          boxShadow:
                                              (((_highlightedIndexes["start"] == index && _isAthanActive) || (_highlightedIndexes["iqamah"] == index && !_isAthanActive)) && !(_selectedDay.toLowerCase() == "tomorrow"))
                                                  ? [BoxShadow(
                                                        color: Colors.black45.withOpacity(0.4),
                                                        spreadRadius: 0,
                                                        blurRadius: 3,
                                                        offset: const Offset(0, 1)),]
                                                  : null,
                                          image: ((_highlightedIndexes["start"] == index || _highlightedIndexes["iqamah"] == index) && !(_selectedDay.toLowerCase() == "tomorrow"))
                                              ? const DecorationImage(
                                                  image: AssetImage('assets/images/pattern_bitmap.png'),
                                                  repeat: ImageRepeat.repeat)
                                              : null,
                                          borderRadius: BorderRadius.circular(10),
                                        ),

                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(data[index].name,
                                                style: TextStyle(
                                                    fontSize: 22,
                                                    color: (((_highlightedIndexes["start"] == index && _isAthanActive) || (_highlightedIndexes["iqamah"] == index && !_isAthanActive)) && !(_selectedDay.toLowerCase() == "tomorrow"))
                                                        ? Colors.white
                                                        : null)),
                                            Text(_selectedTime,
                                                style: TextStyle(
                                                    fontSize: 22,
                                                    color: (((_highlightedIndexes["start"] == index && _isAthanActive) || (_highlightedIndexes["iqamah"] == index && !_isAthanActive)) && !(_selectedDay.toLowerCase() == "tomorrow"))
                                                        ? Colors.white
                                                        : null)),
                                          ],
                                        )));
                              } // Load as many prayer widgets as required
                              )
                        ]);
                    })
              ],)
            )
          ))
        ])
      );
}