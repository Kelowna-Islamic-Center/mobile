import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kelowna_islamic_center/firebase_options.dart';
import 'package:kelowna_islamic_center/sections/intro/intro_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart'; 
import 'package:alarm/alarm.dart';

import 'package:kelowna_islamic_center/sections/home_screen_view.dart';
import 'package:kelowna_islamic_center/theme/theme.dart';
import 'package:kelowna_islamic_center/services/announcements/announcements_message_service.dart';
import 'package:kelowna_islamic_center/services/prayer/prayer_notification_service.dart';
import 'package:kelowna_islamic_center/services/api/api_fetch_service.dart';
import 'package:kelowna_islamic_center/theme/theme_mode_provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';


// WorkManager callbackDispatcher for handling background services
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case PrayerNotificationService.taskUniqueName:
        await PrayerNotificationService.scheduleNextNotifications();
        break;
      case ApiFetchService.taskUniqueName:
        await ApiFetchService.updateSharedPreferencesTimes();
        break;
    }

    return Future.value(true);
  });
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Firebase services
  await AnnouncementsMessageService.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  

  // Initialize app services
  // Workmanager tasks are android only for the time being
  if (Platform.isAndroid) {
    await Alarm.init();
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    await ApiFetchService.initBackgroundService();
    await PrayerNotificationService.initBackgroundService();
  }

  // Check if user has skipped the intro
  bool? isIntroDone = prefs.getBool("isIntroDone");
  isIntroDone ??= false;

  runApp(ChangeNotifierProvider(
    create: (context) => ThemeModeProvider(prefs: prefs),
    child: App(isIntroDone: isIntroDone),
  ));
}


class App extends StatelessWidget {

  final bool isIntroDone; 
  
  const App({Key? key, required this.isIntroDone}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      // Localization
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Theming
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: Provider.of<ThemeModeProvider>(context).themeMode,

      home: (isIntroDone) ? const HomeScreenView() : const IntroView(),
    );
  }
}