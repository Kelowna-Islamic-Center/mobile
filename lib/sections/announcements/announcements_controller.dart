import "dart:async";
import "dart:convert";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:kelowna_islamic_center/config.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:kelowna_islamic_center/structs/announcement.dart";

class AnnouncementsController {
  static String _firstNonEmpty(List<String?> candidates) {
    for (String? value in candidates) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return "";
  }

  static Map<String, Map<String, String>> _normalizeL10n(
      Map<String, Map<String, String>> rawL10n) {
    Map<String, Map<String, String>> normalized = {};

    rawL10n.forEach((locale, values) {
      String title = (values["title"] ?? "").trim();
      String description = (values["description"] ?? "").trim();

      if (title.isEmpty && description.isEmpty) {
        return;
      }

      normalized[locale] = {
        "title": title,
        "description": description,
      };
    });

    return normalized;
  }

  static Future<Map<String, dynamic>> fetchAnnouncements() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    QuerySnapshot<Map<String, dynamic>> fbSnapshot = await FirebaseFirestore
        .instance
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

  static Future<void> createAnnouncement({
    required Map<String, Map<String, String>> l10n,
    required List<String> platforms,
  }) async {
    Map<String, Map<String, String>> normalizedL10n = _normalizeL10n(l10n);

    if (normalizedL10n.isEmpty) {
      throw ArgumentError(
          "At least one locale must contain title or description.");
    }

    String fallbackTitle = _firstNonEmpty([
      normalizedL10n["en"]?["title"],
      normalizedL10n["ar"]?["title"],
    ]);

    String fallbackDescription = _firstNonEmpty([
      normalizedL10n["en"]?["description"],
      normalizedL10n["ar"]?["description"],
    ]);

    await FirebaseFirestore.instance
        .collection(Config.announcementCollection)
        .add({
      "title": fallbackTitle,
      "description": fallbackDescription,
      "platforms": platforms,
      "l10n": normalizedL10n,
    });
  }

  static Future<void> updateAnnouncement({
    required String announcementID,
    required Map<String, Map<String, String>> l10n,
    required List<String> platforms,
  }) async {
    Map<String, Map<String, String>> normalizedL10n = _normalizeL10n(l10n);

    if (normalizedL10n.isEmpty) {
      throw ArgumentError(
          "At least one locale must contain title or description.");
    }

    String fallbackTitle = _firstNonEmpty([
      normalizedL10n["en"]?["title"],
      normalizedL10n["ar"]?["title"],
    ]);

    String fallbackDescription = _firstNonEmpty([
      normalizedL10n["en"]?["description"],
      normalizedL10n["ar"]?["description"],
    ]);

    await FirebaseFirestore.instance
        .collection(Config.announcementCollection)
        .doc(announcementID)
        .update({
      "title": fallbackTitle,
      "description": fallbackDescription,
      "platforms": platforms,
      "l10n": normalizedL10n,
    });
  }

  static Future<void> deleteAnnouncement(String announcementID) async {
    await FirebaseFirestore.instance
        .collection(Config.announcementCollection)
        .doc(announcementID)
        .delete();
  }
}
