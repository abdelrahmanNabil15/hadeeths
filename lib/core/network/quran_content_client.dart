import 'package:dio/dio.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/network/quran_content_endpoints.dart';

/// Low-level GET access to hadeeths' own Quran content proxy: timeouts, error mapping and
/// bounded retries. Same shape as `HadeethClient`, kept as its own class because it talks to a
/// different server (the Cloudflare Worker proxy, not HadeethEnc) with its own base URL.
///
/// Retries apply only to idempotent GETs that failed with a timeout or a gateway error
/// (502/503/504), the same rule `HadeethClient` uses.
class QuranContentClient {
  QuranContentClient({
    Dio? dio,
    this.maxRetries = 2,
    this.retryDelay = const Duration(milliseconds: 400),
  }) : _dio = dio ?? createDio();

  final Dio _dio;
  final int maxRetries;
  final Duration retryDelay;

  static Dio createDio() => Dio(
    BaseOptions(
      baseUrl: quranContentBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 10),
    ),
  );

  /// Returns the decoded JSON body of `GET [path]`. Throws a [Failure] on any error.
  Future<Object?> get(String path, Map<String, dynamic> query) async {
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
