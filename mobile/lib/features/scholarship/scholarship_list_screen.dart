import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/scholarship_provider.dart';
import 'scholarship_detail_screen.dart';

class ScholarshipListScreen extends ConsumerWidget {
  const ScholarshipListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scholarshipsAsync = ref.watch(scholarshipListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Burslar')),
      body: scholarshipsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (scholarships) => scholarships.isEmpty
            ? const Center(child: Text('Henüz burs yok'))
            : ListView.builder(
                itemCount: scholarships.length,
                itemBuilder: (context, index) {
                  final scholarship = scholarships[index];
                  return Card(
                    child: ListTile(
                      title: Text(scholarship.title ?? 'Başlıksız'),
                      subtitle: Text(
                        'Kota: ${scholarship.quota ?? '-'} • Min GPA: ${scholarship.minGpa?.toStringAsFixed(2) ?? '-'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (scholarship.isActive == true)
                            const Icon(Icons.check_circle, color: Colors.green, size: 16)
                          else
                            const Icon(Icons.cancel, color: Colors.red, size: 16),
                          SizedBox(width: 4),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScholarshipDetailScreen(
                            scholarshipId: scholarship.id!,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
