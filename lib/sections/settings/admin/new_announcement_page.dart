import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kelowna_islamic_center/config.dart';

class NewAnnouncementsPage extends StatefulWidget {
  const NewAnnouncementsPage({Key? key}) : super(key: key);

  @override
  NewAnnouncementsPageState createState() => NewAnnouncementsPageState();
}


class NewAnnouncementsPageState extends State<NewAnnouncementsPage> {
  
  String title = "";
  String description = "";
  bool loading = false;

  final _formKey = GlobalKey<FormState>();


  Future<Map<String, dynamic>> _addAnnouncement() async {
    Map<String, dynamic> data = {
      "title": title,
      "description": description
    };

    if (!context.mounted) {
      return {
        "success": false,
        "message": "Failure"
      };
    }

    try {
      await FirebaseFirestore.instance.collection(Config.announcementCollection).add(data);
      return {
        "success": true,
        "message": AppLocalizations.of(context)!.successfullyAddedAnnouncement,
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
      title: Text(AppLocalizations.of(context)!.addAnnouncement),
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

                                  Map<String, dynamic> auth = await _addAnnouncement();
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
                              child: Text(AppLocalizations.of(context)!.addAnnouncement),
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