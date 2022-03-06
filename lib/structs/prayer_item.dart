
class PrayerItem {
  final String startTime;
  final String iqamahTime;
  final String name;

  const PrayerItem(
      {required this.startTime, required this.iqamahTime, required this.name});

  static listFromFetchedJson(List<dynamic> json, [dynamic fsSnapshot]) {
    List<PrayerItem> parsedList = [];

    for (int i = 0; i < json.length; i++) {
      parsedList.add(PrayerItem(
          name: fsSnapshot != null ? fsSnapshot.docs[i]['name'] : json[i]['name'],
          startTime: json[i]['start'],
          iqamahTime: json[i]['timings']));
    }
    return parsedList;
  }

  static toJsonStringFromList(List<PrayerItem> list) {
    List<String> jsonList = [];

    for (int i = 0; i < list.length; i++) {
      jsonList.add('{"name":"' + list[i].name + '", "start":"' + list[i].startTime + '", "timings":"' + list[i].iqamahTime + '"}');
    }
    return jsonList;
  }
}
