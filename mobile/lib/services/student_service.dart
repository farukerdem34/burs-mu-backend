import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/create_student_request.dart';
import '../models/student.dart';
import '../models/update_student_request.dart';

class StudentService {
  final Dio _dio;

  StudentService(this._dio);

  Future<List<Student>> getAll() async {
    final response =
        await _dio.get<List<dynamic>>(ApiConstants.students);
    return response.data!
        .map((e) => Student.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Student> getById(String profileId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.students}/$profileId',
    );
    return Student.fromJson(response.data!);
  }

  Future<Student> create(CreateStudentRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.students,
      data: request.toJson(),
    );
    return Student.fromJson(response.data!);
  }

  Future<Student> update(String profileId, UpdateStudentRequest request) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '${ApiConstants.students}/$profileId',
      data: request.toJson(),
    );
    return Student.fromJson(response.data!);
  }
}
