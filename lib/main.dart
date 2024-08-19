import 'dart:io';

import 'package:auto_start_flutter/auto_start_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kelowna_islamic_center/theme/theme.dart';
import 'package:kelowna_islamic_center/sections/announcements/announcements_view.dart';
import 'package:kelowna_islamic_center/sections/prayer/prayer_view.dart';
import 'package:kelowna_islamic_center/sections/settings/settings_view.dart';
import 'package:kelowna_islamic_center/services/announcements/announcements_message_service.dart';
import 'package:kelowna_islamic_center/services/prayer/prayer_notification_service.dart';
import 'package:kelowna_islamic_center/services/api/api_fetch_service.dart';
import 'package:kelowna_islamic_center/theme/theme_mode_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart'; 
import 'package:alarm/alarm.dart';


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

  final prefs = await SharedPreferences.getInstance();

  // Firebase Services
  await AnnouncementsMessageService.init();
  await Firebase.initializeApp();

  // App Services
  // Workmanager tasks are android only for the time being
  if (Platform.isAndroid) {
    await Alarm.init();

    await Workmanager().initialize(callbackDispatcher);

    await ApiFetchService.initBackgroundService();
    await PrayerNotificationService.initBackgroundService();
  }

  runApp(ChangeNotifierProvider(
    create: (context) => ThemeModeProvider(prefs: prefs),
    child: const App(),
  ));
}

class App extends StatelessWidget {
  
  const App({Key? key}) : super(key: key);


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: Provider.of<ThemeModeProvider>(context).themeMode,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    setupNotificationInteractions();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    // Notification and alarm requests
    await Permission.notification.isDenied.then((value) {
      if (value) {
        Permission.notification.request();
      }
    });

    await Permission.scheduleExactAlarm.isDenied.then((value) {
      if (value) {
        Permission.scheduleExactAlarm.request();
      }
    });

    // Permission to allow Athan Alarms to wake android phones
    await getAutoStartPermission();
  }

  // Notification click handler
  Future<void> setupNotificationInteractions() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _navigateToAnnouncements(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_navigateToAnnouncements);
  }

  void _navigateToAnnouncements(RemoteMessage message) {
    if (message.from == "/topics/announcements") {
      setState(() => currentIndex = 1);
    }
  }


  final sections = const [
    PrayerView(),
    AnnouncementsView(),
    SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: sections[currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index), 
        items: const [
            BottomNavigationBarItem(icon: Icon(Icons.mosque_rounded), label: 'Prayer Times'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'Announcements'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ]
      ),
    );
  }
}
