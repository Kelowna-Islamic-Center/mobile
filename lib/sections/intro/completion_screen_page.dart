import "package:flutter/material.dart";

import "package:flutter_gen/gen_l10n/app_localizations.dart";

class CompletionScreenPage extends StatelessWidget {

  const CompletionScreenPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
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
                children: [
                  // Icon(Icons.check_circle_outline_rounded, size: 70,),
                  const SizedBox(height: 25),
                  Text(
                    AppLocalizations.of(context)!.setupComplete,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                  ),
                ],
              ))
        ]));
  }
}
