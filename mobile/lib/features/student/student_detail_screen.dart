import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/student_provider.dart';
import '../../core/secure_storage.dart';
import 'student_edit_screen.dart';
import 'match_result_screen.dart';

class StudentDetailScreen extends ConsumerWidget {
  final String profileId;

  const StudentDetailScreen({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailProvider(profileId));

    return Scaffold(
      appBar: AppBar(title: const Text('Öğrenci Detay')),
      body: studentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (student) {
          return FutureBuilder<String?>(
            future: SecureStorage.getToken(),
            builder: (context, tokenSnapshot) {
              final isOwner = tokenSnapshot.data == student.profileId;

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Profil ID', student.profileId ?? '-'),
                    _infoRow('Şehir', student.city ?? '-'),
                    _infoRow('Bölüm', student.department ?? '-'),
                    _infoRow(
                      'GPA',
                      student.gpa?.toStringAsFixed(2) ?? '-',
                    ),
                    _infoRow(
                      'Gelir Düzeyi',
                      student.incomeStatus?.displayName ?? '-',
                    ),
                    if (student.about != null && student.about!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'Hakkında: ${student.about}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    const Spacer(),
                    if (isOwner) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StudentEditScreen(profileId: profileId),
                            ),
                          ),
                          child: const Text('Düzenle'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MatchResultScreen(studentId: profileId),
                          ),
                        ),
                        child: const Text('Eşleşme Sonuçlarını Gör'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
