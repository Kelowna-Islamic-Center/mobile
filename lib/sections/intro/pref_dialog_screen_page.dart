import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:flutter_gen/gen_l10n/app_localizations.dart";

class PrefDialogScreenPage extends StatelessWidget {
  final VoidCallback incrementKey;
  final String text;
  final String prefKey;

  const PrefDialogScreenPage(
      {Key? key, required this.text, required this.prefKey, required this.incrementKey})
      : super(key: key);

  Future<void> updateValue(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, value);
    incrementKey();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Image(
                          image: AssetImage("assets/images/ic_launcher.png"),
                          width: 50,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppLocalizations.of(context)!.kelownaIslamicCenter,
                          style: const TextStyle(fontSize: 18),
                        )
                      ]),
                      const SizedBox(height: 25),
                      Text(
                        text,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 30),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        children: [
                          FilledButton(
                            onPressed: () {
                              updateValue(true);
                            },
                            child: Text(AppLocalizations.of(context)!.yes),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () {
                              updateValue(false);
                            },
                            child: Text(AppLocalizations.of(context)!.no),
                          )
                        ],
                      )
                    ],
                  ))
            ]));
  }
}
