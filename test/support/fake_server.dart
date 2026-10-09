import 'package:dio/dio.dart';
import 'package:mynewapp/app/app_dependencies.dart';
import 'package:mynewapp/core/cache/response_cache.dart';
import 'package:mynewapp/core/network/hadeeth_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_dio.dart';
import 'fixtures.dart';

/// A pretend HadeethEnc server behind a real [HadeethClient], that can be switched offline.
/// Used with the real data sources, repositories and cache.
class FakeServer {
  bool online = true;

  /// When true the details endpoint answers with something that is not a hadith.
  bool malformed = false;

  /// When true the details endpoint answers 404 (the hadith was removed).
  bool gone = false;
  final requests = <RequestOptions>[];

  /// How many requests reached the server for [path].
  int count(String path) => requests.where((r) => r.path == path).length;

  Future<ResponseBody> handle(RequestOptions options, int callNumber) async {
    requests.add(options);
    if (!online) throw dioError(options, DioExceptionType.connectionError);
    final q = options.queryParameters;
    switch (options.path) {
      case 'categories/list':
        return jsonResponse(categoriesJson);
      case 'hadeeths/list':
        return jsonResponse(
          hadithPageJson(
            ids: ['101', '102'],
            page: q['page'] as int,
            lastPage: 1,
          ),
        );
      case 'hadeeths/one':
        if (gone) return emptyResponse(404);
        if (malformed) return jsonResponse([1, 2, 3]);
        final id = q['id'];
        return jsonResponse({
          ...arabicDetailsJson,
          'id': id,
          'title': 'عنوان $id',
        });
      case 'hadeeths/search':
        return jsonResponse([
          {
            'id': '101',
            'title': 'نتيجة',
            'hadith_text': 'نص',
            'hadith_text_highlights': 'نص <mark>الحديث</mark>',
          },
        ]);
    }
    return emptyResponse(404);
  }

  HadeethClient get client {
    final dio = HadeethClient.createDio()
      ..httpClientAdapter = FakeAdapter(handle);
    return HadeethClient(dio: dio, retryDelay: Duration.zero);
  }

  /// The real application wiring over this server.
  Future<AppDependencies> dependencies(SwitchableResponseCache cache) async {
    SharedPreferences.setMockInitialValues({});
    return AppDependencies.live(
      preferences: await SharedPreferences.getInstance(),
      cache: cache,
      client: client,
    );
  }
}
