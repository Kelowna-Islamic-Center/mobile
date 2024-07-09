import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kelowna_islamic_center/admin/admin_page.dart';
import 'package:kelowna_islamic_center/admin/auth_guard.dart';
import 'package:kelowna_islamic_center/services/announcements_notification_service.dart';
import 'package:kelowna_islamic_center/theme/theme.dart';
import 'package:kelowna_islamic_center/theme/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsPage> {

  final Map<String, dynamic> settings = {
    // Default Values
    "iqamahTimeAlert": true,
    "iqamahTimeAlertTime": 15,
    "athanTimeAlert": true,
    "announcementAlert": true,
  };

  final List<int> iqamahTimeValues = [5, 10, 15, 20, 30, 45];
  final List<String> themeValues = ["Dark", "Light", "Default"];

  @override
  void initState() {
    setToStoredValues();
    super.initState();
  }

  void launchURL(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  // Set settings values to data stored in SharedPreferences
  void setToStoredValues() async {
    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> data = {
      "iqamahTimeAlert": prefs.getBool('iqamahTimeAlert'),
      "iqamahTimeAlertTime": prefs.getInt('iqamahTimeAlertTime'),
      "athanTimeAlert": prefs.getBool("athanTimeAlert"),
      "announcementAlert": prefs.getBool('announcementAlert')
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
    if (key == "announcementAlert" && value is bool) {
      AnnouncementsMessageService.toggleSubscription(value);
    }

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            
            // Top "Announcements" Title Header
            Container(
                width: double.infinity,
                margin: const EdgeInsets.all(0.0),
                padding: const EdgeInsets.fromLTRB(30.0, 60.0, 30.0, 20.0),
                decoration: const BoxDecoration(
                    gradient: AppTheme.gradient,
                    image: DecorationImage(
                        image: AssetImage('assets/images/pattern_bitmap.png'),
                        repeat: ImageRepeat.repeat)),
                child: const Text("Settings",
                    style: TextStyle(fontSize: 30.0, color: Colors.white))),

            ListTile(
                leading: Icon(Icons.dark_mode_rounded),
                title: const Text(
                    "Colour Theme"),
                trailing: DropdownButton<String>(
                    value: Provider.of<ThemeModeProvider>(context).themeModeStringValue,
                    items: 
                      themeValues.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    onChanged: (value) {
                      Provider.of<ThemeModeProvider>(context, listen: false).setThemeMode(value);
                    })),


            // Notifications Section
            const ListTile(
                title: Text("Notifications",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),


            /* Iqamah Alert Settings (ANDROID ONLY) */
            if (Platform.isAndroid) ...[
              SwitchListTile(
                  value: settings["athanTimeAlert"],
                  onChanged: (bool newValue) {
                    updateValue("athanTimeAlert", newValue);
                  },
                  secondary: const Icon(Icons.timer_rounded),
                  title: const Text("Athan Reminder"),
                  subtitle: const Text(
                      "Notification and Athan when it's Athan Time.")),

              SwitchListTile(
                  value: settings["iqamahTimeAlert"],
                  onChanged: (bool newValue) {
                    updateValue("iqamahTimeAlert", newValue);
                  },
                  secondary: const Icon(Icons.record_voice_over_rounded),
                  title: const Text("Iqamaah Reminder"),
                  subtitle: const Text(
                      "Notification a few minutes before Iqamah time at Masjid")),

              ListTile(
                  enabled: settings["iqamahTimeAlert"],
                  leading: const SizedBox(),
                  subtitle: const Text(
                      "How much time before Iqamaah the app sends a reminder"),
                  trailing: DropdownButton<int>(
                      value: settings["iqamahTimeAlertTime"],
                      items:
                        iqamahTimeValues.map<DropdownMenuItem<int>>((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text("$value minutes"),
                          );
                        }).toList(),
                      onChanged: (settings["iqamahTimeAlert"])
                          ? (value) {
                              updateValue("iqamahTimeAlertTime", value);
                            }
                          : null)),
            ],

            SwitchListTile(
                value: settings["announcementAlert"],
                onChanged: (bool newValue) {
                  updateValue("announcementAlert", newValue);
                },
                secondary: const Icon(Icons.notification_important_rounded),
                title: const Text("New Announcements"),
                subtitle:
                    const Text("Notifications on new Masjid Announcements")),

            // Info Section
            const ListTile(
                title: Text("Information",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15))),

            ListTile(
              title: const Text("Admin Tools"),
              leading: const Icon(Icons.admin_panel_settings),
              onTap: () => {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => 
                      (FirebaseAuth.instance.currentUser == null) 
                        ? const AdminAuthPage()
                        : const AdminPage()),
                )
              },
            ),

            ListTile(
              title: const Text("Masjid Website"),
              leading: const Icon(Icons.link),
              onTap: () => {launchURL("http://org.thebcma.com/kelowna")},
            ),

            ListTile(
              title: const Text("Email Address"),
              leading: const Icon(Icons.link),
              onTap: () => {launchURL("mailto:kelowna.secretary@thebcma.com")},
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
                            gradient: AppTheme.gradient,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2))
                            ],
                            image: const DecorationImage(
                                image: AssetImage(
                                    'assets/images/pattern_bitmap.png'),
                                repeat: ImageRepeat.repeat)),
                        child: const Row(children: [
                          Icon(Icons.recommend, color: Colors.white, size: 35),
                          SizedBox(width: 10.0),
                          Flexible(
                              child: Text(
                                  "Support this app by donating to the Masjid & leaving a review",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17)))
                        ])),
                  )),
            
    ])));
}
