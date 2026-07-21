import "package:flutter/material.dart";
import "package:kelowna_islamic_center/sections/announcements/announcements_controller.dart";

import "package:kelowna_islamic_center/structs/announcement.dart";
import "package:kelowna_islamic_center/l10n/app_localizations.dart";
import "package:multi_select_flutter/multi_select_flutter.dart";

class EditAnnouncementsPage extends StatefulWidget {
  final String announcementID;
  final Announcement announcement;
  const EditAnnouncementsPage(
      {super.key, required this.announcementID, required this.announcement});

  @override
  EditAnnouncementsPageState createState() => EditAnnouncementsPageState();
}

class EditAnnouncementsPageState extends State<EditAnnouncementsPage> {
  static const List<String> _supportedLocales = ["en", "ar"];

  late final Map<String, TextEditingController> _titleControllers;
  late final Map<String, TextEditingController> _descriptionControllers;
  List<String> platforms = [];
  bool loading = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _titleControllers = {
      for (final String locale in _supportedLocales)
        locale: TextEditingController(
          text: widget.announcement.l10n[locale]?["title"] ??
              (locale == "en" ? widget.announcement.title : ""),
        ),
    };

    _descriptionControllers = {
      for (final String locale in _supportedLocales)
        locale: TextEditingController(
          text: widget.announcement.l10n[locale]?["description"] ??
              (locale == "en" ? widget.announcement.description : ""),
        ),
    };

    platforms = List<String>.from(widget.announcement.platforms);
  }

  @override
  void dispose() {
    for (TextEditingController controller in _titleControllers.values) {
      controller.dispose();
    }
    for (TextEditingController controller in _descriptionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, Map<String, String>> _localizedPayload() {
    return {
      for (final String locale in _supportedLocales)
        locale: {
          "title": _titleControllers[locale]!.text,
          "description": _descriptionControllers[locale]!.text,
        }
    };
  }

  String _localeLabel(BuildContext context, String locale) {
    if (locale == "ar") {
      return AppLocalizations.of(context)!.arabicLanguage;
    }
    return AppLocalizations.of(context)!.englishLanguage;
  }

  Future<Map<String, dynamic>> _updateAnnouncement() async {
    if (!context.mounted) {
      return {"success": false, "message": "Failure"};
    }

    AppLocalizations localizedStrings = AppLocalizations.of(context)!;

    try {
      await AnnouncementsController.updateAnnouncement(
        announcementID: widget.announcementID,
        l10n: _localizedPayload(),
        platforms: platforms,
      );

      return {
        "success": true,
        "message": localizedStrings.successfullyUpdatedAnnouncement,
      };
    } catch (error) {
      return {
        "success": false,
        "message": localizedStrings.somethingWentWrong,
      };
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.changeAnAnnouncement),
      ),
      body: SingleChildScrollView(
          child: Card(
        margin: const EdgeInsets.all(15),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: DefaultTabController(
            length: _supportedLocales.length,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    for (final String locale in _supportedLocales)
                      Tab(text: _localeLabel(context, locale)),
                  ],
                ),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 320,
                        child: TabBarView(
                          children: [
                            for (final String locale in _supportedLocales)
                              SingleChildScrollView(
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _titleControllers[locale],
                                      decoration: InputDecoration(
                                        labelText: AppLocalizations.of(context)!
                                            .enterTitleForLanguage(
                                                _localeLabel(context, locale)),
                                        border: const OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.text,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return AppLocalizations.of(context)!
                                              .thisFieldIsRequired;
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 15),
                                    TextFormField(
                                      controller:
                                          _descriptionControllers[locale],
                                      decoration: InputDecoration(
                                        labelText: AppLocalizations.of(context)!
                                            .enterDescriptionForLanguage(
                                                _localeLabel(context, locale)),
                                        border: const OutlineInputBorder(),
                                        alignLabelWithHint: true,
                                      ),
                                      keyboardType: TextInputType.multiline,
                                      minLines: 5,
                                      maxLines: null,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return AppLocalizations.of(context)!
                                              .thisFieldIsRequired;
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                        decoration: BoxDecoration(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(5)),
                          border:
                              Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: MultiSelectDialogField<String>(
                          initialValue: widget.announcement.platforms,
                          dialogHeight: 2 * 60,
                          itemsTextStyle:
                              Theme.of(context).textTheme.bodyMedium,
                          selectedItemsTextStyle:
                              Theme.of(context).textTheme.bodyMedium,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!
                                  .thisFieldIsRequired;
                            }
                            return null;
                          },
                          buttonText: Text(
                              AppLocalizations.of(context)!.showOnPlatforms),
                          cancelText:
                              Text(AppLocalizations.of(context)!.cancel),
                          confirmText:
                              Text(AppLocalizations.of(context)!.confirm),
                          decoration: const BoxDecoration(),
                          buttonIcon: const Icon(Icons.arrow_drop_down_rounded),
                          items: [
                            MultiSelectItem<String>(
                              "web",
                              AppLocalizations.of(context)!.webPlatform,
                            ),
                            MultiSelectItem<String>(
                              "mobile",
                              AppLocalizations.of(context)!.mobilePlatform,
                            ),
                          ],
                          chipDisplay: MultiSelectChipDisplay(),
                          onConfirm: (List<String> selection) {
                            platforms = selection;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            FilledButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    loading = true;
                                  });

                                  Map<String, dynamic> auth =
                                      await _updateAnnouncement();

                                  if (!context.mounted) return;

                                  setState(() {
                                    loading = false;
                                  });

                                  if (auth["success"] as bool) {
                                    Navigator.of(context).pop();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text(auth["message"] as String)),
                                    );
                                  }
                                }
                              },
                              child: Text(AppLocalizations.of(context)!
                                  .updateAnnouncement),
                            ),
                            const SizedBox(width: 20),
                            if (loading) const CircularProgressIndicator(),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      )));
}
