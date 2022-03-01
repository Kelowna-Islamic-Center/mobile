import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

// TODO: Offline functionality
// TODO: Set http permissions
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

// API Request
Future<List<PrayerItem>> fetchTimes() async {
  final response = await http.get(Uri.parse('https://api.kelownaislamiccenter.org/files/php/data-fetch.php'));
  return PrayerItem.listFromJSON(jsonDecode(response.body));
}


class PrayerPage extends StatefulWidget {
  const PrayerPage({Key? key}) : super(key: key);
  @override
  State<PrayerPage> createState() => _PrayerPageState();
}


class _PrayerPageState extends State<PrayerPage> {

  bool isAthanActive = false; // If athan times are selected
  late Future<List<PrayerItem>> prayerTimes; // Prayer times https fetch
  String _timeString = "12:00";

  @override
  void initState() {
    super.initState();
    prayerTimes = fetchTimes(); // Fetch Prayer Times
  }

  // Each prayer widget
  Widget _prayerItem(BuildContext context, int index, DocumentSnapshot firebaseSnapshot) =>
    FutureBuilder<List<PrayerItem>>(
      future: prayerTimes,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        String _selectedTime = isAthanActive ? snapshot.data![index].startTime : snapshot.data![index].iqamahTime; // Set either athan or iqamah time based on user selection
        return ListTile(
          title: Row(children: [
            Text(firebaseSnapshot['name']),
            Text(_selectedTime)
          ],)
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
              Text(isAthanActive ? "Start Times - \u062a\u0648\u0642\u064a\u062a \u0627\u0644\u0623\u0630\u0627\u0646" : "Iqamaah Times - \u062a\u0648\u0642\u064a\u062a \u0627\u0644\u0625\u0642\u0627\u0645\u0629")
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
                      if (isAthanActive) setState(() => isAthanActive = false);
                    },
                    child: const Text("Iqamaah")
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (!isAthanActive) setState(() => isAthanActive = true);
                    },
                    child: const Text("Start/Athan")
                  )
                ],
              ),

              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('prayers')
                    .snapshots(), // Fetch name and id from Firestore
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Error... Something went wrong.');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  ;
                  return ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) => _prayerItem(
                          context,
                          index,
                          snapshot.data!.docs[
                              index]) // Load as many prayer widgets as required
                      );
                })
            ],
          )
        ])
      );
}


