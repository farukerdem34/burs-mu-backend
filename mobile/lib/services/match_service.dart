import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/match_result.dart';

class MatchService {
  final Dio _dio;

  MatchService(this._dio);

  Future<List<MatchResult>> matchStudent(String studentId) async {
    final response = await _dio.post<List<dynamic>>(
      '${ApiConstants.match}/$studentId',
    );
    return response.data!
        .map((e) => MatchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
