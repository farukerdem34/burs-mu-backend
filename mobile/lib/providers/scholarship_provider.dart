import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scholarship.dart';
import '../services/scholarship_service.dart';
import 'auth_provider.dart';

final scholarshipServiceProvider = Provider<ScholarshipService>((ref) {
  return ScholarshipService(ref.read(dioProvider));
});

final scholarshipListProvider = FutureProvider<List<Scholarship>>((ref) async {
  return ref.read(scholarshipServiceProvider).getAll();
});

final scholarshipDetailProvider =
    FutureProvider.family<Scholarship, String>((ref, id) async {
  return ref.read(scholarshipServiceProvider).getById(id);
});

final donorScholarshipsProvider =
    FutureProvider.family<List<Scholarship>, String>((ref, donorProfileId) async {
  return ref.read(scholarshipServiceProvider).getByDonorId(donorProfileId);
});
