import 'package:flutter/material.dart';

class PrayerEditor extends StatelessWidget {
  const PrayerEditor({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Center(child: SingleChildScrollView(child:
          // Prayer Times cant be changed from here anymore card
          Container(
            margin: const EdgeInsets.fromLTRB(15, 17, 15, 17),
            child: SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.fromLTRB(15, 17, 15, 17),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.yellow[800],
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2))]),
                child: 
                  const Row(
                    children: [
                      Icon(Icons.info, color: Colors.white, size: 35),
                      SizedBox(width: 15.0),
                      Flexible(child:
                        Text(
                          "Prayer Times can no longer be changed from here, please change them using the Kelowna BCMA Website.",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17)))
                    ]
                  )
              ),
          )),
        )));
}

