import 'package:flutter/material.dart';
import 'package:kelowna_islamic_center/services/announcements_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/gradient_button.dart';

// Settings Values
Map<String, dynamic> settings = {
  "iqamahTimeAlert": true,
  "iqamahTimeAlertTime": 15,
  "announcementAlert": true,
};

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsPage> {

  @override
  void initState() {
    setToValues(); 
    super.initState();
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  // Set settings values to data stored in SharedPreferences
  void setToValues() async {
    final prefs = await SharedPreferences.getInstance();
    
    Map<String, dynamic> data = {
      "iqamahTimeAlert": prefs.getBool('iqamahTimeAlert'),
      "iqamahTimeAlertTime": prefs.getInt('iqamahTimeAlertTime'),
      "announcementAlert": prefs.getBool('announcementAlert'),
    };

    data.forEach((key, value) async {
      if (value == null) {
        // Set SharedPreferences settings to defaults if never set by user
        if (settings[key] is int) {
          await prefs.setInt(key, settings[key]);
        } else if (settings[key] is bool) {
          await prefs.setBool(key, settings[key]);
        }
      } else {
        // Get the SharedPreferences settings set by user and set everything to match thier values
        setState(() => settings[key] = value);
      }
    });
  }

  // Update SharedPreferences values on any value change
  void updateValue(key, value) async {
    // Functions to run on value change
    if (key == "announcementAlert" && value is bool) AnnouncementsMessageService.toggleSubscription(value);
    // TODO: Add iqamah times implimentation
    
    // Set SharedPreferences and setState
    final prefs = await SharedPreferences.getInstance();
    if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else {
      return; // Prevent errors by writing as an incorrect type
    }
    setState(() => settings[key] = value);
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
                                    onPressed: () {
                                      _launchURL("mailto:kelowna.secretary@thebcma.com");
                                    }, 
                                    text: "Email Us"),
                                  const SizedBox(width: 30),
                                  RaisedGradientButton(
                                      onPressed: () {
                                        _launchURL("http://org.thebcma.com/kelowna");
                                      }, 
                                      text: "Website")
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
                    value: settings["iqamahTimeAlert"],
                    onChanged: (bool newValue) {
                      updateValue("iqamahTimeAlert", newValue);
                    },
                    secondary: const Icon(Icons.access_alarm_rounded),
                    title: const Text("Iqamaah Time Reminder")),
                  ListTile(
                    enabled: settings["iqamahTimeAlert"],
                    leading: const SizedBox(),
                    title: const Text("Time before Iqamaah"),
                    subtitle: const Text("How much time before Iqamaah should the app send a reminder?"),
                    trailing: DropdownButton<int>(
                      value: settings["iqamahTimeAlertTime"],
                      items: <int>[5, 10, 15, 20, 30, 45].map<DropdownMenuItem<int>>((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(value.toString() + " minutes"),
                          );
                        }).toList(),
                      onChanged: (settings["iqamahTimeAlert"]) ? (value) { 
                        updateValue("iqamahTimeAlertTime", value);
                      } : null
                    )),
                  SwitchListTile(
                      value: settings["announcementAlert"],
                      onChanged: (bool newValue) {
                        updateValue("announcementAlert", newValue);
                      },
                      secondary: const Icon(Icons.notification_important),
                      title: const Text("New Announcements Alert"))
                ]
      )));
}
