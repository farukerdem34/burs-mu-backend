import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/donor.dart';

class DonorService {
  final Dio _dio;

  DonorService(this._dio);

  Future<List<Donor>> getAll() async {
    final response =
        await _dio.get<List<dynamic>>(ApiConstants.donors);
    return response.data!
        .map((e) => Donor.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Donor> getById(String profileId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.donors}/$profileId',
    );
    return Donor.fromJson(response.data!);
  }

  Future<Donor> verify(String profileId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiConstants.donors}/$profileId/verify',
    );
    return Donor.fromJson(response.data!);
  }
}
