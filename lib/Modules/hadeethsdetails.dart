
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';




import '../Shared/constant.dart';
import '../Shared/components/Widget.dart';

import 'cubit/State.dart';
import 'cubit/cubit.dart';

// ignore: must_be_immutable, camel_case_types
class Hadeethsdetails extends StatelessWidget {
  const Hadeethsdetails({Key? key, required this.id}) : super(key: key);
  final String id;


  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (BuildContext context) => AlmunirCubit()..getdetails(id),
        child: BlocConsumer<AlmunirCubit, almunir_state>(
            listener: (context, state) {},
            builder: (context, state) {
              var cubit = AlmunirCubit.get(context);
              return Scaffold(
                appBar: AppBar(
                  backgroundColor: appbarColor,
                ),
                body: hadeethsdetails(cubit),
              );
            }));
  }
}
