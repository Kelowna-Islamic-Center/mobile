import "package:flutter/material.dart";
import "package:kelowna_islamic_center/l10n/app_localizations.dart";

class WelcomeScreenPage extends StatelessWidget {
  final Future<void> Function() onContinue;

  const WelcomeScreenPage({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Image(
                      image: AssetImage("assets/images/ic_launcher.png"),
                      width: 45,
                    ),
                    const SizedBox(width: 15),
                    Text(
                      AppLocalizations.of(context)!.kelownaIslamicCenter,
                      style: const TextStyle(fontSize: 18),
                    )
                  ]),
                  const SizedBox(height: 25),
                  Text(
                    AppLocalizations.of(context)!.beginSetup,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 45),
                  ),
                  const SizedBox(height: 25),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: onContinue,
                      child: Text(AppLocalizations.of(context)!.continueSetup),
                    ),
                  ),
                ],
              ))
        ]));
  }
}
