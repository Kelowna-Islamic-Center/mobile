import "package:cloud_firestore/cloud_firestore.dart";
import "package:intl/intl.dart";

class Announcement {
  final String title;
  final String description;
  final int timeStamp;
  final String timeString;
  final List<String> platforms;

  const Announcement({ required this.title, required this.description, required this.timeStamp, required this.platforms, this.timeString = "" });

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

      parsedList.add(Announcement(
          timeStamp: timeStamp, // Set to timeStamp in milliseconds
          timeString: parsedTimeString,
          title: parsedTitle, 
          description: parsedDescription,
          platforms: parsedPlatforms
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

      jsonList.add('{"title":"$parsedTitle", "description":"$parsedDescription", "platforms":["${list[i].platforms.join('","')}"], "timeStamp":"${list[i].timeStamp.toString()}"}');
    }
    
    return jsonList;
  }
}
