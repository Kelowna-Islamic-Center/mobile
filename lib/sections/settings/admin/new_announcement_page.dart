import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";

import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:kelowna_islamic_center/config.dart";
import "package:multi_select_flutter/multi_select_flutter.dart";

class NewAnnouncementsPage extends StatefulWidget {
  const NewAnnouncementsPage({Key? key}) : super(key: key);

  @override
  NewAnnouncementsPageState createState() => NewAnnouncementsPageState();
}


class NewAnnouncementsPageState extends State<NewAnnouncementsPage> {
  
  String title = "";
  String description = "";
  List<String> platforms = [];
  bool loading = false;

  final _formKey = GlobalKey<FormState>();


  Future<Map<String, dynamic>> _addAnnouncement() async {
    Map<String, dynamic> data = {
      "title": title,
      "description": description,
      "platforms": platforms
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
        margin: const EdgeInsets.all(15),
        elevation: 3,
        child: Padding(padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    /* Email Address Field */
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.enterTitle,
                        border: const OutlineInputBorder(),
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
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.enterDescription,
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            /* Submit Button */
                            FilledButton(
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.done_rounded),
                                  const SizedBox(width: 10),
                                  Text(AppLocalizations.of(context)!.publishAnnouncement),
                                ],
                              )
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