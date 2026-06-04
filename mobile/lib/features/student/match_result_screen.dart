import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/match_provider.dart';
import '../../core/secure_storage.dart';

class MatchResultScreen extends ConsumerWidget {
  final String? studentId;

  const MatchResultScreen({super.key, this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: SecureStorage.getToken(),
      builder: (context, snapshot) {
        final id = studentId ?? snapshot.data ?? '';
        final matchesAsync = ref.watch(matchResultsProvider(id));

        return Scaffold(
          appBar: AppBar(title: const Text('Eşleşme Sonuçları')),
          body: matchesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Hata: $e')),
            data: (matches) {
              if (matches.isEmpty) {
                return const Center(
                  child: Text('Uygun burs bulunamadı'),
                );
              }
              return ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  final scorePercent = ((match.score ?? 0) * 100).toInt();
                  return Card(
                    child: ListTile(
                      title: Text('Burs: ${match.scholarshipId ?? '-'}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: match.score ?? 0,
                            backgroundColor: Colors.grey[300],
                          ),
                          const SizedBox(height: 4),
                          Text('Eşleşme: %$scorePercent'),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
