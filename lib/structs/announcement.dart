
class Announcement {
  final String title;
  final String description;

  const Announcement({ required this.title, required this.description });

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
