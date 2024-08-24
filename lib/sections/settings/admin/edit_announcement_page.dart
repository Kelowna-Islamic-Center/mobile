import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kelowna_islamic_center/config.dart';

import 'package:kelowna_islamic_center/structs/announcement.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

    if (!context.mounted) {
      return {
        "success": false,
        "message": "Failure"
      };
    }

    try {
      CollectionReference collection = FirebaseFirestore.instance.collection(Config.announcementCollection);
      
      await collection.doc(widget.announcementID).update({
        "title": title,
        "description": description
      });

      return {
        "success": true,
        "message": AppLocalizations.of(context)!.successfullyUpdatedAnnouncement,
      };
    } catch (error) {
      return {
        "success": false,
        "message": AppLocalizations.of(context)!.somethingWentWrong,
      };
    }
  }


  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(AppLocalizations.of(context)!.changeAnAnnouncement),
    ),

    body: SingleChildScrollView(child: 
      Card(
        margin: const EdgeInsets.all(15.0),
        elevation: 3,
        child: Padding(padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /* Email Address Field */
                    TextFormField(
                      initialValue: widget.announcement.title,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.enterTitle),
                      keyboardType: TextInputType.text,
                      onSaved: (String? value) => title = value!,
                      validator: (value) {
                        if (value == null || value.isEmpty) return AppLocalizations.of(context)!.thisFieldIsRequired;
                        return null;
                      },
                    ),

                    /* Password Field */
                    TextFormField(
                      initialValue: widget.announcement.description,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.enterDescription),
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onSaved: (String? value) => description = value!,
                      validator: (value) {
                        if (value == null || value.isEmpty) return AppLocalizations.of(context)!.thisFieldIsRequired;
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
                              child: Text(AppLocalizations.of(context)!.updateAnnouncement),
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