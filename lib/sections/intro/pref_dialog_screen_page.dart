import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefDialogScreenPage extends StatelessWidget {
  final VoidCallback incrementKey;
  final String text;
  final String prefKey;

  const PrefDialogScreenPage(
      {Key? key, required this.text, required this.prefKey, required this.incrementKey})
      : super(key: key);

  Future<void> updateValue(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(prefKey, value);
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
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Image(
                          image: AssetImage("assets/images/ic_launcher.png"),
                          width: 50.0,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Kelowna Islamic Center",
                          style: TextStyle(fontSize: 18),
                        )
                      ]),
                      const SizedBox(height: 25),
                      const Text(
                        "Would you like to receive a notification a few minutes before Iqamaah at the Masjid?",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 30.0),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        children: [
                          FilledButton(
                            onPressed: () {
                              updateValue(true);
                            },
                            child: const Text("Yes"),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () {
                              updateValue(false);
                            },
                            child: const Text("No"),
                          )
                        ],
                      )
                    ],
                  ))
            ]));
  }
}
