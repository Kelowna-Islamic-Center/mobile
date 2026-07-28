import "dart:async";
import "dart:io";

import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:permission_handler/permission_handler.dart";
import "package:url_launcher/url_launcher_string.dart";
import "package:provider/provider.dart";

import "package:kelowna_islamic_center/sections/settings/admin/admin_page.dart";
import "package:kelowna_islamic_center/sections/settings/admin/auth_guard.dart";
import "package:kelowna_islamic_center/theme/theme.dart";
import "package:kelowna_islamic_center/theme/theme_mode_provider.dart";
import "package:kelowna_islamic_center/locales/locale_provider.dart";
import "package:kelowna_islamic_center/sections/settings/settings_controller.dart";
import "package:kelowna_islamic_center/config.dart";
import "package:kelowna_islamic_center/services/prayer_alert_scheduler_service.dart";

import "package:kelowna_islamic_center/l10n/app_localizations.dart";

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsView> {
  
  late SettingsController controller;

  Map<String, dynamic> settings = Config.defaultSettings;
  final List<int> iqamahTimeValues = [5, 10, 15, 20, 30, 45];
  bool isNotificationsDisabled = false;

  @override
  void initState() {
    controller = SettingsController(onSettingsChanged: (newSettings) {
      setState(() => settings = Map.from(newSettings));
    });

    controller.init();
    _verifyNotificationPermissionStatus();
    super.initState();
  }

  void launchURL(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  Future<void> _verifyNotificationPermissionStatus() async {
    PermissionStatus status = await Permission.notification.status;
    setState(() {
      isNotificationsDisabled = !status.isGranted;
    });
  }

  void _showExactAlarmDeniedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.exactAlarmPermissionRequired),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.openSettings,
          onPressed: () {
            openAppSettings();
          },
        ),
      ),
    );
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
                margin: const EdgeInsets.all(0),
                padding: const EdgeInsets.fromLTRB(30, 60, 30, 20),
                decoration: const BoxDecoration(
                    gradient: AppTheme.gradient,
                    image: DecorationImage(
                        image: AssetImage("assets/images/pattern_bitmap.png"),
                        repeat: ImageRepeat.repeat)),
                child: Text(AppLocalizations.of(context)!.settings,
                    style: const TextStyle(fontSize: 30, color: Colors.white))),

            ListTile(
                leading: const Icon(Icons.dark_mode_rounded),
                title: Text(AppLocalizations.of(context)!.colorTheme),
                trailing: DropdownButton<String>(
                    value: Provider.of<ThemeModeProvider>(context).themeModeStringValue,
                    items: [
                      DropdownMenuItem<String>(
                          value: null,
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

            ListTile(
                leading: const Icon(Icons.language),
                title: Text(AppLocalizations.of(context)!.appLanguage),
                trailing: DropdownButton<String>(
                    value: Provider.of<LocaleProvider>(context).localeStringValue,
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(AppLocalizations.of(context)!.defaultLanguage),
                      ),
                      for (Locale locale in context.findAncestorWidgetOfExactType<MaterialApp>()!.supportedLocales)
                        DropdownMenuItem<String>(
                            value: locale.languageCode,
                            child: Text(lookupAppLocalizations(locale).localeFullName),
                          ),
                    ],
                    onChanged: (value) {
                      Provider.of<LocaleProvider>(context, listen: false).setLocale(value);
                    })),

            // Calculation Method
            ListTile(
              leading: const Icon(Icons.mosque),
              title: Text(AppLocalizations.of(context)!.calculationMethod),
              trailing: DropdownButton<String>(
                value: settings["calculationMethod"],
                items: [
                  DropdownMenuItem<String>(
                    value: "hanafi",
                    child: Text(AppLocalizations.of(context)!.hanafi),
                  ),
                  DropdownMenuItem<String>(
                    value: "hanbali",
                    child: Text(AppLocalizations.of(context)!.hanbaliShafiMaliki),
                  )
                ],
                onChanged: (value) {
                  controller.updateValue("calculationMethod", value);
                })),

            ListTile(
              leading: const Icon(Icons.launch_rounded),
              title: Text(AppLocalizations.of(context)!.timesToShowOnAppLaunch),
              trailing: DropdownButton<int>(
                value: settings["launchDefaultIndex"],
                items: [
                  DropdownMenuItem<int>(
                    value: 0,
                    child: Text(AppLocalizations.of(context)!.iqamahTimes),
                  ),
                  DropdownMenuItem<int>(
                    value: 1,
                    child: Text(AppLocalizations.of(context)!.athanTimes),
                  )
                ],
                onChanged: (value) {
                  controller.updateValue("launchDefaultIndex", value);
                })),


            // Notifications Section
            ListTile(
                title: Text(AppLocalizations.of(context)!.notifications,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),

            // Disabled Notifications Card
            if (isNotificationsDisabled && Platform.isAndroid) ...{
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
                            const SizedBox(width: 10),
                            Flexible(
                                child: Text(
                                    AppLocalizations.of(context)!.notificationsDisabledWarning,
                                    style: const TextStyle(fontWeight: FontWeight.bold)))
                          ]))),
                  )),
            },

            /* Iqamah Alert Settings */
            SwitchListTile(
                value: settings["athanTimeAlert"] ?? false,
                onChanged: (bool newValue) async {
                  bool applied = await controller.updateValue("athanTimeAlert", newValue);
                  if (!applied && context.mounted) {
                    _showExactAlarmDeniedMessage();
                  }
                },
                secondary: const Icon(Icons.timer_rounded),
                title: Text(AppLocalizations.of(context)!.athanReminder),
                subtitle: Text(AppLocalizations.of(context)!.athanReminderDescription)),

            SwitchListTile(
                value: settings["iqamahTimeAlert"] ?? false,
                onChanged: (bool newValue) {
                  controller.updateValue("iqamahTimeAlert", newValue);
                },
                secondary: const Icon(Icons.record_voice_over_rounded),
                title: Text(AppLocalizations.of(context)!.iqamaahReminder),
                subtitle: Text(AppLocalizations.of(context)!.iqamaahReminderDescription)),

            ListTile(
                enabled: settings["iqamahTimeAlert"] ?? false,
                leading: const SizedBox(),
                subtitle: Text(AppLocalizations.of(context)!.howManyMinutesBefore),
                trailing: DropdownButton<int>(
                    value: settings["iqamahTimeAlertTime"],
                    items:
                      iqamahTimeValues.map<DropdownMenuItem<int>>((int value) {
                        String locale = AppLocalizations.of(context)!.localeName;
                        String localeWithCountry = (locale == "ar") ? "${locale}_EG" : locale;
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(
                            AppLocalizations.of(context)!.minutes(
                              NumberFormat("###", localeWithCountry).format(value))),
                        );
                      }).toList(),
                    onChanged: (settings["iqamahTimeAlert"])
                        ? (value) {
                            controller.updateValue("iqamahTimeAlertTime", value);
                          }
                        : null)),

            SwitchListTile(
                value: settings["announcementAlert"] ?? false,
                onChanged: (bool newValue) {
                  controller.updateValue("announcementAlert", newValue);
                },
                secondary: const Icon(Icons.notification_important_rounded),
                title: Text(AppLocalizations.of(context)!.newAnnouncements),
                subtitle: Text(AppLocalizations.of(context)!.newAnnouncementsDescription)),

            if (Platform.isAndroid)
              ListTile(
                enabled: settings["athanTimeAlert"] ?? false,
                leading: const Icon(Icons.play_circle_fill_rounded),
                title: const Text("Test Athan Alert"),
                subtitle: const Text("Play Athan now using the Android alarm service"),
                onTap: (settings["athanTimeAlert"] ?? false)
                    ? () async {
                        await PrayerAlertSchedulerService.triggerTestAthanAlert(
                          title: AppLocalizations.of(context)!.athanReminder,
                          body: AppLocalizations.of(context)!.athanReminderDescription,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Running Athan test now")),
                          );
                        }
                      }
                    : null,
              ),

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
              title: Text(AppLocalizations.of(context)!.sourceCode),
              subtitle: Text(AppLocalizations.of(context)!.appIsOpenSource),
              leading: const Icon(Icons.code),
              onTap: () => {launchURL("https://github.com/Kelowna-Islamic-Center")}
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
                            borderRadius: BorderRadius.circular(10),
                            gradient: AppTheme.gradient,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withAlpha((0.4 * 255).round()),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2))
                            ],
                            image: const DecorationImage(
                                image: AssetImage(
                                    "assets/images/pattern_bitmap.png"),
                                repeat: ImageRepeat.repeat)),
                        child: Row(children: [
                          const Icon(Icons.recommend, color: Colors.white, size: 35),
                          const SizedBox(width: 10),
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
