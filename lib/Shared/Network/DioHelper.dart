 // ignore: file_names
 // ignore: file_names
 // ignore: file_names
 // ignore_for_file: file_names, duplicate_ignore

 import 'package:dio/dio.dart';


import 'endpoint.dart';

class DioHelper {
  static late Dio dio;

  static void init() {
    dio = Dio(BaseOptions(
      baseUrl:baseUrl,
    ));
  }

  static Future<Response> getdata({
    required String url,
    required Map<String, dynamic>? query,
  }) async {
    return await dio.get(
      url,
      queryParameters: query,
    );
  }
  Future onError(DioError err, ErrorInterceptorHandler handler) async {
    // ignore: avoid_print
    print("onError: ${err.response!.statusCode}");
    return handler.next(err);  // <--- THE TIP IS HERE
  }
}
