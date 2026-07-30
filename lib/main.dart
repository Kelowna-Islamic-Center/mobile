import "package:flutter/material.dart";
import "package:firebase_core/firebase_core.dart";
import "package:kelowna_islamic_center/firebase_options.dart";
import "package:kelowna_islamic_center/locales/locale_provider.dart";
import "package:kelowna_islamic_center/sections/intro/intro_view.dart";
import "package:kelowna_islamic_center/services/prayer_alert_scheduler_service.dart";
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
      case PrayerAlertSchedulerService.taskUniqueName:
        await PrayerAlertSchedulerService.reconcileSchedules(fromBackground: true);
      case ApiFetchService.taskUniqueName:
        await ApiFetchService.updateSharedPreferencesTimes();
        await PrayerAlertSchedulerService.reconcileSchedules(
          fromBackground: true,
          force: true,
        );
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

  // Initialize app services
  await Workmanager().initialize(callbackDispatcher);
  await ApiFetchService.initBackgroundService();
  await PrayerAlertSchedulerService.initBackgroundService();
  await ApiFetchService.updateSharedPreferencesTimes();
  await PrayerAlertSchedulerService.reconcileIfNativeDirty();
  await PrayerAlertSchedulerService.reconcileSchedules(force: true);

  // Check if user has skipped the intro
  bool? isIntroComplete = prefs.getBool("isIntroV2Complete");
  isIntroComplete ??= false;

  if (!isIntroComplete) {
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
    child: App(isIntroComplete: isIntroComplete),
  ));
}


class App extends StatefulWidget {

  final bool isIntroComplete; 
  
  const App({super.key, required this.isIntroComplete});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      PrayerAlertSchedulerService.reconcileIfNativeDirty();
      PrayerAlertSchedulerService.reconcileSchedules();
    }
  }

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

      home: widget.isIntroComplete ? const HomeScreenView() : const IntroView(),
    );
  }
}