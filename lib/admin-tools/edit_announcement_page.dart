import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../structs/announcement.dart';

class EditAnnouncementsPage extends StatefulWidget {
  final String announcementID;
  final Announcement announcement;
  const EditAnnouncementsPage({ Key? key, required this.announcementID, required this.announcement }) : super(key: key);

  @override
  EditAnnouncementsPageState createState() => EditAnnouncementsPageState();
}


class EditAnnouncementsPageState extends State<EditAnnouncementsPage> {

  String title = "";
  String description = "";
  bool loading = false;

  final _formKey = GlobalKey<FormState>();


  Future<Map<String, dynamic>> _updateAnnouncement() async {
    try {
      CollectionReference collection = FirebaseFirestore.instance.collection("announcements");
      
      await collection.doc(widget.announcementID).update({
        "title": title,
        "description": description
      });

      return {
        "success": true,
        "message": "Made changes successfully",
      };
    } catch (error) {
      return {
        "success": false,
        "message": "An error occured: $error",
      };
    }
  }


  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("Change an Announcement"),
    ),

    body: SingleChildScrollView(child: 
      Card(
        margin: const EdgeInsets.all(15.0),
        elevation: 3,
        child: Padding(padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Edit Announcement".toUpperCase(),
                style: const TextStyle(
                  fontSize: 20.0, 
                  fontWeight: FontWeight.bold)),

              const SizedBox(height: 10.0),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /* Email Address Field */
                    TextFormField(
                      initialValue: widget.announcement.title,
                      decoration: const InputDecoration(labelText: 'Enter Title'),
                      keyboardType: TextInputType.text,
                      onSaved: (String? value) => title = value!,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Title cannot be empty';
                        return null;
                      },
                    ),

                    /* Password Field */
                    TextFormField(
                      initialValue: widget.announcement.description,
                      decoration: const InputDecoration(labelText: 'Enter Description'),
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onSaved: (String? value) => description = value!,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Description cannot be empty';
                        return null;
                      },
                    ),
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          children: [
                            /* Submit Button */
                            ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  loading = true;
                                  _formKey.currentState!.save();

                                  Map<String, dynamic> auth = await _updateAnnouncement();
                                  loading = false;

                                  if (!context.mounted) return;
                                  
                                  if (auth["success"]) {
                                    Navigator.of(context).pop();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(auth["message"])),
                                    );
                                  }
                                }
                              },
                              child: const Text('Update Announcement'),
                            ),
                            const SizedBox(width: 20),
                            if (loading) const CircularProgressIndicator()
                          ],
                        ))
                  ],
                ),
              )
            ],
          ),
        ),
      )
    )
  );
}