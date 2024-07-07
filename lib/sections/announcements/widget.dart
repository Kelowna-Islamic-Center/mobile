import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:kelowna_islamic_center/sections/announcements/worker.dart';

import 'package:kelowna_islamic_center/structs/announcement.dart';
import 'package:url_launcher/url_launcher_string.dart';


class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Column(children: [
        // Top "Masjid Announcements" Header
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
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.all(Radius.circular(10.0))
                ),
                // Prayer Items List
                child: SingleChildScrollView(child:
                    FutureBuilder<Map<String, dynamic>>(
                        future: fetchAnnouncements(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(25.0), child: CircularProgressIndicator()));
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
                                        child: const Row(children: [
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
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: data.length,
                              separatorBuilder: (context, index) => const Column(children: [
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
                                                  fontWeight: FontWeight.w600))
                                          ]),
                                          const SizedBox(height: 12),
                                          Row(children: [
                                            const Icon(Icons.calendar_month),
                                            const SizedBox(width: 5),
                                            Text(data[index].timeString,
                                                style: const TextStyle(fontSize: 15)),
                                          ]),
                                        ])),

                                    subtitle: Container(
                                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                                        child: Linkify(
                                            onOpen: (link) async {
                                              if (await canLaunchUrlString(link.url)) {
                                                await launchUrlString(link.url);
                                              } else {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("Couldn't open link, something went wrong.")),
                                                );
                                              }
                                            },
                                            text: data[index].description,
                                            style: const TextStyle(fontSize: 14),
                                            linkStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),  
                                          )
                                        ),
                                  );
                              }
                            )
                          ]);
                        })
                )))
      ])
);}