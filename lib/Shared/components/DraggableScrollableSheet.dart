// ignore_for_file: non_constant_identifier_names, file_names

import 'package:flutter/material.dart';

import 'CustomText.dart';
import '../constant.dart';

// ignore: camel_case_types
class customScrollableSheet extends StatelessWidget {
  const customScrollableSheet({Key? key,   required this.Text, required this.TextTitle, required this.function,}) : super(key: key);
 final String Text ;
 final String TextTitle;
 final  VoidCallback function;


  @override
  Widget build(BuildContext context) {
    return   DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        builder: (_, controller) => Container(
          decoration:const BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.vertical(
                  top:
                  Radius.circular(
                      20))),
          child: Padding(
            padding: const EdgeInsets.all(
                12.0),
            child: ListView(

              controller: controller,
              children: [
                Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed:function
                    ),
                    Customtext(
                      fontWeight:
                      FontWeight.bold,
                      alignment: Alignment
                          .centerRight,
                      color:mainColor,
                      text:TextTitle,
                      fontSize: 24,
                    ),
                  ],
                ),
                Customtext(
                  fontWeight:
                  FontWeight.normal,
                  alignment: Alignment
                      .centerRight,
                  color: Colors.black,
                  text:Text,
                  fontSize: 19,
                )
              ],
            ),
          ),
        ));
  }
}
