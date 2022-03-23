import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kelowna_islamic_center/structs/announcement.dart';

class AnnouncementsEditor extends StatelessWidget {
  const AnnouncementsEditor({Key? key}) : super(key: key);

  // TODO: Add error and success messages
  void _removeAnnouncement(String id) {
    final collection = FirebaseFirestore.instance.collection('announcements');
    collection
        .doc(id)
        .delete()
        .then((value) => print('Deleted'))
        .catchError((error) => print('Delete failed: $error'));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
          child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: ElevatedButton(
                onPressed: () => false, child: const Text("Add Announcement")),
          ),
          StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('timeStamp')
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) return const Text('Error... Something went wrong.');
                if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      dynamic data = Announcement.listFromJSON(snapshot.data!.docs);

                      if (data != null) {
                        return ListTile(
                            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                            title: Container(
                                padding: const EdgeInsets.fromLTRB(10, 17, 10, 10),
                                child: Column(children: [
                                  Row(children: [
                                    Text(data[index].title,
                                        style: const TextStyle(
                                            fontSize: 26,
                                            letterSpacing: -1,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600))
                                  ]),
                                  const SizedBox(height: 12),
                                  Row(children: [
                                    const Icon(Icons.calendar_month, color: Colors.black87),
                                    const SizedBox(width: 5),
                                    Text(data[index].timeString,
                                        style: const TextStyle(fontSize: 15)),
                                  ]),
                                ])),
                            subtitle: Container(
                                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data[index].description,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.black87)),
                                    const SizedBox(height: 10.0),
                                    ElevatedButton(
                                        onPressed: () {
                                          int reversedIndex = (snapshot.data!.docs.length-1) - index;
                                          _removeAnnouncement(snapshot.data!.docs[reversedIndex].id);
                                        },
                                        style: ElevatedButton.styleFrom(primary: Colors.red),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.delete),
                                            Text("Delete")
                                          ],
                                        ))
                                  ],
                                )));
                      } else {
                        return const SizedBox(height: 1.0);
                      }
                    });
              })
        ],
      )));
}
