import "dart:async";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:skeletonizer/skeletonizer.dart";

import "package:kelowna_islamic_center/sections/prayer/prayer_controller.dart";
import "package:kelowna_islamic_center/structs/prayer_item.dart";
import "package:kelowna_islamic_center/theme/theme.dart";

import "package:flutter_gen/gen_l10n/app_localizations.dart";

class PrayerList extends StatefulWidget {
  final bool isAthanTimesActive;
  final bool isTodayActive;

  const PrayerList({Key? key, required this.isAthanTimesActive, required this.isTodayActive}) : super(key: key);

  @override
  State<PrayerList> createState() => _PrayerListState();
}

class _PrayerListState extends State<PrayerList> {

  Timer? timer;
  late Future<Map<String, dynamic>> fetchedData;

  final skeletonData = [
    PrayerItem(id: "loading", startTime: "00:00 AM", iqamahTime: "00:00 AM", name: "Prayer - \u0635\u0644\u0627\u062D "),
    PrayerItem(id: "loading", startTime: "00:00 AM", iqamahTime: "00:00 AM", name: "Prayer - \u0635\u0644\u0627\u062D "),
    PrayerItem(id: "loading", startTime: "00:00 AM", iqamahTime: "00:00 AM", name: "Prayer - \u0635\u0644\u0627\u062D "),
    PrayerItem(id: "loading", startTime: "00:00 AM", iqamahTime: "00:00 AM", name: "Prayer - \u0635\u0644\u0627\u062D "),
    PrayerItem(id: "loading", startTime: "00:00 AM", iqamahTime: "00:00 AM", name: "Prayer - \u0635\u0644\u0627\u062D "),
    PrayerItem(id: "loading", startTime: "00:00 AM", iqamahTime: "00:00 AM", name: "Prayer - \u0635\u0644\u0627\u062D "),
    PrayerItem(id: "loading", startTime: "00:00 AM", iqamahTime: "00:00 AM", name: "Prayer - \u0635\u0644\u0627\u062D ")
  ];

  Map<String, dynamic> _highlightedIndexes = {
    "iqamah": "...",
    "start": "..."
  }; // Selected prayerItem indexes that will be highlighted

  @override
  void initState() {
    super.initState();
    fetchedData = PrayerController.fetchPrayerTimes(); // Set to latest Prayer Times
    updateHighlightedPrayer();
    timer = Timer.periodic(
        const Duration(seconds: 20), (Timer t) => updateHighlightedPrayer());
  }

  @override
  void dispose() {
    super.dispose();
    timer!.cancel();
  }

  // Clock and highlight checker update
  void updateHighlightedPrayer() async {
    setState(() {
      fetchedData.then(
          (value) => _highlightedIndexes = PrayerController.getActivePrayer(value["data"]));
    });
  }

  bool isItemActive(int index) {
    return ((_highlightedIndexes["start"] == index && widget.isAthanTimesActive) ||
    (_highlightedIndexes["iqamah"] == index && !widget.isAthanTimesActive)) &&
    widget.isTodayActive;
  }

  @override
  Widget build(BuildContext context) => 
    SingleChildScrollView(
      child:
        // Prayer Items List
        FutureBuilder<Map<String, dynamic>>(
            future: fetchedData,
            builder: (context, snapshot) {
              // Set to either today or tomorrow's time based on user selection
              dynamic data = snapshot.hasData ?
              widget.isTodayActive
                  ? snapshot.data!["data"]
                  : snapshot.data!["dataForNextDay"]
              : skeletonData;

              return Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: Column(children: [
                /* Offline message if offline */
                if (snapshot.hasData)
                  if (snapshot.data!["timeStampDiff"] > 0)
                    Container(
                        margin:
                            const EdgeInsets.fromLTRB(15, 17, 15, 17),
                        child: SizedBox(
                        width: double.infinity,
                        child: Container(
                            padding: const EdgeInsets.fromLTRB(
                                15, 17, 15, 17),
                            decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(10),
                                color: Colors.yellow[800],
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black
                                          .withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2))
                                ]),
                            child: Row(children: [
                              const Icon(Icons.wifi_off_rounded,
                                  color: Colors.white, size: 35),
                              const SizedBox(width: 10),
                              Flexible(
                                  child: Text(
                                      AppLocalizations.of(context)!.timesOutdatedWarning(
                                        NumberFormat("###", 
                                          (AppLocalizations.of(context)!.localeName == "ar") ? "ar_EG" : AppLocalizations.of(context)!.localeName
                                        ).format(snapshot.data!["timeStampDiff"])
                                      ),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: 13)))
                            ])),
                      )),


                /* Prayer Times List */
                Skeletonizer(
                  enabled: !snapshot.hasData,
                  child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        // Set either athan or iqamah time based on user selection
                        String selectedTime = (widget.isAthanTimesActive)
                            ? data[index].startTime
                            : data[index].iqamahTime;

                        return ListTile(
                            minVerticalPadding: 4,
                            title: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: isItemActive(index)
                                      ? AppTheme.gradient
                                      : null,
                                  boxShadow: isItemActive(index)
                                      ? [
                                          BoxShadow(
                                              color: Colors.black45
                                                  .withOpacity(0.4),
                                              spreadRadius: 0,
                                              blurRadius: 3,
                                              offset:
                                                  const Offset(0, 1)),
                                        ]
                                      : null,
                                  image: isItemActive(index)
                                      ? const DecorationImage(
                                          image: AssetImage(
                                              "assets/images/pattern_bitmap.png"),
                                          repeat: ImageRepeat.repeat)
                                      : null,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(data[index].name,
                                        style: TextStyle(
                                            fontSize: 20,
                                            color: isItemActive(index)
                                                ? Colors.white
                                                : null)),
                                    Text(selectedTime,
                                        style: TextStyle(
                                            fontSize: 20,
                                            color: isItemActive(index)
                                                ? Colors.white
                                                : null)),
                                  ],
                                )));
                      } // Load as many prayer widgets as required
                      )
                )
              ]));
            })
      
    );
}
