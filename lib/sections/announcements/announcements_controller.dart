import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kelowna_islamic_center/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kelowna_islamic_center/structs/announcement.dart';

class AnnouncementsController {

  static Future<Map<String, dynamic>> fetchAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final fbSnapshot = await FirebaseFirestore.instance
        .collection(Config.announcementCollection)
        .get(); // Firestore get (don't need realtime data)
    List<dynamic>? localJSON = prefs.getStringList('announcements');

    if (localJSON == null || !fbSnapshot.metadata.isFromCache) {
      await prefs.setStringList(
          'announcements',
          Announcement.toJsonStringFromList(
              Announcement.listFromJSON(fbSnapshot.docs)));
      localJSON = prefs.getStringList('announcements');
    }

    List<dynamic> parsedList = [];
    for (int i = 0; i < localJSON!.length; i++) {
      parsedList.add(jsonDecode(localJSON[i]));
    }

    return {
      "offline": fbSnapshot.metadata.isFromCache,
      "data": Announcement.listFromJSON(parsedList)
    };
  }
  
}