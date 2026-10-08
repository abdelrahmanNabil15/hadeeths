import 'package:dio/dio.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/network/endpoints.dart';

/// Low-level GET access to the HadeethEnc API: timeouts, error mapping and bounded retries.
/// It returns the decoded JSON and knows nothing about hadith or category shapes.
///
/// Retries apply only to idempotent GETs that failed with a timeout or a gateway error
/// (502/503/504). A plain 500 is not retried: the API answers an unknown category id
/// with a 500, and repeating that request cannot help.
class HadeethClient {
  HadeethClient({
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

/// Runs [parse] and turns any parsing problem into a [FailureKind.parse] failure.
T parseResponse<T>(T Function() parse) {
  try {
    return parse();
  } on Failure {
    rethrow;
  } catch (e) {
    throw Failure(FailureKind.parse, debugMessage: e.toString());
  }
}
