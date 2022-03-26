import 'package:flutter/material.dart';

class NewAnnouncementsPage extends StatelessWidget {
  const NewAnnouncementsPage({Key? key}) : super(key: key);

  // TODO: Add offline support

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("Add an Announcement"),
    ),

    body: const Text("Work")
  );
}