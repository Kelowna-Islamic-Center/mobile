import "dart:async";
import "dart:convert";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:kelowna_islamic_center/config.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:kelowna_islamic_center/structs/announcement.dart";

class AnnouncementsController {

  static Future<Map<String, dynamic>> fetchAnnouncements() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    QuerySnapshot<Map<String, dynamic>> fbSnapshot = await FirebaseFirestore.instance
        .collection(Config.announcementCollection)
        .where("platforms", arrayContains: "mobile")
        .get();

    List<dynamic>? localJSON = prefs.getStringList("announcements");

    if (localJSON == null || !fbSnapshot.metadata.isFromCache) {
      await prefs.setStringList(
          "announcements",
          Announcement.toJsonStringFromList(
              Announcement.listFromJSON(fbSnapshot.docs)));
      localJSON = prefs.getStringList("announcements");
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