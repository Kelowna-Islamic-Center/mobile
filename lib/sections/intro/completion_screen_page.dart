import 'package:flutter/material.dart';

class CompletionScreenPage extends StatelessWidget {
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
              padding: EdgeInsets.all(20.0),
              child: const Column(
                children: [
                  // Icon(Icons.check_circle_outline_rounded, size: 70,),
                  SizedBox(height: 25),
                  Text(
                    "All done! Setup complete.",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0),
                  ),
                ],
              ))
        ]));
  }
}
