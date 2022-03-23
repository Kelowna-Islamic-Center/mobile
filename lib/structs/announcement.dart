import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Announcement {
  final String title;
  final String description;
  final int timeStamp;
  final String timeString;

  const Announcement({ required this.title, required this.description, required this.timeStamp, this.timeString = "" });

  static listFromJSON(List<dynamic> json) {
    List<Announcement> parsedList = [];

    for (int i = 0; i < json.length; i++) {

      final item = (json[i] is QueryDocumentSnapshot)? json[i].data() : json[i];
      if (!(item.containsKey("timeStamp") || item.containsKey("title") || item.containsKey("description"))) return;
      
      if (item["timeStamp"] == null) return;
      final timeStamp = (item["timeStamp"] is String) ? (int.tryParse(item["timeStamp"]!) ?? 0) : item["timeStamp"]!.seconds * 1000;

      parsedList.add(Announcement(
          timeStamp: timeStamp, // Set to timeStamp in milliseconds
          timeString: DateFormat.yMMMMd('en_US').format(DateTime.fromMillisecondsSinceEpoch(timeStamp)),
          title: item['title'], 
          description: item['description']
      ));
    }

    // Sort by the timeStamp on each announcement (Newest to Oldest)
    parsedList.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));

    return parsedList;
  }

  static toJsonStringFromList(List<Announcement> list) {
    List<String> jsonList = [];

    for (int i = 0; i < list.length; i++) {
      jsonList.add('{"title":"' + list[i].title + '", "description":"' + list[i].description + '", "timeStamp":"' + list[i].timeStamp.toString() + '"}');
    }
    return jsonList;
  }
}
