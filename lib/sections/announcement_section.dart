import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../structs/announcement.dart';

// TODO: Background checking service
// TODO: Fix overflow


Future<Map<String, dynamic>> announcementsFetch() async {
  final snapshot = await FirebaseFirestore.instance.collection('announcements').get(); // Firestore get (dont need realtime data)
  return {
    "offline": snapshot.metadata.isFromCache,
    "data": Announcement.listFromJSON(snapshot.docs)
  };
}


class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
          body: Column(children: [
        // Top Time Area
        Container(
            width: double.infinity,
            margin: const EdgeInsets.all(0.0),
            padding: const EdgeInsets.all(45.0),
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Colors.green,Colors.teal]),
                image: DecorationImage(
                    image: AssetImage('assets/images/pattern_bitmap.png'),
                    repeat: ImageRepeat.repeat)),
            child:
              Center(child: Text("Masjid Announcements".toUpperCase(),
                  style: const TextStyle(
                    fontSize: 21.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)
                  ))
            ),

        Expanded(
            child: Container(
                transform: Matrix4.translationValues(0.0, -10.0, 0.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(10.0))
                ),
                child:
                    // Prayer Items List
                    FutureBuilder<Map<String, dynamic>>(
                        future: announcementsFetch(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          List<Announcement> data = snapshot.data!["data"];

                          return Column(children: [
                            // Show offline message if offline
                            if (snapshot.data!["offline"])
                              Container(
                                  margin: const EdgeInsets.fromLTRB(15, 17, 15, 17),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Container(
                                        padding: const EdgeInsets.fromLTRB(15, 17, 15, 17),
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10.0),
                                            color: Colors.yellow[800],
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  spreadRadius: 1,
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2))
                                            ]),
                                        child: Row(children: const [
                                          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 35),
                                          SizedBox(width: 10.0),
                                          Flexible(
                                              child: Text(
                                                  "You are offline, these announcements may be old. Connect to the Internet to get the latest announcements.",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13)))
                                        ])),
                                  )),

                            ListView.separated(
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              itemCount: data.length,
                              separatorBuilder: (context, index) => Column(children: const [
                                SizedBox(height: 15),
                                Divider(thickness: 1, indent: 15, endIndent: 15)]),
                              itemBuilder: (context, index) {
                                // Announcement Item
                                return ListTile(
                                    visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                                    title: Container(
                                        padding: const EdgeInsets.fromLTRB(10, 17, 10, 10),
                                        child: Column(children: [
                                          Row(children: [
                                            Text(data[index].title,
                                              style: const TextStyle(
                                                  fontSize: 26,
                                                  letterSpacing: -1,
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w600))
                                          ]),
                                          const SizedBox(height: 12),
                                          Row(children: [
                                            const Icon(Icons.calendar_month, color: Colors.black87),
                                            const SizedBox(width: 5),
                                            Text(data[index].timeString,
                                                style: const TextStyle(fontSize: 15)),
                                          ]),
                                        ])),

                                    subtitle: Container(
                                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                                        child: Text(data[index].description,
                                            style: const TextStyle(fontSize: 15, color: Colors.black87))),
                                  );
                              }
                            )
                          ]);
                        })
                ))
      ]));
}