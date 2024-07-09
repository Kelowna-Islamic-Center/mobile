import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kelowna_islamic_center/sections/prayer/prayer_list.dart';
import 'package:kelowna_islamic_center/theme.dart';

class PrayerPage extends StatefulWidget {
  const PrayerPage({Key? key}) : super(key: key);

  @override
  State<PrayerPage> createState() => _PrayerWidgetState();
}

class _PrayerWidgetState extends State<PrayerPage> {

  String selectedDay = "Today";
  Timer? timer;
  String timeString = "...";

  @override
  void initState() {
    super.initState();
    updateTimeDisplay();
    timer = Timer.periodic(const Duration(seconds: 1),
        (Timer t) => updateTimeDisplay()); // Realtime Clock timer
  }

  @override
  void dispose() {
    super.dispose();
    timer!.cancel();
  }

  // Clock and highlight checker update
  void updateTimeDisplay() async {
    final String dateTime = DateFormat.jm()
        .addPattern(' - EEE. d MMMM')
        .format(DateTime.now())
        .toString();
    setState(() {
      timeString = dateTime;
    });
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
          body: Column(children: [
        // Top Time Area
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(35.0),
            decoration: BoxDecoration(
                gradient: (Theme.of(context).brightness == Brightness.light) ? AppTheme.gradient : null,
                image: const DecorationImage(
                    image: AssetImage('assets/images/pattern_bitmap.png'),
                    repeat: ImageRepeat.repeat)),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(timeString,
                  style: TextStyle(
                    fontSize: 24.0,
                    color: (Theme.of(context).brightness == Brightness.light) ? Colors.white : null,
                  )),
            ])),

        Expanded(
            child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15.0),
                      topRight: Radius.circular(15.0)),
                ),
                transform: Matrix4.translationValues(0.0, -15.0, 0.0),
                child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 12.0, 8.0, 12.0),
                      child: ListTile(
                          leading: const Icon(Icons.calendar_month_rounded),
                          title: const Text("Prayer Times For:",
                              style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 18.0)),
                          trailing: DropdownButton<String>(
                            value: selectedDay,
                            onChanged: (String? value) {
                              setState(() {
                                selectedDay = value!;
                              });
                            },
                            items: ["Today", "Tomorrow"]
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                  value: value, child: Text(value));
                            }).toList(),
                          ))),
                  const TabBar(
                    tabs: <Widget>[
                      Tab(
                        icon: Icon(Icons.record_voice_over_rounded),
                        text: "Iqamaah Times",
                      ),
                      Tab(
                        icon: Icon(Icons.mosque_rounded),
                        text: "Athan Times",
                      ),
                    ],
                  ),
                  Expanded(
                      child: TabBarView(children: [
                        PrayerList(isAthanTimesActive: false, isTodayActive: selectedDay == "Today"),
                        PrayerList(isAthanTimesActive: true, isTodayActive: selectedDay == "Today")
                  ]))
                ]))),
      ])));
}
