import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:kelowna_islamic_center/sections/settings/admin/edit_announcement_page.dart';
import 'package:kelowna_islamic_center/sections/settings/admin/new_announcement_page.dart';
import 'package:kelowna_islamic_center/structs/announcement.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AnnouncementsEditor extends StatefulWidget {
  const AnnouncementsEditor({Key? key}) : super(key: key);

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
      await FirebaseFirestore.instance.collection('announcements').doc(id).delete();
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
              title: Text(AppLocalizations.of(context)!.addAnnouncement, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.add)
            ),
            StreamBuilder(
                stream: FirebaseFirestore.instance.collection('announcements').orderBy('timeStamp').snapshots(),
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  
                  if (snapshot.hasError) return Text(AppLocalizations.of(context)!.somethingWentWrong);
                  if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();

                  return ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        List<Announcement> data = Announcement.listFromJSON(snapshot.data!.docs);

                        return ListTile(
                            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                            title: Container(
                                padding: const EdgeInsets.fromLTRB(10, 17, 10, 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data[index].title,
                                        style: const TextStyle(
                                            fontSize: 26,
                                            letterSpacing: -1,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 12),
                                    Row(children: [
                                      const Icon(Icons.calendar_month),
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

                                    Linkify(
                                      onOpen: (link) async {
                                        if (await canLaunchUrlString(link.url)) {
                                          await launchUrlString(link.url);
                                        } else {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(AppLocalizations.of(context)!.unableToOpenLink)),
                                          );
                                        }
                                      },
                                      text: data[index].description,
                                      style: const TextStyle(fontSize: 14),
                                      linkStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),  
                                    ),

                                    const SizedBox(height: 25.0),
                                    
                                    Row(children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          int reversedIndex = (snapshot.data!.docs.length-1) - index;
                                          _navigateToEditAnnouncement(snapshot.data!.docs[reversedIndex].id, data[index]);
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.edit, color: Theme.of(context).colorScheme.onSecondary),
                                            const SizedBox(width: 10),
                                            Text(AppLocalizations.of(context)!.edit, style: TextStyle(color: Theme.of(context).colorScheme.onSecondary))
                                          ],
                                        )),

                                      const SizedBox(width: 15.0),

                                      ElevatedButton(
                                        onPressed: () {
                                          int reversedIndex = (snapshot.data!.docs.length-1) - index;
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) => _deletionPopupDialog(context, snapshot.data!.docs[reversedIndex].id),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
                                            const SizedBox(width: 10),
                                            Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Theme.of(context).colorScheme.onError))
                                          ],
                                        ))
                                    ],)
                                  ],
                                )));
                      });
                })
          ],
      )));
}
