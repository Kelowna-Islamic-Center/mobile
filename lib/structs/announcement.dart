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
      final timeStamp = json[i]["timeStamp"]!.seconds * 1000;

      parsedList.add(Announcement(
          timeStamp: timeStamp, // Set to timeStamp in milliseconds
          timeString: DateFormat.yMMMMd('en_US').format(DateTime.fromMillisecondsSinceEpoch(timeStamp)),
          title: json[i]['title'], 
          description: json[i]['description']
      ));
    }

    // Sort by the timeStamp on each announcement (Newest to Oldest)
    parsedList.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));

    return parsedList;
  }
}
