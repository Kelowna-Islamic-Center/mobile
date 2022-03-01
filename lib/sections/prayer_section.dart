import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// TODO: Offline functionality
// TODO: Enable highlighting
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
    setState(() => _timeString = dateTime);

    timesFetch.then((value) => checkActivePrayer(value["times"]));
  }

  //Calculate nearest prayer time (highlighted prayer time)
  Map<String, int> checkActivePrayer(List<PrayerItem> timeList) {
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


  // Each prayerItem's widget
  Widget _prayerList() =>
    FutureBuilder<Map<String, dynamic>>(
      future: timesFetch,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        return ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: snapshot.data!["fbSnapshot"].length,
          itemBuilder: (context, index) {
            String _selectedTime = _isAthanActive ? snapshot.data!["times"][index].startTime : snapshot.data!["times"][index].iqamahTime; // Set either athan or iqamah time based on user selection
            
            return ListTile(
              title: Row(children: [
                Text(snapshot.data!["fbSnapshot"][index]['name']),
                Text(_selectedTime)
              ],)
            );
          } // Load as many prayer widgets as required
        );
      }
    );
    
  @override
  Widget build(BuildContext context) =>
      Scaffold(
        body: Column(children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _timeString,
                style: const TextStyle(fontSize: 23.0) 
              ),
              Text(_isAthanActive ? "Start Times - \u062a\u0648\u0642\u064a\u062a \u0627\u0644\u0623\u0630\u0627\u0646" : "Iqamaah Times - \u062a\u0648\u0642\u064a\u062a \u0627\u0644\u0625\u0642\u0627\u0645\u0629")
            ],
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_isAthanActive) setState(() => _isAthanActive = false);
                    },
                    child: const Text("Iqamaah")
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (!_isAthanActive) setState(() => _isAthanActive = true);
                    },
                    child: const Text("Start/Athan")
                  )
                ],
              ),
            ],
          ),

          _prayerList()
        ])
      );
}