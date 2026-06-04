import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/create_scholarship_request.dart';
import '../models/scholarship.dart';

class ScholarshipService {
  final Dio _dio;

  ScholarshipService(this._dio);

  Future<List<Scholarship>> getAll() async {
    final response =
        await _dio.get<List<dynamic>>(ApiConstants.scholarships);
    return response.data!
        .map((e) => Scholarship.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Scholarship> getById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.scholarships}/$id',
    );
    return Scholarship.fromJson(response.data!);
  }

  Future<Scholarship> create(CreateScholarshipRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.scholarships,
      data: request.toJson(),
    );
    return Scholarship.fromJson(response.data!);
  }
}
