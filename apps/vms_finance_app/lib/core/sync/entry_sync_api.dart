import 'package:dio/dio.dart';

enum EntrySyncStatus { applied, duplicate, conflict, rejected }

class PendingEntryOperation {
  const PendingEntryOperation({
    required this.operationId,
    required this.entryId,
    required this.householdId,
    required this.direction,
    required this.amountInCents,
    required this.description,
    required this.occurredOn,
  });

  final String operationId;
  final String entryId;
  final String householdId;
  final String direction;
  final int amountInCents;
  final String description;
  final String occurredOn;

  Map<String, Object> toJson() => {
    'id': entryId,
    'idempotencyKey': operationId,
    'direction': direction,
    'amountInCents': amountInCents,
    'description': description,
    'occurredOn': occurredOn,
  };
}

class EntrySyncResult {
  const EntrySyncResult({
    required this.operationId,
    required this.status,
    this.message,
  });

  final String operationId;
  final EntrySyncStatus status;
  final String? message;
}

abstract interface class EntrySyncApi {
  Future<List<EntrySyncResult>> pushEntries({
    required String householdId,
    required String accessToken,
    required List<PendingEntryOperation> operations,
  });
}

class EntrySyncConflictException implements Exception {
  const EntrySyncConflictException([this.message = 'Sync conflict.']);

  final String message;

  @override
  String toString() => 'EntrySyncConflictException: $message';
}

class EntrySyncAuthenticationException implements Exception {
  const EntrySyncAuthenticationException();
}

class EntrySyncInvalidResponseException implements Exception {
  const EntrySyncInvalidResponseException();
}

class DioEntrySyncApi implements EntrySyncApi {
  DioEntrySyncApi(this._dio);

  final Dio _dio;

  @override
  Future<List<EntrySyncResult>> pushEntries({
    required String householdId,
    required String accessToken,
    required List<PendingEntryOperation> operations,
  }) async {
    late final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
        '/api/households/$householdId/sync/entries',
        data: {
          'operations': operations
              .map((operation) => operation.toJson())
              .toList(),
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 409) {
        throw EntrySyncConflictException(error.message ?? 'Sync conflict.');
      }
      if (error.response?.statusCode case 401 || 403) {
        throw const EntrySyncAuthenticationException();
      }
      rethrow;
    }
    final rawResults = response.data?['results'];
    if (rawResults is! List) {
      throw const EntrySyncInvalidResponseException();
    }

    return rawResults
        .map((raw) {
          if (raw is! Map) {
            throw const EntrySyncInvalidResponseException();
          }
          final operationId = raw['idempotencyKey'];
          final created = raw['created'];
          if (operationId is! String || created is! bool) {
            throw const EntrySyncInvalidResponseException();
          }
          return EntrySyncResult(
            operationId: operationId,
            status: created
                ? EntrySyncStatus.applied
                : EntrySyncStatus.duplicate,
          );
        })
        .toList(growable: false);
  }
}

abstract interface class AccessTokenProvider {
  Future<String?> readAccessToken();
}
