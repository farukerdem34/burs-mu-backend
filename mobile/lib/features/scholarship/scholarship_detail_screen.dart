import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/screen_utils.dart';
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
            padding: EdgeInsets.all(context.w(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scholarship.title ?? 'Başlıksız',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: context.h(16)),
                _infoRow(context, 'Durum',
                    scholarship.isActive == true ? 'Aktif' : 'Pasif'),
                _infoRow(context, 'Kota', scholarship.quota?.toString() ?? '-'),
                _infoRow(context, 'Min GPA',
                    scholarship.minGpa?.toStringAsFixed(2) ?? 'Yok'),
                SizedBox(height: context.h(16)),
                const Text('Hedef Şehirler:'),
                SizedBox(height: context.h(4)),
                scholarship.targetCities != null &&
                        scholarship.targetCities!.isNotEmpty
                    ? Wrap(
                        spacing: context.w(8),
                        runSpacing: context.h(4),
                        children: scholarship.targetCities!
                            .map((c) => Chip(label: Text(c)))
                            .toList(),
                      )
                    : const Text('Yok'),
                SizedBox(height: context.h(16)),
                const Text('Hedef Bölümler:'),
                SizedBox(height: context.h(4)),
                scholarship.targetDepartments != null &&
                        scholarship.targetDepartments!.isNotEmpty
                    ? Wrap(
                        spacing: context.w(8),
                        runSpacing: context.h(4),
                        children: scholarship.targetDepartments!
                            .map((d) => Chip(label: Text(d)))
                            .toList(),
                      )
                    : const Text('Yok'),
                SizedBox(height: context.h(16)),
                const Text('Hedef Gelir Düzeyleri:'),
                SizedBox(height: context.h(4)),
                scholarship.targetIncomeLevels != null &&
                        scholarship.targetIncomeLevels!.isNotEmpty
                    ? Wrap(
                        spacing: context.w(8),
                        runSpacing: context.h(4),
                        children: scholarship.targetIncomeLevels!
                            .map((l) => Chip(label: Text(l.displayName)))
                            .toList(),
                      )
                    : const Text('Yok'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.w(120),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
