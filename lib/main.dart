import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kelowna_islamic_center/sections/announcement_section.dart';
import 'package:kelowna_islamic_center/sections/editor_section.dart';
import 'package:kelowna_islamic_center/sections/prayer_section.dart';
import 'package:kelowna_islamic_center/sections/settings_section.dart';
import 'package:kelowna_islamic_center/services/cms_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  CloudMessagingService();
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

  final sections = const [
    PrayerPage(),
    AnnouncementsPage(),
    EditorPage(),
    SettingsPage()
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
            BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Make Changes'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ]
      ),
    );
  }
}
