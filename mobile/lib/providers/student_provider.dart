import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/secure_storage.dart';
import '../models/student.dart';
import '../services/student_service.dart';
import 'auth_provider.dart';

final studentServiceProvider = Provider<StudentService>((ref) {
  return StudentService(ref.read(dioProvider));
});

final studentListProvider = FutureProvider<List<Student>>((ref) async {
  return ref.read(studentServiceProvider).getAll();
});

final studentDetailProvider =
    FutureProvider.family<Student, String>((ref, id) async {
  return ref.read(studentServiceProvider).getById(id);
});

final currentStudentProvider = FutureProvider<Student?>((ref) async {
  final token = await SecureStorage.getToken();
  if (token == null) return null;
  try {
    return await ref.read(studentServiceProvider).getById(token);
  } catch (_) {
    return null;
  }
});

final studentUpdateProvider = Provider<StudentService>((ref) {
  return ref.read(studentServiceProvider);
});
