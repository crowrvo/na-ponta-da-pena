import 'package:dio/dio.dart';

import '../domain/household.dart';

abstract interface class HouseholdApi {
  Future<List<HouseholdSummary>> listHouseholds(String accessToken);

  Future<HouseholdSummary> createHousehold(String accessToken, String name);

  Future<HouseholdSummary> acceptInvitation(
    String accessToken,
    String invitationToken,
  );
}

class HouseholdAuthenticationException implements Exception {
  const HouseholdAuthenticationException();
}

class HouseholdTransportException implements Exception {
  const HouseholdTransportException();
}

class HouseholdRemoteException implements Exception {
  const HouseholdRemoteException();
}

class HouseholdInvalidResponseException implements Exception {
  const HouseholdInvalidResponseException();
}

class DioHouseholdApi implements HouseholdApi {
  DioHouseholdApi(this._dio);

  final Dio _dio;

  @override
  Future<List<HouseholdSummary>> listHouseholds(String accessToken) async {
    final response = await _request<List<dynamic>>(
      accessToken,
      (options) => _dio.get<List<dynamic>>('/api/households', options: options),
    );
    final data = response.data;
    if (data == null) throw const HouseholdInvalidResponseException();
    return data.map(_parseSummary).toList(growable: false);
  }

  @override
  Future<HouseholdSummary> createHousehold(
    String accessToken,
    String name,
  ) async {
    final response = await _request<Map<String, dynamic>>(
      accessToken,
      (options) => _dio.post<Map<String, dynamic>>(
        '/api/households',
        data: {'name': name},
        options: options,
      ),
    );
    return _parseSummary(response.data);
  }

  @override
  Future<HouseholdSummary> acceptInvitation(
    String accessToken,
    String invitationToken,
  ) async {
    final response = await _request<Map<String, dynamic>>(
      accessToken,
      (options) => _dio.post<Map<String, dynamic>>(
        '/api/household-invitations/accept',
        data: {'token': invitationToken},
        options: options,
      ),
    );
    final data = response.data;
    if (data == null) throw const HouseholdInvalidResponseException();
    return HouseholdSummary(
      id: _requiredUuid(data, 'householdId'),
      name: _requiredString(data, 'householdName'),
      role: HouseholdRole.fromJson(data['role']),
    );
  }

  Future<Response<T>> _request<T>(
    String accessToken,
    Future<Response<T>> Function(Options options) request,
  ) async {
    try {
      return await request(
        Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode case 401 || 403) {
        throw const HouseholdAuthenticationException();
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.response == null) {
        throw const HouseholdTransportException();
      }
      throw const HouseholdRemoteException();
    }
  }

  static HouseholdSummary _parseSummary(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const HouseholdInvalidResponseException();
    }
    return HouseholdSummary(
      id: _requiredUuid(value, 'id'),
      name: _requiredString(value, 'name'),
      role: HouseholdRole.fromJson(value['role']),
    );
  }

  static String _requiredString(Map<String, dynamic> value, String key) {
    final field = value[key];
    if (field is! String || field.trim().isEmpty) {
      throw const HouseholdInvalidResponseException();
    }
    return field;
  }

  static String _requiredUuid(Map<String, dynamic> value, String key) {
    final field = _requiredString(value, key);
    if (!_uuidPattern.hasMatch(field)) {
      throw const HouseholdInvalidResponseException();
    }
    return field;
  }

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
}
