import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/named_item.dart';

class ReferenceService {
  final Dio _dio;

  ReferenceService(this._dio);

  Future<List<NamedItem>> getCities() async {
    final response =
        await _dio.get<List<dynamic>>(ApiConstants.cities);
    return response.data!
        .map((e) => NamedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<NamedItem>> getDepartments() async {
    final response =
        await _dio.get<List<dynamic>>(ApiConstants.departments);
    return response.data!
        .map((e) => NamedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<NamedItem>> getIncomeLevels() async {
    final response =
        await _dio.get<List<dynamic>>(ApiConstants.incomeLevels);
    return response.data!
        .map((e) => NamedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<NamedItem>> getUserRoles() async {
    final response =
        await _dio.get<List<dynamic>>(ApiConstants.userRoles);
    return response.data!
        .map((e) => NamedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
