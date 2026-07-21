import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";
import "package:flutter_linkify/flutter_linkify.dart";
import "package:kelowna_islamic_center/config.dart";
import "package:kelowna_islamic_center/sections/announcements/announcements_controller.dart";
import "package:url_launcher/url_launcher_string.dart";

import "package:kelowna_islamic_center/sections/settings/admin/edit_announcement_page.dart";
import "package:kelowna_islamic_center/sections/settings/admin/new_announcement_page.dart";
import "package:kelowna_islamic_center/structs/announcement.dart";
import "package:kelowna_islamic_center/l10n/app_localizations.dart";

class AnnouncementsEditor extends StatefulWidget {
  const AnnouncementsEditor({super.key});

  @override
  AnnouncementsEditorState createState() => AnnouncementsEditorState();
}

class AnnouncementsEditorState extends State<AnnouncementsEditor> {

  void _navigateToAddAnnouncement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewAnnouncementsPage()),
    );
  }

  void _navigateToEditAnnouncement(String id, Announcement announcement) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditAnnouncementsPage(announcementID: id, announcement: announcement)),
    );
  }

  Future<void> _deleteAnnouncement(BuildContext context, String id) async {
    try {
      await AnnouncementsController.deleteAnnouncement(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.announcementDeleted)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.somethingWentWrong)),
      );
    }
  }

  Widget _deletionPopupDialog(BuildContext context, String deleteID) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.areYouSureYouWantToDelete),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            await _deleteAnnouncement(context, deleteID);
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Theme.of(context).colorScheme.onError)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
                tileColor: Theme.of(context).hoverColor,
                onTap: () => _navigateToAddAnnouncement(),
                title: Text(AppLocalizations.of(context)!.addAnnouncement,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.add)),
            StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection(Config.announcementCollection)
                    .orderBy("timeStamp", descending: true)
                    .snapshots(),
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  
                  if (snapshot.hasError) {
                    return Text(AppLocalizations.of(context)!.somethingWentWrong);
                  }
                  
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  List<Announcement> data = Announcement.listFromJSON(snapshot.data!.docs);

                  return ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        return _AnnouncementEditorCard(
                          announcement: data[index],
                          announcementID: snapshot.data!.docs[index].id,
                          onEdit: (String announcementID, Announcement announcement) {
                            _navigateToEditAnnouncement(announcementID, announcement);
                          },
                          onDelete: (String announcementID) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) =>
                                  _deletionPopupDialog(context, announcementID),
                            );
                          },
                        );
                      });
                })
          ],
        )));
}

class _AnnouncementEditorCard extends StatefulWidget {
  final Announcement announcement;
  final String announcementID;
  final void Function(String announcementID, Announcement announcement) onEdit;
  final void Function(String announcementID) onDelete;

  const _AnnouncementEditorCard({
    required this.announcement,
    required this.announcementID,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_AnnouncementEditorCard> createState() =>
      _AnnouncementEditorCardState();
}

class _AnnouncementEditorCardState extends State<_AnnouncementEditorCard> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _localeLabel(BuildContext context, String locale) {
    if (locale == "ar") {
      return AppLocalizations.of(context)!.arabicLanguage;
    }
    return AppLocalizations.of(context)!.englishLanguage;
  }

  @override
  Widget build(BuildContext context) {
    Announcement announcement = widget.announcement;
    String selectedLocale = _tabController.index == 1 ? "ar" : "en";

    String title = announcement.l10n[selectedLocale]?["title"] ?? announcement.title;
    String description = announcement.l10n[selectedLocale]?["description"] ?? announcement.description;

    return Card(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: _localeLabel(context, "en")),
                Tab(text: _localeLabel(context, "ar")),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                letterSpacing: -1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.calendar_month),
              const SizedBox(width: 10),
              Text(announcement.timeString,
                  style: const TextStyle(fontSize: 15)),
            ]),
            const SizedBox(height: 10),
            Linkify(
              onOpen: (link) async {
                if (await canLaunchUrlString(link.url)) {
                  await launchUrlString(link.url);
                } else {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            AppLocalizations.of(context)!.unableToOpenLink)),
                  );
                }
              },
              text: description,
              style: const TextStyle(fontSize: 14),
              linkStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                for (String platform in announcement.platforms)
                  Chip(
                    avatar: Icon(
                      (platform == "mobile")
                          ? Icons.smartphone_rounded
                          : Icons.desktop_windows_outlined,
                    ),
                    label: Text(
                      (platform == "mobile")
                          ? AppLocalizations.of(context)!.mobilePlatform
                          : (platform == "web")
                              ? AppLocalizations.of(context)!.webPlatform
                              : platform,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () =>
                      widget.onEdit(widget.announcementID, announcement),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit,
                          color: Theme.of(context).colorScheme.onSecondary),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context)!.edit,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: () => widget.onDelete(widget.announcementID),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete,
                          color: Theme.of(context).colorScheme.onError),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context)!.delete,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onError),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
