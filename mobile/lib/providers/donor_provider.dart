import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/donor.dart';
import '../services/donor_service.dart';
import 'auth_provider.dart';

final donorServiceProvider = Provider<DonorService>((ref) {
  return DonorService(ref.read(dioProvider));
});

final donorListProvider = FutureProvider<List<Donor>>((ref) async {
  return ref.read(donorServiceProvider).getAll();
});

final donorDetailProvider =
    FutureProvider.family<Donor, String>((ref, profileId) async {
  return ref.read(donorServiceProvider).getById(profileId);
});
