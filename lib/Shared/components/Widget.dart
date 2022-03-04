// ignore_for_file: file_names, non_constant_identifier_names

import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loadmore/loadmore.dart';
import 'package:share/share.dart';

import '../../Modules/hadeethsdetails.dart';
import 'CustomText.dart';
import 'DraggableScrollableSheet.dart';

import '../constant.dart';
import '../../Modules/hadeeths.dart';


Widget hadeethsCategory(cubit)=>ConditionalBuilder(
  condition: cubit.Categories.length > 0,
  builder: (context) =>
      Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage("assets/backgruond.jpg"),
              fit: BoxFit.cover),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Customtext(
                    fontWeight: FontWeight.bold,
                    alignment: Alignment.centerRight,
                    color: Colors.black,
                    text: "التصنيفات الرئيسية",
                    fontSize: 30,
                  ),
                ),
                GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        childAspectRatio: 3 / 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20),
                    physics:
                    const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return Container(
                        alignment: Alignment.center,
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromARGB(
                                  100, 238, 231, 225),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: Offset(0,
                                  3), // changes position of shadow
                            ),
                          ],
                          border: Border.all(
                            color: const Color.fromARGB(
                                100, 245, 218, 176),
                            width: 0.7,
                          ),
                          borderRadius:
                          BorderRadius.circular(15),
                          color: Colors.white60,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    Hadeeths(
                                        namecategory: cubit
                                            .Categories
                                            .isNotEmpty
                                            ? cubit
                                            .Categories[
                                        index]['title']
                                            : "",
                                        id: cubit
                                            .Categories[
                                        index]["id"] ??
                                            1),
                              ),
                            );
                          },
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Center(
                                child: Customtext(
                                  fontWeight:
                                  FontWeight.bold,
                                  alignment:
                                  Alignment.center,
                                  color: Colors.black,
                                  text: cubit.Categories
                                      .isNotEmpty
                                      ? cubit.Categories[
                                  index]['title']
                                      : "",
                                  fontSize: 19,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    itemCount: 20),
              ],
            ),
          ),
        ),
      ),
  fallback: (context) =>
      RefreshIndicator(onRefresh: cubit.refreshMain,
          child: SingleChildScrollView(
             physics: BouncingScrollPhysics(),
              child: SizedBox(
                height: MediaQuery
                    .of(context)
                    .size
                    .height,
                child: Center(
                    child: CircularProgressIndicator(

                      valueColor:
                      AlwaysStoppedAnimation<Color>(
                          appbarColor),
                    )),))
      ),
);
Widget hadeeths(cubit,id)=>ConditionalBuilder(
    condition: cubit.category!= null,

    builder:(context) => RefreshIndicator(
      onRefresh: ()=>cubit.refresh(id:id, ),

      child: SafeArea(
          child: LoadMore(
            whenEmptyLoad: false,
            delegate: const DefaultLoadMoreDelegate(),
            textBuilder: DefaultLoadMoreTextBuilder.english,
            isFinish:int.parse(cubit.category!.meta!.perPage)>=  20,
            onLoadMore: ()=>cubit.loadMore(id: id, ),

            child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: cubit.category!.meta!.totalItems,

                itemBuilder: (context,  index) =>   Card(
                  elevation: 3,

                  margin: const EdgeInsets.all(10),
                  child: ListTile( onTap: (){

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>Hadeethsdetails(
                            id: cubit.category!.data[index].id,


                          ),
                        ));
/*
                              Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => onedetail(
                                  id: cubit.category!.data[index].id,


                                        ),
                              ),
                            );*/
                  },
                    leading:const Icon(Icons.arrow_back_ios),
                    title:Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Customtext(
                        fontWeight: FontWeight.bold,
                        alignment :Alignment.centerRight,
                        color: const Color.fromARGB(250,40, 82, 122),
                        text:  cubit.category!.data[index].title.toString(),
                        fontSize: 16,


                      ),
                    ),
                  ),
                )),
          )

      ),
    ), fallback: (BuildContext context) =>    Center(
  child: CircularProgressIndicator(
    valueColor: AlwaysStoppedAnimation<Color>(appbarColor),
  ),
)



);
Widget hadeethsdetails(cubit)=>ConditionalBuilder(

  condition: cubit.model != null,
  builder: (context) => Padding(
    padding: const EdgeInsets.all(10.0),
    child:SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          ///hadeeth
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () async {
                  Share.share(cubit.model!.hadeeth.isNotEmpty &&
                      cubit.model!.grade.isNotEmpty &&
                      cubit.model!.attribution.isNotEmpty
                      ? cubit.model!.hadeeth +"[" + cubit.model!.attribution + "]"
                      "[" +
                      cubit.model!.grade +
                      "]"
                      : "not data");
                },
              ),
              Customtext(
                fontWeight: FontWeight.bold,
                alignment: Alignment.centerRight,
                color: mainColor,
                text: "الحديث:",
                fontSize: 24,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Customtext(
              fontWeight: FontWeight.normal,
              alignment: Alignment.centerRight,
              color: Colors.black,
              text: cubit.model!.hadeeth.isNotEmpty
                  ? cubit.model!.hadeeth
                  : "not data",
              fontSize: 24,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          //// الرواي ودرجه الحديث  /
          Row(
            children: [
              Expanded(
                child: Customtext(
                  fontWeight: FontWeight.normal,
                  alignment: Alignment.centerLeft,
                  color: subColor,
                  text: cubit.model!.grade.isNotEmpty
                      ? "[" + cubit.model!.grade + "]"
                      : "not data",
                  fontSize: 19,
                ),
              ),
              Expanded(
                child: Customtext(
                  fontWeight: FontWeight.normal,
                  alignment: Alignment.centerLeft,
                  color: subColor,
                  text: cubit.model!.attribution.isNotEmpty
                      ? "[" + cubit.model!.attribution + "]"
                      : "not data",
                  fontSize: 19,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          // الشرح
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  builder: (context) => customScrollableSheet(
                    function: () async {
                      Share.share(cubit.model!.explanation.isNotEmpty
                          ? cubit.model!.explanation
                          : "not data");
                    },
                    TextTitle: 'الشرح:',
                    Text:
                    cubit.model!.explanation.isNotEmpty
                        ? cubit.model!.explanation
                        : "not data",
                  ));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  Icons.arrow_back_ios,
                  color: mainColor,
                ),
                Customtext(
                  fontWeight: FontWeight.bold,
                  alignment: Alignment.centerRight,
                  color: mainColor,
                  text: "الشرح",
                  fontSize: 24,
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          //الفوائد//
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                  isScrollControlled: true,
                  enableDrag: true,
                  context: context,
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  builder: (context) =>
                      DraggableScrollableSheet(
                          initialChildSize: 0.7,
                          minChildSize: 0.5,
                          maxChildSize: 1.0,
                          builder: (_, controller) => Container(
                            decoration: const BoxDecoration(
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
                                children: [
                                  Padding(
                                    padding:
                                    const EdgeInsets
                                        .only(
                                        bottom: 8.0),
                                    child: Customtext(
                                      fontWeight:
                                      FontWeight.bold,
                                      alignment: Alignment
                                          .centerRight,
                                      color: mainColor,
                                      text: "الفوائد:",
                                      fontSize: 24,
                                    ),
                                  ),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    controller: controller,
                                    physics:
                                    const NeverScrollableScrollPhysics(),
                                    itemCount: cubit.model!
                                        .hints.length,
                                    separatorBuilder:
                                        (BuildContext
                                    context,
                                        int index) =>
                                    const Divider(
                                      color: Colors.teal,
                                    ),
                                    itemBuilder:
                                        (BuildContext
                                    context,
                                        int index) {
                                      return Row(
                                        children: [
                                          Expanded(
                                            child:
                                            Customtext(
                                              fontWeight:
                                              FontWeight
                                                  .normal,
                                              alignment:
                                              Alignment
                                                  .centerRight,
                                              color: Colors
                                                  .black,
                                              text: cubit
                                                  .model!
                                                  .hints[
                                              index]
                                                  .isNotEmpty
                                                  ? (1 + index)
                                                  .toString() +
                                                  ":  " +
                                                  cubit
                                                      .model!
                                                      .hints[index]
                                                  : "not data",
                                              fontSize: 19,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.arrow_back_ios,
                ),
                Customtext(
                  fontWeight: FontWeight.bold,
                  alignment: Alignment.centerRight,
                  color: mainColor,
                  text: "الفوائد:",
                  fontSize: 24,
                ),
              ],
            ),
          ),
/////معاني الكلمات
          cubit.model!.wordsMeanings.isNotEmpty
              ? Customtext(
            fontWeight: FontWeight.bold,
            alignment: Alignment.centerRight,
            color: mainColor,
            text: "معاني الكلمات:",
            fontSize: 24,
          )
              : const Customtext(
            fontWeight: FontWeight.bold,
            text: " ",
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: cubit.model!.wordsMeanings.length,
            separatorBuilder:
                (BuildContext context, int index) => Divider(
              color: subColor,
            ),
            itemBuilder: (BuildContext context, int index) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Customtext(
                      fontWeight: FontWeight.normal,
                      alignment: Alignment.centerRight,
                      color: Colors.black,
                      text: cubit.model!.wordsMeanings[index]
                          .meaning.isNotEmpty
                          ? cubit.model!.wordsMeanings[index]
                          .meaning
                          : "not data",
                      fontSize: 19,
                    ),
                  ),
                  Expanded(
                    child: Customtext(
                      fontWeight: FontWeight.bold,
                      alignment: Alignment.centerRight,
                      color: subColor,
                      text: cubit.model!.wordsMeanings[index]
                          .word.isNotEmpty
                          ? cubit.model!.wordsMeanings[index]
                          .word +
                          ":"
                          : "not data",
                      fontSize: 19,
                    ),
                  ),
                ],
              );
            },
          ),


          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  builder: (context) => customScrollableSheet(
                    function: () async {
                      Share.share(cubit.model!.reference.isNotEmpty
                          ? cubit.model!.reference
                          : "not data");
                    },
                    TextTitle: 'المصادر:',
                    Text:
                    cubit.model!.reference.isNotEmpty
                        ? cubit.model!.reference
                        : "not data",
                  ));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  Icons.arrow_back_ios,
                  color: mainColor,
                ),
                Customtext(
                  fontWeight: FontWeight.bold,
                  alignment: Alignment.centerRight,
                  color: mainColor,
                  text: "المصادر",
                  fontSize: 24,
                ),
              ],
            ),
          ),


        ],
      ),
    ),
  ),
  fallback: (context) =>   Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(appbarColor),

      )),

);