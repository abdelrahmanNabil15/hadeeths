// ignore_for_file: file_names, prefer_const_constructors, non_constant_identifier_names

import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../Shared/components/CustomText.dart';

import '../Shared/components/Widget.dart';

import 'cubit/State.dart';
import 'cubit/cubit.dart';

class HadeethsCategory extends StatelessWidget {
  const HadeethsCategory({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (BuildContext context) =>
        AlmunirCubit()
          ..getCategories()
          ..Conection(),
        child: BlocConsumer<AlmunirCubit, almunir_state>(
            listener: (context, state) {},
            builder: (context, state) {
              var cubit = AlmunirCubit.get(context);
              return Scaffold(
                  appBar: AppBar(
                      backgroundColor: Color.fromARGB(100, 241, 224, 172),
                      title: Customtext(
                        fontWeight: FontWeight.bold,
                        alignment: Alignment.center,
                        color: Colors.white,
                        text: "الأحاديث النبوية",
                        fontSize: 19,
                      )),
                  body: state is! isnotcectedstate
                  ? hadeethsCategory(cubit)
                          : RefreshIndicator( onRefresh:cubit.refreshMain,
                      child: SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: Center(
                            child:
                            Text("You are disconnected from the internet."),
                          ))
                  ));
            }));
  }
}
