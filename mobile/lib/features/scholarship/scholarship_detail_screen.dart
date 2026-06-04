import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/scholarship_provider.dart';

class ScholarshipDetailScreen extends ConsumerWidget {
  final String scholarshipId;

  const ScholarshipDetailScreen({super.key, required this.scholarshipId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scholarshipAsync = ref.watch(scholarshipDetailProvider(scholarshipId));

    return Scaffold(
      appBar: AppBar(title: const Text('Burs Detay')),
      body: scholarshipAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (scholarship) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scholarship.title ?? 'Başlıksız',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _infoRow('Durum',
                    scholarship.isActive == true ? 'Aktif' : 'Pasif'),
                _infoRow('Kota', scholarship.quota?.toString() ?? '-'),
                _infoRow('Min GPA',
                    scholarship.minGpa?.toStringAsFixed(2) ?? '-'),
                if (scholarship.targetCities != null &&
                    scholarship.targetCities!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Hedef Şehirler:'),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: scholarship.targetCities!
                        .map((c) => Chip(label: Text(c)))
                        .toList(),
                  ),
                ],
                if (scholarship.targetDepartments != null &&
                    scholarship.targetDepartments!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Hedef Bölümler:'),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: scholarship.targetDepartments!
                        .map((d) => Chip(label: Text(d)))
                        .toList(),
                  ),
                ],
                if (scholarship.targetIncomeLevels != null &&
                    scholarship.targetIncomeLevels!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Hedef Gelir Düzeyleri:'),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: scholarship.targetIncomeLevels!
                        .map((l) => Chip(label: Text(l.name)))
                        .toList(),
                  ),
                ],
              ],
            ),
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
