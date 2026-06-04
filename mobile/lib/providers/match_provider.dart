import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_result.dart';
import '../services/match_service.dart';
import 'auth_provider.dart';

final matchServiceProvider = Provider<MatchService>((ref) {
  return MatchService(ref.read(dioProvider));
});

final matchResultsProvider =
    FutureProvider.family<List<MatchResult>, String>((ref, studentId) async {
  return ref.read(matchServiceProvider).matchStudent(studentId);
});
