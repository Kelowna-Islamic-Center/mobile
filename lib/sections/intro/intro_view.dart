import "dart:io";

import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:kelowna_islamic_center/sections/home_screen_view.dart";
import "package:kelowna_islamic_center/sections/intro/alert_preferences_screen_page.dart";
import "package:kelowna_islamic_center/sections/intro/battery_optimization_screen_page.dart";
import "package:kelowna_islamic_center/sections/intro/completion_screen_page.dart";
import "package:kelowna_islamic_center/sections/intro/notifications_permission_screen_page.dart";
import "package:kelowna_islamic_center/sections/intro/welcome_screen_page.dart";

class IntroView extends StatefulWidget {
  const IntroView({super.key});

  @override
  State<IntroView> createState() => _IntroViewState();
}

class _IntroViewState extends State<IntroView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _nextPage() async {
    if (!_pageController.hasClients) {
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _completeIntro() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isIntroComplete", true);

    if (!mounted) {
      return;
    }

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreenView()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      WelcomeScreenPage(onContinue: _nextPage),
      AlertPreferencesScreenPage(onContinue: _nextPage),
      if (Platform.isAndroid) BatteryOptimizationScreenPage(onContinue: _nextPage),
      NotificationsPermissionScreenPage(onContinue: _nextPage),
      CompletionScreenPage(onFinish: _completeIntro),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (index) {
                  bool isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: isActive ? 24 : 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
