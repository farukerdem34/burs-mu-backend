import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/donor_provider.dart';

class DonorVerifyScreen extends ConsumerWidget {
  const DonorVerifyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donorsAsync = ref.watch(donorListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Donör Doğrula')),
      body: donorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (donors) {
          final unverified =
              donors.where((d) => d.isVerified != true).toList();

          if (unverified.isEmpty) {
            return const Center(
              child: Text('Doğrulanmamış donör yok'),
            );
          }

          return ListView.builder(
            itemCount: unverified.length,
            itemBuilder: (context, index) {
              final donor = unverified[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.pending, color: Colors.orange),
                  title: Text(
                    'Profil: ${donor.profileId?.substring(0, 8)}...',
                  ),
                  subtitle: Text(
                    'Oluşturulma: ${donor.createdAt?.toString().substring(0, 10) ?? '-'}',
                  ),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(donorServiceProvider)
                            .verify(donor.profileId!);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Donör ${donor.profileId?.substring(0, 8)} doğrulandı',
                              ),
                            ),
                          );
                          ref.invalidate(donorListProvider);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Hata: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Doğrula'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
