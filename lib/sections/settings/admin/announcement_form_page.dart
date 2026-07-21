import "package:flutter/material.dart";
import "package:kelowna_islamic_center/l10n/app_localizations.dart";
import "package:kelowna_islamic_center/sections/announcements/announcements_controller.dart";
import "package:kelowna_islamic_center/structs/announcement.dart";
import "package:multi_select_flutter/multi_select_flutter.dart";

class AnnouncementFormPage extends StatefulWidget {
  final String? announcementID;
  final Announcement? announcement;

  const AnnouncementFormPage({
    super.key,
    this.announcementID,
    this.announcement,
  }) : assert((announcementID == null && announcement == null) || (announcementID != null && announcement != null), "announcementID and announcement must both be provided for edit mode." );

  @override
  State<AnnouncementFormPage> createState() => _AnnouncementFormPageState();
}

class _AnnouncementFormPageState extends State<AnnouncementFormPage> {
  static const List<String> _supportedLocales = ["en", "ar"];

  late final Map<String, TextEditingController> _titleControllers;
  late final Map<String, TextEditingController> _descriptionControllers;

  List<String> platforms = [];
  bool loading = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool get _isEditing {
    return widget.announcementID != null && widget.announcement != null;
  }

  @override
  void initState() {
    super.initState();

    Announcement? announcement = widget.announcement;

    // Populate fields based on if its editing or creating a new announcement

    _titleControllers = {
      for (final String locale in _supportedLocales)
        locale: TextEditingController(
          text: announcement == null
              ? ""
              : (announcement.l10n[locale]?["title"] ??
                  (locale == "en" ? announcement.title : "")),
        ),
    };

    _descriptionControllers = {
      for (final String locale in _supportedLocales)
        locale: TextEditingController(
          text: announcement == null
              ? ""
              : (announcement.l10n[locale]?["description"] ??
                  (locale == "en" ? announcement.description : "")),
        ),
    };

    platforms = announcement == null ? <String>[] : List<String>.from(announcement.platforms);
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
        },
    };
  }

  String _localeLabel(BuildContext context, String locale) {
    if (locale == "ar") {
      return AppLocalizations.of(context)!.arabicLanguage;
    }
    return AppLocalizations.of(context)!.englishLanguage;
  }

  Future<Map<String, dynamic>> _submitAnnouncement() async {
    if (!context.mounted) {
      return {"success": false, "message": "Failure"};
    }

    AppLocalizations localizedStrings = AppLocalizations.of(context)!;

    try {
      if (_isEditing) {
        await AnnouncementsController.updateAnnouncement(
          announcementID: widget.announcementID!,
          l10n: _localizedPayload(),
          platforms: platforms,
        );
      } else {
        await AnnouncementsController.createAnnouncement(
          l10n: _localizedPayload(),
          platforms: platforms,
        );
      }

      return {
        "success": true,
        "message": _isEditing
            ? localizedStrings.successfullyUpdatedAnnouncement
            : localizedStrings.successfullyAddedAnnouncement,
      };
    } catch (error) {
      return {
        "success": false,
        "message": localizedStrings.somethingWentWrong,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations strings = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? strings.changeAnAnnouncement
            : strings.addAnnouncement),
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
                      mainAxisAlignment: MainAxisAlignment.start,
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
                                          labelText:
                                              strings.enterTitleForLanguage(
                                            _localeLabel(context, locale),
                                          ),
                                          border: const OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.text,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return strings.thisFieldIsRequired;
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 15),
                                      TextFormField(
                                        controller:
                                            _descriptionControllers[locale],
                                        decoration: InputDecoration(
                                          labelText: strings.enterDescriptionForLanguage(
                                            _localeLabel(context, locale),
                                          ),
                                          alignLabelWithHint: true,
                                          border: const OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.multiline,
                                        minLines: 5,
                                        maxLines: null,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return strings.thisFieldIsRequired;
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
                            border: Border.all(
                                color: Theme.of(context).dividerColor),
                          ),
                          child: MultiSelectDialogField<String>(
                            initialValue: platforms,
                            dialogHeight: 2 * 90,
                            itemsTextStyle: Theme.of(context).textTheme.bodyMedium,
                            selectedItemsTextStyle: Theme.of(context).textTheme.bodyMedium,
                            selectedColor: Theme.of(context).colorScheme.primary,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return strings.thisFieldIsRequired;
                              }
                              return null;
                            },
                            buttonText: Text(strings.showOnPlatforms),
                            cancelText: Text(strings.cancel),
                            confirmText: Text(strings.confirm),
                            decoration: const BoxDecoration(),
                            buttonIcon:
                                const Icon(Icons.arrow_drop_down_rounded),
                            items: [
                              MultiSelectItem<String>("web", strings.webPlatform),
                              MultiSelectItem<String>("mobile", strings.mobilePlatform),
                            ],
                            chipDisplay: MultiSelectChipDisplay(),
                            onConfirm: (List<String> selection) {
                              setState(() {
                                platforms = selection;
                              });
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

                                    Map<String, dynamic> result = await _submitAnnouncement();

                                    if (!context.mounted) return;

                                    setState(() {
                                      loading = false;
                                    });

                                    if (result["success"] as bool) {
                                      Navigator.of(context).pop();
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(result["message"] as String),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!_isEditing) ...[
                                      const Icon(Icons.done_rounded),
                                      const SizedBox(width: 10),
                                    ],
                                    Text(
                                      _isEditing
                                          ? strings.updateAnnouncement
                                          : strings.publishAnnouncement,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              if (loading) const CircularProgressIndicator(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
