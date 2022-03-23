import 'package:flutter/material.dart';
import 'package:kelowna_islamic_center/admin-tools/announcements_editor.dart';
import 'package:kelowna_islamic_center/admin-tools/prayer_editor.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({Key? key}) : super(key: key);

  // TODO: Add offline support

  @override
  Widget build(BuildContext context) => DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Tools"),
          bottom: const TabBar(tabs: [
            Tab(text: "Prayer Times"),
            Tab(text: "Announcements")
          ]),
        ),
        body: const TabBarView(children: [
          PrayerEditor(),
          AnnouncementsEditor()
        ])
      )
    );
}