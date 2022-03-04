import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Shared/components/CustomText.dart';
import '../Shared/constant.dart';
import '../Shared/components/Widget.dart';

import 'cubit/State.dart';
import 'cubit/cubit.dart';

class Hadeeths extends StatelessWidget {
  const Hadeeths({Key? key, required this.id, required this.namecategory})
      : super(key: key);
  final String id;
  final String namecategory;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (BuildContext context) => AlmunirCubit()
          ..getCategories()
          ..getheadof(
            id,
          )
          ..Conection(),
        child: BlocConsumer<AlmunirCubit, almunir_state>(
            listener: (context, state) {},
            builder: (context, state) {
              var cubit = AlmunirCubit.get(context);
              return Scaffold(
                  appBar: AppBar(
                      backgroundColor: appbarColor,
                      title: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Customtext(
                          fontWeight: FontWeight.bold,
                          alignment: Alignment.centerRight,
                          color: Colors.white,
                          text: namecategory,
                          fontSize: 19,
                        ),
                      )),
                  body: hadeeths(cubit, id));
            }));
  }
}
