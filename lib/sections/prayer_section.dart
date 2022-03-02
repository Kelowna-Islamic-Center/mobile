import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../widgets/gradient_button.dart';

// TODO: Offline functionality
// TODO: Background checking service
// API data class (other data is fetched from firestore)
class PrayerItem {
  final String startTime;
  final String iqamahTime;

  const PrayerItem({
    required this.startTime,
    required this.iqamahTime
  });

  static listFromJSON(List<dynamic> json) {
    List<PrayerItem> parsedList = [];

    for (int i = 0; i < json.length; i++) {
      parsedList.add(PrayerItem(
        startTime: json[i]['start'], 
        iqamahTime: json[i]['timings']
      ));
    }
    return parsedList;
  }
}


Future<Map<String, dynamic>> fetchTimes() async {
  final apiResponse = await http.get(Uri.parse('https://api.kelownaislamiccenter.org/files/php/data-fetch.php')); // BCMA Api Request
  final fsSnapshot = await FirebaseFirestore.instance.collection('prayers').get(); // Firestore get (dont need realtime data)
  return {
    "times": PrayerItem.listFromJSON(jsonDecode(apiResponse.body)),
    "fbSnapshot": fsSnapshot.docs
  };
}


class PrayerPage extends StatefulWidget {
  const PrayerPage({Key? key}) : super(key: key);

  @override
  State<PrayerPage> createState() => _PrayerWidgetState();
}

class _PrayerWidgetState extends State<PrayerPage> {

  Timer? timer;
  String _timeString = "...";
  bool _isAthanActive = false; // If athan times are selected
  Map<String, dynamic> _highlightedIndexes = {"iqamah": "...", "start": "..."}; // Selected prayerItem indexes that will be highlighted
  late Future<Map<String, dynamic>> timesFetch; // Prayer times https fetch

  @override
  void initState() {
    timesFetch = fetchTimes(); // Fetch Prayer Times
    _updateTime();
    timer = Timer.periodic(const Duration(seconds: 10), (Timer t) => _updateTime()); // Realtime Clock timer
    super.initState();
  }

  @override
  void dispose() {
    timer!.cancel();
    super.dispose();
  }

  // Clock and highlight checker update
  void _updateTime() async {
    final String dateTime = DateFormat('KK:mm - EEE. d MMMM').format(DateTime.now()).toString();
    setState(() {
      _timeString = dateTime;
      timesFetch.then((value) => 
        _highlightedIndexes = getActivePrayer(value["times"]));
    });
  }

  //Calculate nearest prayer time (highlighted prayer time)
  Map<String, int> getActivePrayer(List<PrayerItem> timeList) {
    final DateTime now = DateTime.now();
    final int nowTotalMinutes = now.hour * 60 + now.minute; // Current time in minutes

    int getClosestTime(bool isIqamahTimes) {
      int activeIndex = 0;
      int initDiff = 999999;

      for (int i = 0; i < timeList.length; i++) {
        
        int today = DateTime.now().weekday; // Today's day of the week
        if (i == 2 && today == DateTime.friday) continue; // Skip if Duhr on Friday
        if (i == 6 && today != DateTime.friday) continue; // Skip if Jumuah on Other days

        // Parse string into different time parts
        List<String> stringSplit = isIqamahTimes ? timeList[i].iqamahTime.split(':') : timeList[i].startTime.split(':');
        int hour = int.parse(stringSplit[0]);
        int minute = int.parse(stringSplit[1].split(' ')[0]);
        String amPM = stringSplit[1].split(' ')[1];

        hour = (hour == 12 && amPM.toLowerCase() == "am" || amPM.toLowerCase() == "a.m.") ? 0 : hour; // If midnight then set 12 to 0
        hour = (hour != 12 && amPM.toLowerCase() == "pm" || amPM.toLowerCase() == "p.m.") ? hour + 12 : hour; // Add 12 hours if PM

        int totalMinutes = hour * 60 + minute;
        int difference = (totalMinutes - nowTotalMinutes).abs(); // Difference between currentime and a prayerTime
        
        if (difference <= initDiff) {
          initDiff = difference; // Set lowest difference
          activeIndex = i;// Set active index to the current index
        }
      }

      return activeIndex;
    }

    return {
      "iqamah": getClosestTime(true),
      "start": getClosestTime(false)
    };
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
                      future: timesFetch,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                        return Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemCount: snapshot.data!["fbSnapshot"].length,
                            itemBuilder: (context, index) {
                              // Set either athan or iqamah time based on user selection
                              String _selectedTime = _isAthanActive ? snapshot.data!["times"][index].startTime : snapshot.data!["times"][index].iqamahTime;

                              return ListTile(
                                  visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                                  title: Container(
                                      padding: const EdgeInsets.fromLTRB(15, 17, 15, 17),
                                      decoration: BoxDecoration(
                                        gradient: (_isAthanActive)
                                            ? (_highlightedIndexes["start"] == index)
                                                ? const LinearGradient(colors: [Colors.amber, Colors.red])
                                                : null
                                            : (_highlightedIndexes["iqamah"] == index)
                                                ? const LinearGradient(colors: [Colors.green, Colors.teal])
                                                : null,
                                        boxShadow: 
                                            (_highlightedIndexes["start"] == index || _highlightedIndexes["iqamah"] == index)
                                            ? [
                                                BoxShadow(
                                                  color: Colors.grey.withOpacity(0.6),
                                                  spreadRadius: 2,
                                                  blurRadius: 5,
                                                  offset: const Offset(0,2), // changes position of shadow
                                                ),
                                              ]
                                            : null,
                                        image: (_highlightedIndexes["start"] == index || _highlightedIndexes["iqamah"] == index)
                                            ?
                                              const DecorationImage(
                                                image: AssetImage('assets/images/pattern_bitmap.png'),
                                                repeat: ImageRepeat.repeat)
                                            : null,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(snapshot.data!["fbSnapshot"][index]['name'],
                                              style: TextStyle(
                                                  fontFamily: 'Bebas',
                                                  fontSize: 21,
                                                  fontWeight: FontWeight.w500,
                                                  color: (_highlightedIndexes["start"] ==index ||_highlightedIndexes["iqamah"] == index)
                                                      ? Colors.white
                                                      : null)),
                                          Text(_selectedTime,
                                              style: TextStyle(
                                                  fontFamily: 'Bebas',
                                                  fontSize: 21,
                                                  color: (_highlightedIndexes["start"] == index || _highlightedIndexes["iqamah"] == index)
                                                      ? Colors.white
                                                      : null)),
                                        ],
                                      )));
                            } // Load as many prayer widgets as required
                          )
                        );
                      })
              ],)
          ))
        ])
      );
}