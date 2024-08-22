
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:kelowna_islamic_center/sections/home_screen_view.dart';
import 'package:kelowna_islamic_center/sections/intro/completion_screen_page.dart';
import 'package:kelowna_islamic_center/sections/intro/pref_dialog_screen_page.dart';
import 'package:kelowna_islamic_center/sections/intro/welcome_screen_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroView extends StatefulWidget {
  const IntroView({Key? key}) : super(key: key);

  @override
  State<IntroView> createState() => _IntroViewState();
}

class _IntroViewState extends State<IntroView> {
  final key = GlobalKey<IntroductionScreenState>();

  void incrementIntroKey() {
    key.currentState?.next();
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      key: key,
      rawPages: [
        WelcomeScreenPage(),
        PrefDialogScreenPage(
          text: "Would you like to receive athan alarms?", 
          prefKey: "athanTimeAlert", 
          incrementKey: incrementIntroKey
        ),
        PrefDialogScreenPage(
          text: "Would you like to receive a notification a few minutes before Iqamaah at the Masjid?", 
          prefKey: "iqamahTimeAlert", 
          incrementKey: incrementIntroKey
        ),
        CompletionScreenPage()
      ],
      showSkipButton: false,
      showNextButton: true,
      done: const Text("Finish Setup ->"),
      next: const Text("Continue ->"),
      baseBtnStyle: const ButtonStyle(
        alignment: Alignment.centerRight
      ),
      skipOrBackFlex: 0,
      dotsFlex: 0,
      nextFlex: 1,
      onDone: () async {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool("isIntroDone", true);
        
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const HomeScreenView())
        );
      },
      curve: Curves.easeInOutCubic,
      animationDuration: 800,
    );
  }
}
