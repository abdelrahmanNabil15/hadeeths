import 'package:dio/dio.dart';

import '../../Model/category_node.dart';
import '../../Model/hadith_details.dart';
import '../../Model/hadith_page.dart';
import '../../Model/json_helpers.dart';
import '../errors/failure.dart';
import 'endpoint.dart';

/// Read-only access to the HadeethEnc API. Every method throws a [Failure] on error.
abstract interface class HadeethApi {
  /// All categories (roots and descendants) as a flat list; build the tree with `parentId`.
  Future<List<CategoryNode>> getCategories({String language = 'ar'});

  /// One page of the hadith list of [categoryId].
  Future<HadithPage> getHadithPage({
    required String categoryId,
    int page = 1,
    int perPage = defaultPageSize,
    String language = 'ar',
  });

  Future<HadithDetails> getHadithDetails(String id, {String language = 'ar'});

  static const defaultPageSize = 20;
}

/// [HadeethApi] over Dio, with timeouts, error mapping and bounded retries.
///
/// Retries apply only to idempotent GETs that failed with a timeout or a gateway error
/// (502/503/504). A plain 500 is not retried: the API answers an unknown category id
/// with a 500, and repeating that request cannot help.
class HttpHadeethApi implements HadeethApi {
  HttpHadeethApi({
    Dio? dio,
    this.maxRetries = 2,
    this.retryDelay = const Duration(milliseconds: 400),
  }) : _dio = dio ?? createDio();

  final Dio _dio;
  final int maxRetries;
  final Duration retryDelay;

  static Dio createDio() => Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 10),
    ),
  );

  @override
  Future<List<CategoryNode>> getCategories({String language = 'ar'}) async {
    final data = await _get(list, {'language': language});
    return _parse(
      () => asList(
        data,
        'categories',
      ).map((e) => CategoryNode.fromJson(asMap(e, 'category'))).toList(),
    );
  }

  @override
  Future<HadithPage> getHadithPage({
    required String categoryId,
    int page = 1,
    int perPage = HadeethApi.defaultPageSize,
    String language = 'ar',
  }) async {
    final data = await _get(headlist, {
      'language': language,
      'category_id': categoryId,
      'page': page,
      'per_page': perPage,
    });
    return _parse(() => HadithPage.fromJson(asMap(data, 'hadith page')));
  }

  @override
  Future<HadithDetails> getHadithDetails(
    String id, {
    String language = 'ar',
  }) async {
    final data = await _get(oneElment, {'language': language, 'id': id});
    return _parse(() => HadithDetails.fromJson(asMap(data, 'hadith')));
  }

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on Failure {
      rethrow;
    } catch (e) {
      throw Failure(FailureKind.parse, debugMessage: e.toString());
    }
  }

  Future<Object?> _get(String path, Map<String, dynamic> query) async {
    var attempt = 0;
    while (true) {
      try {
        final response = await _dio.get<Object?>(path, queryParameters: query);
        return response.data;
      } on DioException catch (e) {
        final failure = mapDioException(e);
        if (_isRetryable(e) && attempt < maxRetries) {
          attempt++;
          await Future<void>.delayed(retryDelay * attempt);
          continue;
        }
        throw failure;
      }
    }
  }

  static bool _isRetryable(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        return code == 502 || code == 503 || code == 504;
      default:
        return false;
    }
  }

  /// Maps a Dio error to a [Failure] without exposing the exception to callers.
  static Failure mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Failure(FailureKind.timeout, debugMessage: e.message);
      case DioExceptionType.connectionError:
        return Failure(FailureKind.noConnection, debugMessage: e.message);
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 404) {
          return Failure(FailureKind.notFound, statusCode: code);
        }
        return Failure(FailureKind.server, statusCode: code);
      case DioExceptionType.cancel:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return Failure(FailureKind.unexpected, debugMessage: e.message);
    }
  }
}
