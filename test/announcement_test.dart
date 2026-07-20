import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter_test/flutter_test.dart";
import "package:kelowna_islamic_center/structs/announcement.dart";

void main() {
  test("parses localization data with nested dynamic values", () {
    List<Announcement> announcements = Announcement.listFromJSON([
      {
        "title": "Test title",
        "description": "Test description",
        "platforms": ["android"],
        "timeStamp": Timestamp.fromMillisecondsSinceEpoch(1700000000000),
        "l8n": {
          "en": {
            "title": "English title",
            "description": "English description",
            "extra": 1,
          },
        },
      },
    ]);

    expect(announcements, hasLength(1));
    expect(announcements.single.l8n["en"]?["title"], "English title");
    expect(announcements.single.l8n["en"]?["extra"], "1");
  });
}
