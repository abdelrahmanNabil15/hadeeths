import 'package:equatable/equatable.dart';

/// What went wrong, independent of the networking library.
enum FailureKind {
  /// The device could not reach the server.
  noConnection,

  /// The server did not answer in time.
  timeout,

  /// The server answered with an error status (5xx or other unexpected 4xx).
  server,

  /// The requested content does not exist (HTTP 404).
  notFound,

  /// The response arrived but did not have the expected shape.
  parse,

  /// Anything else.
  unexpected,
}

/// An application-level error. Raw exceptions and stack traces never reach the UI;
/// [debugMessage] is for logs only.
class Failure extends Equatable implements Exception {
  const Failure(this.kind, {this.statusCode, this.debugMessage});

  final FailureKind kind;
  final int? statusCode;
  final String? debugMessage;

  /// Whether trying the same request again could plausibly succeed.
  bool get isRetryable => kind != FailureKind.notFound;

  @override
  List<Object?> get props => [kind, statusCode];

  @override
  String toString() =>
      'Failure($kind${statusCode == null ? '' : ', $statusCode'})';
}
