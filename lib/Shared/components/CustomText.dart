
// ignore_for_file: file_names

import 'package:flutter/material.dart';




class Customtext extends StatelessWidget {
  @override
  // ignore: override_on_non_overriding_member
  final String text;
  final double fontSize;

  final Color color;
  final Alignment alignment;

  final FontWeight fontWeight;

    // ignore: use_key_in_widget_constructors
    const Customtext(
      {     this.text='',
        this.fontSize =16,
        this.color = Colors.black,
        this.alignment =Alignment.topLeft,
         required this.fontWeight,
      });

  @override
  Widget build(BuildContext context) {

    return Container(
      alignment:  alignment ,
      child: Text(

        text,
        textDirection: TextDirection.rtl,



        style: TextStyle(
          fontFamily: "Schyler",

          color: color,
          fontSize: fontSize,
          fontWeight:fontWeight,
        ),
      ),
    );
  }
}