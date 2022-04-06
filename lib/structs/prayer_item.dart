
class PrayerItem {
  final String startTime;
  final String iqamahTime;
  final String name;

  const PrayerItem(
      {required this.startTime, required this.iqamahTime, required this.name});

  static listFromFetchedJson(List<dynamic> json) {
    List<PrayerItem> parsedList = [];

    for (int i = 0; i < json.length; i++) {
      parsedList.add(PrayerItem(
          name: json[i]['name'],
          startTime: json[i]['start'],
          iqamahTime: json[i]['iqamah']));
    }
    return parsedList;
  }

  static toJsonStringFromList(List<PrayerItem> list) {
    List<String> jsonList = [];

    for (int i = 0; i < list.length; i++) {
      jsonList.add('{"name":"' + list[i].name + '", "start":"' + list[i].startTime + '", "iqamah":"' + list[i].iqamahTime + '"}');
    }
    return jsonList;
  }
}
