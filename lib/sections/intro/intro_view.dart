
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kelowna_islamic_center/sections/home_screen_view.dart';
import 'package:kelowna_islamic_center/sections/intro/completion_screen_page.dart';
import 'package:kelowna_islamic_center/sections/intro/pref_dialog_screen_page.dart';
import 'package:kelowna_islamic_center/sections/intro/welcome_screen_page.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        const WelcomeScreenPage(),
        PrefDialogScreenPage(
          text: AppLocalizations.of(context)!.introReceiveAthan,
          prefKey: "athanTimeAlert", 
          incrementKey: incrementIntroKey
        ),
        PrefDialogScreenPage(
          text: AppLocalizations.of(context)!.introReceiveIqamaah, 
          prefKey: "iqamahTimeAlert", 
          incrementKey: incrementIntroKey
        ),
        const CompletionScreenPage()
      ],
      showSkipButton: false,
      showNextButton: true,
      done: Text(AppLocalizations.of(context)!.finishSetup),
      next: Text(AppLocalizations.of(context)!.continueSetup),
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
