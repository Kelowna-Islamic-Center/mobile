import "dart:convert";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:intl/intl.dart";

class Announcement {
  final String title;
  final String description;
  final int timeStamp;
  final String timeString;
  final List<String> platforms;
  final Map<String, Map<String, String>> l10n;

  const Announcement({required this.title, required this.description, required this.timeStamp, required this.platforms, this.timeString = "", this.l10n = const {}});

  String localizedTimeString(String locale) {
    var normalizedLocale = locale.isEmpty ? "en_US" : locale.replaceAll("-", "_");
    return DateFormat.yMMMMd(normalizedLocale).format(DateTime.fromMillisecondsSinceEpoch(timeStamp));
  }

  static List<Announcement> listFromJSON(List<dynamic> json) {
    List<Announcement> parsedList = [];

    for (int i = 0; i < json.length; i++) {
      var item = (json[i] is QueryDocumentSnapshot)? json[i].data() : json[i];
      
      if (!(
        item.containsKey("timeStamp") || 
        item.containsKey("title") || 
        item.containsKey("description") ||
        item.containsKey("platforms")
        )) {
          return [];
      }
      
      if (item["timeStamp"] == null) {
        return [];
      }

      String parsedTitle = item["title"].replaceAll("\\n", "\n");
      String parsedDescription = item["description"].replaceAll("\\n", "\n");
      int timeStamp = (item["timeStamp"] is String) ? (int.tryParse(item["timeStamp"]!) ?? 0) : item["timeStamp"]!.seconds * 1000;
      String parsedTimeString = DateFormat.yMMMMd("en_US").format(DateTime.fromMillisecondsSinceEpoch(timeStamp));
      List<String> parsedPlatforms = List<String>.from(item["platforms"] as List);
      

      Map<String, Map<String, String>> parsedL10n = {};

      if (item["l10n"] != null && item["l10n"] is Map) {
        Map<dynamic, dynamic> rawL8n = item["l10n"] as Map<dynamic, dynamic>;
        
        // Map the raw l10n data from firestore or local storage to a Map<String, Map<String, String>> structure
        parsedL10n = rawL8n.map<String, Map<String, String>>((locale, values) {
          String localeKey = locale.toString();
          Map<dynamic, dynamic> rawValues = values is Map ? values : const <dynamic, dynamic>{};
          // Nested map of each locale's key-value pairs
          Map<String, String> normalizedValues = rawValues.map<String, String>((key, value) =>
            MapEntry(key.toString(), value?.toString() ?? "")
          );
          return MapEntry(localeKey, normalizedValues);
        });
      }

      parsedList.add(Announcement(
          timeStamp: timeStamp, // Set to timeStamp in milliseconds
          timeString: parsedTimeString,
          title: parsedTitle, 
          description: parsedDescription,
          platforms: parsedPlatforms,
          l10n: parsedL10n
      ));
    }

    // Sort by the timeStamp (Newest to Oldest)
    parsedList.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));

    return parsedList;
  }


  static List<String> toJsonStringFromList(List<Announcement> list) {
    List<String> jsonList = [];

    for (int i = 0; i < list.length; i++) {
      String parsedTitle = list[i].title.replaceAll("\n", "\\\\n");
      String parsedDescription = list[i].description.replaceAll("\n", "\\\\n");

      jsonList.add('{"title":"$parsedTitle", "description":"$parsedDescription", "platforms":["${list[i].platforms.join('","')}"], "timeStamp":"${list[i].timeStamp.toString()}", "l10n":${jsonEncode(list[i].l10n)}}');
    }
    
    return jsonList;
  }
}
