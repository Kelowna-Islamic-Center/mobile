import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kelowna_islamic_center/config.dart';

import 'package:kelowna_islamic_center/structs/announcement.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

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
  List<String> platforms = [];
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
        "description": description,
        "platforms": platforms
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
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.enterTitle,
                        border: const OutlineInputBorder()
                      ),
                      keyboardType: TextInputType.text,
                      onSaved: (String? value) => title = value!,
                      validator: (value) {
                        if (value == null || value.isEmpty) return AppLocalizations.of(context)!.thisFieldIsRequired;
                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    /* Password Field */
                    TextFormField(
                      initialValue: widget.announcement.description,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.enterDescription,
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true
                      ),
                      keyboardType: TextInputType.multiline,
                      minLines: 5,
                      maxLines: null,
                      onSaved: (String? value) => description = value!,
                      validator: (value) {
                        if (value == null || value.isEmpty) return AppLocalizations.of(context)!.thisFieldIsRequired;
                        return null;
                      },
                    ),


                    const SizedBox(height: 15),

                    Container(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(5)),
                        border: Border.all(
                            color: Theme.of(context).dividerColor)
                      ),
                      child: MultiSelectBottomSheetField(
                        initialValue: widget.announcement.platforms,
                        itemsTextStyle: Theme.of(context).textTheme.bodyMedium,
                        selectedItemsTextStyle: Theme.of(context).textTheme.bodyMedium,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        validator: (value) {
                          if (value == null || value.isEmpty) return AppLocalizations.of(context)!.thisFieldIsRequired;
                          return null;
                        },
                        buttonText: Text(AppLocalizations.of(context)!.showOnPlatforms),
                        cancelText: Text(AppLocalizations.of(context)!.cancel),
                        confirmText: Text(AppLocalizations.of(context)!.confirm),
                        decoration: const BoxDecoration(),
                        buttonIcon: const Icon(Icons.arrow_drop_down_rounded),
                        items: [
                          MultiSelectItem("web", AppLocalizations.of(context)!.webPlatform),
                          MultiSelectItem("mobile", AppLocalizations.of(context)!.mobilePlatform)
                        ],
                        chipDisplay: MultiSelectChipDisplay(), 
                        onConfirm: (List<dynamic> selection) {
                          platforms = List<String>.from(selection);
                        }, 
                      )
                    ),


                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          children: [
                            /* Submit Button */
                            FilledButton(
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