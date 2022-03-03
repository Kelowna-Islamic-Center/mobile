import 'package:flutter/material.dart';

import '../widgets/gradient_button.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsPage> {

  bool _iqamahTimeSwitch = true;
  bool _announcementSwitch = true;
  int _dropdownIqamaahTime = 15;

  @override
  void initState() {
    // TODO: Set to stored values
    _iqamahTimeSwitch = true;
    _announcementSwitch = true;
    _dropdownIqamaahTime = 15;
    
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
          body: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(15, 17, 15, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 4.0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(7.0),
                                child: const Image(image: AssetImage('assets/images/masjid_photo.jpg'))),
                              const SizedBox(height: 20),
                              Text("The BCMA Kelowna Branch".toUpperCase(), 
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text("1120 BC-33, Kelowna, BC V1X 1Z2",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 14)),
                              const SizedBox(height: 15),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  RaisedGradientButton(
                                    onPressed: () {}, text: "Email Us"),
                                  const SizedBox(width: 30),
                                  RaisedGradientButton(
                                      onPressed: () {}, text: "Website")
                                ],
                              )
                            ],
                        ))
                    ))
                  ),

                  // Support the App Card
                  Container(
                    margin: const EdgeInsets.fromLTRB(15, 17, 15, 17),
                    child: SizedBox(
                      width: double.infinity,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(15, 17, 15, 17),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          gradient: const LinearGradient(
                              colors: [Colors.green, Colors.teal]),
                          boxShadow: [BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2))],
                          image: const DecorationImage(
                              image: AssetImage('assets/images/pattern_bitmap.png'),
                              repeat: ImageRepeat.repeat)),
                        child: 
                          Row(
                            children: const [
                              Icon(Icons.recommend, color: Colors.white, size: 35),
                              SizedBox(width: 10.0),
                              Flexible(child:
                                Text(
                                  "Support this app by donating to the Masjid & leaving a review",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17)))
                            ]
                          )
                      ),
                  )),
                  

                  // Settings Begin
                  SwitchListTile(
                    value: _iqamahTimeSwitch,
                    onChanged: (bool newValue) {
                      setState(() {
                        _iqamahTimeSwitch = newValue;
                      });
                    },
                    secondary: const Icon(Icons.access_alarm_rounded),
                    title: const Text("Iqamaah Time Reminder")),
                  ListTile(
                    enabled: _iqamahTimeSwitch,
                    leading: const SizedBox(),
                    title: const Text("Time before Iqamaah"),
                    subtitle: const Text("How much time before Iqamaah should the app send a reminder?"),
                    trailing: DropdownButton<int>(
                      value: _dropdownIqamaahTime,
                      items: <int>[5, 10, 15, 20, 30, 45].map<DropdownMenuItem<int>>((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(value.toString() + " minutes"),
                          );
                        }).toList(),
                      onChanged: (_iqamahTimeSwitch) ? (value) { setState(() {
                        _dropdownIqamaahTime = value!;
                      });} : null
                    )),
                  SwitchListTile(
                      value: _announcementSwitch,
                      onChanged: (bool newValue) {
                        setState(() {
                          _announcementSwitch = newValue;
                        });
                      },
                      secondary: const Icon(Icons.notification_important),
                      title: const Text("New Announcements Alert"))
                ]
      )));
}
