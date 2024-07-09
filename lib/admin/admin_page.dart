import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kelowna_islamic_center/admin/announcements_editor.dart';
import 'package:kelowna_islamic_center/admin/prayer_editor.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Tools"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Prayer Times"),
              Tab(text: "Announcements")
          ]),
          actions: [
            PopupMenuButton(
              onSelected: (_) => {
                FirebaseAuth.instance.signOut().then((onValue) => {
                  Navigator.pop(context)
                })
              },
              itemBuilder: (BuildContext context) {
                return [ "Logout" ].map((String choice) {
                  return PopupMenuItem(
                    value: choice,
                    child: Text(choice)
                  );
                }).toList();
              }
            )
          ],
        ),
        body: const TabBarView(children: [
          PrayerEditor(),
          AnnouncementsEditor()
        ])
      )
    );
}