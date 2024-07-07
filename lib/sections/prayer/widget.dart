import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kelowna_islamic_center/sections/prayer/worker.dart';
import 'package:kelowna_islamic_center/theme.dart';

import '../../widgets/gradient_button.dart';


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

    fetchedData = fetchPrayerTimes(); // Set to latest Prayer Times
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