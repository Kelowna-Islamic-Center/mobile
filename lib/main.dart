import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kelowna_islamic_center/sections/announcement_section.dart';
import 'package:kelowna_islamic_center/sections/editor_section.dart';
import 'package:kelowna_islamic_center/sections/prayer_section.dart';
import 'package:kelowna_islamic_center/sections/settings_section.dart';
import 'package:kelowna_islamic_center/services/announcements_notification_service.dart';
import 'package:kelowna_islamic_center/services/iqamah_notification_service.dart';
import 'package:workmanager/workmanager.dart'; 

// WorkManager callbackDispatcher for handling background services
void callbackDispatcher() {
  final IqamahNotificationService iqamaahService = IqamahNotificationService();
  
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case IqamahNotificationService.taskUniqueName:
        await iqamaahService.scheduleNextNotification();
        break;
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AnnouncementsMessageService.init();
  await Firebase.initializeApp();

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  await IqamahNotificationService().initBackgroundService();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        canvasColor: Colors.white, // I'm sorry darkmode users (I'm lazy to impliment darkmode)
        brightness: Brightness.light, // I'm sorry darkmode users (I'm lazy to impliment darkmode)
        primarySwatch: Colors.green
      ),
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
      setState(() => {currentIndex = 1});
    }
  }


  final sections = const [
    PrayerPage(),
    AnnouncementsPage(),
    SettingsPage(),
    EditorPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: sections[currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: currentIndex,
        onTap: (index) => setState(() => {currentIndex = index}), 
        items: const [
            BottomNavigationBarItem(icon: Icon(Icons.access_time_filled), label: 'Prayer Times'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Announcements'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Admin Tools'),
        ]
      ),
    );
  }
}
