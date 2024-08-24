import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WelcomeScreenPage extends StatelessWidget {
  
  const WelcomeScreenPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.only(bottom: 80),
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
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Image(
                      image: AssetImage("assets/images/ic_launcher.png"),
                      width: 50.0,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)!.kelownaIslamicCenter,
                      style: const TextStyle(fontSize: 18),
                    )
                  ]),
                  const SizedBox(height: 25),
                  Text(
                    AppLocalizations.of(context)!.yourConnectionWithMasjid,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 45.0),
                  ),
                ],
              ))
        ]));
  }
}
