import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/screen_utils.dart';
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
            padding: EdgeInsets.all(context.w(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (donor.name != null)
                  _infoRow(context, 'Ad', donor.name!),
                _infoRow(context, 'Profil ID', donor.profileId ?? '-'),
                _infoRow(context, 'Durum',
                    donor.isVerified == true ? 'Doğrulanmış' : 'Doğrulanmamış'),
                _infoRow(context, 'Oluşturulma',
                    donor.createdAt?.toString() ?? '-'),
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
