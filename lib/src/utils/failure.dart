import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final dynamic error;

  /// The API error code (`SENDER_NOT_LINKED`, `CONFLICT` …) when the failure
  /// came from the server — branch on this, never on [message].
  final String? code;

  /// HTTP status of the failed response, when there was one.
  final int? status;

  const Failure(this.message, {this.error, this.code, this.status});

  @override
  List<Object?> get props => [message, error, code, status];

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.error, super.code, super.status});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.error});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.error});
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.error});
}
