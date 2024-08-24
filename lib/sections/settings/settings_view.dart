import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:provider/provider.dart';

import 'package:kelowna_islamic_center/sections/settings/admin/admin_page.dart';
import 'package:kelowna_islamic_center/sections/settings/admin/auth_guard.dart';
import 'package:kelowna_islamic_center/services/announcements/announcements_message_service.dart';
import 'package:kelowna_islamic_center/theme/theme.dart';
import 'package:kelowna_islamic_center/theme/theme_mode_provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  State<SettingsView> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsView> {

  final Map<String, dynamic> settings = {
    // Default Values
    "iqamahTimeAlert": true,
    "iqamahTimeAlertTime": 15,
    "athanTimeAlert": true,
    "announcementAlert": true,
  };

  final List<int> iqamahTimeValues = [5, 10, 15, 20, 30, 45];
  bool isNotificationsDisabled = false;

  @override
  void initState() {
    setToStoredValues();
    verifyNotificationPermissionStatus();
    super.initState();
  }

  void launchURL(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  Future<void> verifyNotificationPermissionStatus() async {
    isNotificationsDisabled = !(await Permission.notification.isGranted);
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
                child: Text(AppLocalizations.of(context)!.settings,
                    style: const TextStyle(fontSize: 30.0, color: Colors.white))),

            ListTile(
                leading: const Icon(Icons.dark_mode_rounded),
                title: Text(AppLocalizations.of(context)!.colorTheme),
                trailing: DropdownButton<String>(
                    value: Provider.of<ThemeModeProvider>(context).themeModeStringValue,
                    items: [
                      DropdownMenuItem<String>(
                          value: "Default",
                          child: Text(AppLocalizations.of(context)!.defaultTheme),
                        ),
                      DropdownMenuItem<String>(
                          value: "Light",
                          child: Text(AppLocalizations.of(context)!.lightTheme),
                        ),
                      DropdownMenuItem<String>(
                          value: "Dark",
                          child: Text(AppLocalizations.of(context)!.darkTheme),
                        )
                    ],
                    onChanged: (value) {
                      Provider.of<ThemeModeProvider>(context, listen: false).setThemeMode(value);
                    })),


            // Notifications Section
            ListTile(
                title: Text(AppLocalizations.of(context)!.notifications,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),

            // Disabled Notifications Card
            if (isNotificationsDisabled) ...{
              Container(
                  margin: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Card(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(15, 17, 15, 17),
                          child: Row(children: [
                            const Icon(Icons.notifications_off_rounded),
                            const SizedBox(width: 10.0),
                            Flexible(
                                child: Text(
                                    AppLocalizations.of(context)!.notificationsDisabledWarning,
                                    style: const TextStyle(fontWeight: FontWeight.bold)))
                          ]))),
                  )),
            },

            /* Iqamah Alert Settings (ANDROID ONLY) */
            if (Platform.isAndroid) ...[
              SwitchListTile(
                  value: settings["athanTimeAlert"],
                  onChanged: (bool newValue) {
                    updateValue("athanTimeAlert", newValue);
                  },
                  secondary: const Icon(Icons.timer_rounded),
                  title: Text(AppLocalizations.of(context)!.athanReminder),
                  subtitle: Text(AppLocalizations.of(context)!.athanReminderDescription)),

              SwitchListTile(
                  value: settings["iqamahTimeAlert"],
                  onChanged: (bool newValue) {
                    updateValue("iqamahTimeAlert", newValue);
                  },
                  secondary: const Icon(Icons.record_voice_over_rounded),
                  title: Text(AppLocalizations.of(context)!.iqamaahReminder),
                  subtitle: Text(AppLocalizations.of(context)!.iqamaahReminderDescription)),

              ListTile(
                  enabled: settings["iqamahTimeAlert"],
                  leading: const SizedBox(),
                  subtitle: Text(AppLocalizations.of(context)!.howManyMinutesBefore),
                  trailing: DropdownButton<int>(
                      value: settings["iqamahTimeAlertTime"],
                      items:
                        iqamahTimeValues.map<DropdownMenuItem<int>>((int value) {
                          final String locale = AppLocalizations.of(context)!.localeName;
                          final String localeWithCountry = (locale == "ar") ? "${locale}_EG" : locale;
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(
                              AppLocalizations.of(context)!.minutes(
                                NumberFormat("###", localeWithCountry).format(value))),
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
                title: Text(AppLocalizations.of(context)!.newAnnouncements),
                subtitle: Text(AppLocalizations.of(context)!.newAnnouncementsDescription)),

            // Info Section
            ListTile(
                title: Text(AppLocalizations.of(context)!.information,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15))),

            ListTile(
              title: Text(AppLocalizations.of(context)!.adminTools),
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
              title: Text(AppLocalizations.of(context)!.masjidWebsite),
              leading: const Icon(Icons.link),
              onTap: () => {launchURL("http://org.thebcma.com/kelowna")},
            ),

            ListTile(
              title: Text(AppLocalizations.of(context)!.emailAddress),
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
                        child: Row(children: [
                          const Icon(Icons.recommend, color: Colors.white, size: 35),
                          const SizedBox(width: 10.0),
                          Flexible(
                              child: Text(
                                  AppLocalizations.of(context)!.supportTheApp,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17)))
                        ])),
                  )),
            
    ])));
}
