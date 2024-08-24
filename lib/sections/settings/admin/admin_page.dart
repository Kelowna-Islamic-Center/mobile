import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kelowna_islamic_center/sections/settings/admin/announcements_editor.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.adminTools),
          actions: [
            PopupMenuButton(
              onSelected: (_) => {
                FirebaseAuth.instance.signOut().then((onValue) => {
                  Navigator.pop(context)
                })
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(
                    value: "logout",
                    child: Text(AppLocalizations.of(context)!.logout)
                  )
                ];
              }
            )
          ],
        ),
        body: const AnnouncementsEditor()
      )
    );
}