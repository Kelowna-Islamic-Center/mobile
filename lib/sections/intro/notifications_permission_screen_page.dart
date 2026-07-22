import "dart:io";

import "package:flutter/material.dart";
import "package:kelowna_islamic_center/l10n/app_localizations.dart";
import "package:permission_handler/permission_handler.dart";
import "package:shared_preferences/shared_preferences.dart";

class NotificationsPermissionScreenPage extends StatefulWidget {
  final Future<void> Function() onContinue;

  const NotificationsPermissionScreenPage({super.key, required this.onContinue});

  @override
  State<NotificationsPermissionScreenPage> createState() =>
      _NotificationsPermissionScreenPageState();
}

class _NotificationsPermissionScreenPageState
    extends State<NotificationsPermissionScreenPage> {
  bool _requestPermissions = true;
  bool _isSubmitting = false;

  Future<void> _handleContinue() async {
    setState(() {
      _isSubmitting = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("requestNotificationPermissionsOnboardingChoice", _requestPermissions);

    if (_requestPermissions) {
      await Permission.notification.request();

      if (Platform.isAndroid) {
        await Permission.scheduleExactAlarm.request();
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });
    await widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
          child: ShaderMask(
        shaderCallback: (rect) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.transparent],
          ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
        },
        blendMode: BlendMode.dstIn,
        child: Container(
          decoration: const BoxDecoration(
              image: DecorationImage(
            image: AssetImage("assets/images/welcome_back.jpg"),
            fit: BoxFit.cover,
          )),
        ),
      )),
      Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Image(
                      image: AssetImage("assets/images/ic_launcher.png"),
                      width: 50,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.kelownaIslamicCenter,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  l10n.introNotificationsTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.introNotificationsDescription,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.introNotificationsToggleLabel),
                  subtitle: Text(l10n.introNotificationsToggleDescription),
                  value: _requestPermissions,
                  onChanged: (value) {
                    setState(() {
                      _requestPermissions = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _handleContinue,
                    child: Text(l10n.continueSetup),
                  ),
                ),
              ],
            ),
          )),
    ]);
  }
}