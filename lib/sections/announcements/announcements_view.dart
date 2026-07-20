import "package:flutter/material.dart";
import "package:flutter_linkify/flutter_linkify.dart";
import "package:skeletonizer/skeletonizer.dart";
import "package:url_launcher/url_launcher_string.dart";

import "package:kelowna_islamic_center/theme/theme.dart";
import "package:kelowna_islamic_center/structs/announcement.dart";
import "package:kelowna_islamic_center/sections/announcements/announcements_controller.dart";

import "package:kelowna_islamic_center/l10n/app_localizations.dart";

class AnnouncementsView extends StatelessWidget {
  const AnnouncementsView({super.key});
  
  // Data to use for skeleton loader
  final List<Announcement> skeletonData = const [
    Announcement(title: "Loading...", description: "This announcement is currently being loaded and this is just dummy datat", timeStamp: 0, timeString: "March 20, 2000", platforms: []),
    Announcement(title: "Loading...", description: "This announcement is currently being loaded and this is just dummy datat", timeStamp: 0, timeString: "March 20, 2000", platforms: []),
    Announcement(title: "Loading...", description: "This announcement is currently being loaded and this is just dummy datat", timeStamp: 0, timeString: "March 20, 2000", platforms: [])
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
      body: SingleChildScrollView(child:
        Column(children: [
          // Top "Announcements" Title Header
          Container(
              width: double.infinity,
              margin: const EdgeInsets.all(0),
              padding: const EdgeInsets.fromLTRB(30, 50, 30, 30),
              decoration: const BoxDecoration(
                  gradient: AppTheme.gradient,
                  image: DecorationImage(
                      image: AssetImage("assets/images/pattern_bitmap.png"),
                      repeat: ImageRepeat.repeat)),
              child:
                Text(AppLocalizations.of(context)!.announcementsTitle,
                    style: const TextStyle(
                      fontSize: 30,
                      color: Colors.white)
                    )
              ),

          Container(
              transform: Matrix4.translationValues(0, -10, 0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.all(Radius.circular(10))
              ),
              // Prayer Items List
              child: FutureBuilder<Map<String, dynamic>>(
                  future: AnnouncementsController.fetchAnnouncements(),
                  builder: (context, snapshot) {
                    List<Announcement> data = skeletonData;

                    if (snapshot.hasData) {
                      data = snapshot.data!["data"];
                    }

                    return Column(children: [
                      // Show offline message if offline
                      if (snapshot.hasData)
                        if (snapshot.data!["offline"])
                          Container(
                              margin: const EdgeInsets.fromLTRB(15, 17, 15, 17),
                              child: SizedBox(
                                width: double.infinity,
                                child: Container(
                                    padding: const EdgeInsets.fromLTRB(15, 17, 15, 17),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.yellow[800],
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.black.withAlpha((0.2 * 255).round()),
                                              spreadRadius: 1,
                                              blurRadius: 4,
                                              offset: const Offset(0, 2))
                                        ]),
                                    child: Row(children: [
                                      const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 35),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          AppLocalizations.of(context)!.outdatedAnnouncementsWarning,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)))
                                    ])),
                              )),


                      Skeletonizer (
                        enabled: !snapshot.hasData,
                        child: ListView.separated(
                              scrollDirection: Axis.vertical,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: data.length,
                              separatorBuilder: (context, index) =>
                                  const Column(children: [
                                    SizedBox(height: 15),
                                    Divider(
                                        thickness: 1,
                                        indent: 15,
                                        endIndent: 15)
                                  ]),
                              itemBuilder: (context, index) {
                                Announcement item = data[index];
                                String locale = AppLocalizations.of(context)!.localeName;
                                
                                String title = item.l8n[locale]?["title"] ?? item.title;
                                String description = item.l8n[locale]?["description"] ?? item.description;
                                String displayTimeString = snapshot.hasData
                                  ? item.localizedTimeString(locale)
                                  : item.timeString;
                                
                                // Check for legacy announcements that might not be translated to the current locale
                                bool isEnglishOnly = locale != "en"
                                  && item.l8n[locale]?["title"] == null 
                                  && item.l8n[locale]?["description"] == null;
                                
                                // Announcement Item
                                return ListTile(
                                  title: Container(
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 17, 10, 10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(title,
                                              style: const TextStyle(
                                                  fontSize: 26,
                                                  letterSpacing: -1,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                          const SizedBox(height: 5),

                                          if (snapshot.hasData && isEnglishOnly)
                                            Chip(
                                              avatar: const Icon(Icons.warning, color: Colors.white),
                                              label: Text(
                                                AppLocalizations.of(context)!.thisAnnouncementIsNotAvaiableInThisLanguage,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13)
                                                ),
                                              backgroundColor: Colors.yellow[800],
                                              side: const BorderSide(color: Colors.transparent)
                                            ),
                                          
                                          Chip(
                                            avatar: const Icon(Icons.event),
                                            label: Text(displayTimeString),
                                          ),
                                      ])),
                                  subtitle: Container(
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 0, 10, 8),
                                      child: Linkify(
                                        onOpen: (link) async {
                                          if (await canLaunchUrlString(
                                              link.url)) {
                                            await launchUrlString(
                                                link.url);
                                          } else {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      AppLocalizations.of(context)!.errorCouldntOpenLink)),
                                            );
                                          }
                                        },
                                        text: description,
                                        style:
                                            const TextStyle(fontSize: 16),
                                        linkStyle: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      )),
                                );
                              })
                      )
                    ]);
                  })
              )
        ])
  ));
}