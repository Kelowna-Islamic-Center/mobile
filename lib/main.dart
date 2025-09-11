import "dart:io";

import "package:disable_battery_optimization/disable_battery_optimization.dart";
import "package:flutter/material.dart";
import "package:firebase_core/firebase_core.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:kelowna_islamic_center/firebase_options.dart";
import "package:kelowna_islamic_center/locales/locale_provider.dart";
import "package:kelowna_islamic_center/sections/intro/intro_view.dart";
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:workmanager/workmanager.dart";

import "package:kelowna_islamic_center/sections/home_screen_view.dart";
import "package:kelowna_islamic_center/theme/theme.dart";
import "package:kelowna_islamic_center/services/cloud_messaging_service.dart";
import "package:kelowna_islamic_center/services/api_fetch_service.dart";
import "package:kelowna_islamic_center/theme/theme_mode_provider.dart";

import "package:kelowna_islamic_center/l10n/app_localizations.dart";


// WorkManager callbackDispatcher for handling background services
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case ApiFetchService.taskUniqueName:
        await ApiFetchService.updateSharedPreferencesTimes();
    }

    return Future.value(true);
  });
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Firebase services
  await CloudMessagingService.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (Platform.isAndroid) {
    // Request Notification Permissions for Android 13+
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();

    // Request Auto Start Permission
    bool? isAutoStartEnabled = await DisableBatteryOptimization.isAutoStartEnabled;
    if (isAutoStartEnabled == true) {
      await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
    }

    // Request user to disable battery optimizations
    bool? isManBatteryOptimizationDisabled = await DisableBatteryOptimization.isManufacturerBatteryOptimizationDisabled;
    if (isManBatteryOptimizationDisabled == true) {
      await DisableBatteryOptimization.showDisableManufacturerBatteryOptimizationSettings(
          "Your device has battery optimization enabled.",
          "Please follow the steps and disable the optimizations to allow smooth functioning of this app");
    }
  }

  // Initialize app services
  await Workmanager().initialize(callbackDispatcher);
  await ApiFetchService.initBackgroundService();

  // Check if user has skipped the intro
  bool? isIntroDone = prefs.getBool("isIntroDone");
  isIntroDone ??= false;

  if (!isIntroDone) {
    await prefs.clear();
  }

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (context) => ThemeModeProvider(prefs: prefs),
      ),
      ChangeNotifierProvider(
        create: (context) => LocaleProvider(prefs: prefs),
      ),
    ],
    child: App(isIntroDone: isIntroDone),
  ));
}


class App extends StatelessWidget {

  final bool isIntroDone; 
  
  const App({super.key, required this.isIntroDone});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      // Localization
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Provider.of<LocaleProvider>(context).locale,
      // Theming
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: Provider.of<ThemeModeProvider>(context).themeMode,

      home: isIntroDone ? const HomeScreenView() : const IntroView(),
    );
  }
}