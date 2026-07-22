import "package:flutter/material.dart";
import "package:kelowna_islamic_center/config.dart";
import "package:kelowna_islamic_center/l10n/app_localizations.dart";
import "package:kelowna_islamic_center/sections/settings/settings_controller.dart";
import "package:shared_preferences/shared_preferences.dart";

class AlertPreferencesScreenPage extends StatefulWidget {
  final Future<void> Function() onContinue;

  const AlertPreferencesScreenPage({super.key, required this.onContinue});

  @override
  State<AlertPreferencesScreenPage> createState() =>
      _AlertPreferencesScreenPageState();
}

class _AlertPreferencesScreenPageState extends State<AlertPreferencesScreenPage> {
  bool _athanEnabled = true;
  bool _iqamahEnabled = true;
  bool _didTouchAthanToggle = false;
  bool _didTouchIqamahToggle = false;
  bool _isSaving = false;

  Future<void> _persistAlertPreference(String key, bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    await SettingsController.subscriptionHandler(key, value);
  }

  Future<void> _persistIqamahAlertTimeDefault() async {
    int defaultIqamahAlertTime = Config.defaultSettings["iqamahTimeAlertTime"] as int;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt("iqamahTimeAlertTime", defaultIqamahAlertTime);
    await SettingsController.subscriptionHandler("iqamahTimeAlertTime", defaultIqamahAlertTime);
  }

  Future<void> _saveAndContinue() async {
    setState(() {
      _isSaving = true;
    });

    // Persist explicit defaults when the user continues without touching toggles.
    bool savedAthanValue = _didTouchAthanToggle ? _athanEnabled : true;
    bool savedIqamahValue = _didTouchIqamahToggle ? _iqamahEnabled : true;

    await _persistAlertPreference("athanTimeAlert", savedAthanValue);
    await _persistAlertPreference("iqamahTimeAlert", savedIqamahValue);
    await _persistIqamahAlertTimeDefault();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
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
                  l10n.introAlertsTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.introAlertsDescription,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.introAthanToggleLabel),
                  subtitle: Text(l10n.introAthanToggleDescription),
                  value: _athanEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _didTouchAthanToggle = true;
                      _athanEnabled = value;
                    });

                    await _persistAlertPreference("athanTimeAlert", value);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.introIqamahToggleLabel),
                  subtitle: Text(l10n.introIqamahToggleDescription),
                  value: _iqamahEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _didTouchIqamahToggle = true;
                      _iqamahEnabled = value;
                    });

                    await _persistAlertPreference("iqamahTimeAlert", value);
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveAndContinue,
                    child: Text(l10n.continueSetup),
                  ),
                ),
              ],
            ),
          )),
    ]);
  }
}