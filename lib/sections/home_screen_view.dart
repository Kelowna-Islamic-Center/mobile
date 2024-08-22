import 'package:auto_start_flutter/auto_start_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kelowna_islamic_center/config.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

import 'package:kelowna_islamic_center/sections/announcements/announcements_view.dart';
import 'package:kelowna_islamic_center/sections/prayer/prayer_view.dart';
import 'package:kelowna_islamic_center/sections/settings/settings_view.dart';


class HomeScreenView extends StatefulWidget {
  const HomeScreenView({Key? key}) : super(key: key);

  @override
  State<HomeScreenView> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreenView> {
  int currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    requestPermissions();
    setupNotificationInteractions();
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
    if (message.from == "/topics/${Config.announcementTopic}") {
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
