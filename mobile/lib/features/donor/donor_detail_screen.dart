import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/donor_provider.dart';

class DonorDetailScreen extends ConsumerWidget {
  final String profileId;

  const DonorDetailScreen({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donorAsync = ref.watch(donorDetailProvider(profileId));

    return Scaffold(
      appBar: AppBar(title: const Text('Donör Detay')),
      body: donorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (donor) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Profil ID', donor.profileId ?? '-'),
                _infoRow(
                  'Durum',
                  donor.isVerified == true ? 'Doğrulanmış' : 'Doğrulanmamış',
                ),
                _infoRow(
                  'Oluşturulma',
                  donor.createdAt?.toString() ?? '-',
                ),
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
