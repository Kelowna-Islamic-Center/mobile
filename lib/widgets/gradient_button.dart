import 'package:flutter/material.dart';
import 'package:kelowna_islamic_center/theme.dart';

class RaisedGradientButton extends StatelessWidget {
  final double? width;
  final double height;
  final Gradient gradient;
  final VoidCallback? onPressed;
  final String text;
  final bool enabled;

  const RaisedGradientButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.width,
    this.height = 36.0,
    this.gradient = AppTheme.gradient,
    this.enabled = true
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: enabled ?
      BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ) : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.fromLTRB(35, 0, 35, 0),
        ),
        child: Text(text.toUpperCase(), style: TextStyle(
          fontWeight: FontWeight.normal,
          letterSpacing: 1.5,
          fontSize: 12.0,
          color: enabled ? Colors.white : null
        )),
      ),
    );
  }
}
