// ignore_for_file: avoid_print, duplicate_ignore, avoid_web_libraries_in_flutter, non_constant_identifier_names

import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:mynewapp/Model/categoryModel.dart';
import 'package:mynewapp/Model/detailsModel.dart';
import 'package:mynewapp/Shared/Network/DioHelper.dart';
import 'package:mynewapp/Shared/Network/endpoint.dart';


import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'State.dart';

class AlmunirCubit extends Cubit<almunir_state> {

  AlmunirCubit() : super(almunirInitstate());
  RefreshController refreshController =
  RefreshController(initialRefresh: true);

  static AlmunirCubit get(context) => BlocProvider.of(context);
  Category? category;
  detailsModel? model;

  // ignore: non_constant_identifier_names
  List<dynamic> Categories = [];

  void getCategories() {
    emit(almunirLoadingstate());
    if(Categories.isEmpty){
    DioHelper.getdata(url: list, query: {
      'language': 'ar',

    }).then((value) {
      Categories = value.data;


      emit(almunirSuccessstate());
    }).catchError((error) {
      print(error.toString());
      emit(almunirErrorstate(error.toString()));
    });
  }else{

      emit(almunirSuccessstate());
    }
  }

  Future<bool> getheadof(var id,) async {
    emit(almunirLoadingstate());
    await DioHelper.getdata(url: headlist, query: {
      'language': 'ar',
      'category_id': id,
      'page': '1',
      'per_page': "2000"
    }).then((value) {
      category = Category.fromJson(value.data);
      print(category!.data.length);


      emit(almunirSuccessstate());
      return true;
    }).catchError((error) {
      print(error.toString());
      emit(almunirErrorstate(error.toString()));
    });

    return false;
  }

  Future<bool> loadMore({var id}) async {
    print("onLoadMore");
    await Future.delayed(const Duration(seconds: 0, milliseconds: 2000));

    getheadof(id);


    return true;
  }

  Future<void> refresh({var id,}) async {
    await Future.delayed(const Duration(seconds: 0, milliseconds: 2000));
    Category;

    getheadof(id,);
  }


  void getdetails(var id,)  {
    emit(onedetailsLoadingstate());
    if(category== null){
      DioHelper.getdata(url: oneElment, query: {
      'language': 'ar',
      'id': id,
    }).then((value) {
      model = detailsModel.fromJson(value.data);
      // ignore: avoid_print
      print(model!.title);


      emit(onedetailsSuccessstate());

    }).catchError((Object e, StackTrace stackTrace) {
      // ignore: avoid_print
      print(e.toString());
      // ignore: avoid_print
      print(stackTrace);
      
      
      emit(onedetailsErrorstate(e.toString()));
    }).then((print) );


  }
  else{

      emit(onedetailsSuccessstate());

    }}

  bool isConnected=false;

  Future<void>checkConection() async{
    InternetAddress.lookup('google.com').then((result){
      if(result.isNotEmpty && result[0].rawAddress.isNotEmpty){
        // internet conn available
        
        print("connecet");
        return true;

      }else{
        // no conn
        print('no connect');

        return false;
      }
    }).catchError((error){
      print('no connect');


      // no conn

    });

    return ;   }
  void Conection()async{


    // Simple check to see if we have Internet
    // ignore: avoid_print
    print('''The statement 'this machine is connected to the Internet' is: ''');
    isConnected = await InternetConnectionChecker().hasConnection;
    // ignore: avoid_print
    print(
      isConnected.toString(),
    );
    // returns a bool

    // We can also get an enum instead of a bool
    // ignore: avoid_print
    print(
        'Current status: ${await InternetConnectionChecker().connectionStatus}');
    // Prints either InternetConnectionStatus.connected
    // or InternetConnectionStatus.disconnected

    // actively listen for status updates
    final StreamSubscription<InternetConnectionStatus> listener =
    InternetConnectionChecker().onStatusChange.listen(
          (InternetConnectionStatus status) {
        switch (status) {
          case InternetConnectionStatus.connected:
          // ignore: avoid_print
            print('Data connection is available.');
            emit(isconnectedstate());
            break;
          case InternetConnectionStatus.disconnected:
          // ignore: avoid_print
            print('You are disconnected from the internet.');
            emit(isnotcectedstate());
            break;
        }
      },
    );

    // close listener after 30 seconds, so the program doesn't run forever
    await Future<void>.delayed(const Duration(seconds: 30));
    await listener.cancel();
  }

  Future<void> refreshMain( ) async {
    await Future.delayed(const Duration(seconds: 0, milliseconds: 2000));
    Category;

    getCategories();
  }

  }











