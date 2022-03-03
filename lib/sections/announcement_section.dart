import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// TODO: Offline functionality
// TODO: Background checking service
// Announcements data class
class Announcement {
  final String title;
  final String description;

  const Announcement({
    required this.title,
    required this.description
  });

  static listFromJSON(List<dynamic> json) {
    List<Announcement> parsedList = [];

    for (int i = 0; i < json.length; i++) {
      parsedList.add(Announcement(
        title: json[i]['title'], 
        description: json[i]['description']
      ));
    }
    return parsedList;
  }
}


Future<List<Announcement>> announcementsFetch() async {
  final snapshot = await FirebaseFirestore.instance.collection('announcements').get(); // Firestore get (dont need realtime data)
  return Announcement.listFromJSON(snapshot.docs);
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
              Center(child: Text("Announcements".toUpperCase(),
                  style: const TextStyle(
                    fontSize: 21.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)
                  ))
            ),

        Expanded(
            child: Container(
                transform: Matrix4.translationValues(0.0, -15.0, 0.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(15.0))
                ),
                child:
                    // Prayer Items List
                    FutureBuilder<List<Announcement>>(
                        future: announcementsFetch(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                          return ListView.separated(
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              itemCount: snapshot.data!.length,
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                // Announcement Item
                                return ListTile(
                                    visualDensity: const VisualDensity(horizontal: 0, vertical: -4),

                                    title: Container(
                                        padding: const EdgeInsets.fromLTRB(10, 17, 10, 10),
                                        child: Row(children: [
                                          const Icon(
                                            Icons.notifications, 
                                            color: Colors.black54),
                                          const SizedBox(
                                            width: 5),
                                          Text(snapshot.data![index].title,
                                            style: const TextStyle(
                                                fontFamily: 'Bebas',
                                                fontSize: 23,
                                                letterSpacing: 1.5,
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w600))
                                        ])),

                                    subtitle: Container(
                                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                                        child: Text(snapshot.data![index].description,
                                            style: const TextStyle(
                                                fontSize: 13)),
                                    ),
                                  );
                              }
                            );
                        })
                ))
      ]));
}