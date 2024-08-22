import 'package:flutter/material.dart';

class WelcomeScreenPage extends StatelessWidget {
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
              padding: EdgeInsets.all(20.0),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
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
                  SizedBox(height: 25),
                  Text(
                    "Your Connection with the Masjid",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 45.0),
                  ),
                ],
              ))
        ]));
  }
}
