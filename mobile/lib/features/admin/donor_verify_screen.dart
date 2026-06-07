import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/screen_utils.dart';
import '../../providers/donor_provider.dart';
import '../../widgets/stacked_notification.dart';

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
                  title: Text(donor.name ?? 'Profil: ${donor.profileId?.substring(0, 8) ?? '-'}...'),
                  subtitle: Text(
                    'Oluşturulma: ${donor.createdAt?.toString().substring(0, 10) ?? '-'}',
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(donorServiceProvider)
                            .verify(donor.profileId!);
                        if (context.mounted) {
                          ref.read(notificationStackProvider.notifier).show(
                            'Donör ${donor.name ?? donor.profileId?.substring(0, 8) ?? ''} doğrulandı',
                          );
                          ref.invalidate(donorListProvider);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ref.read(notificationStackProvider.notifier).show(
                            'Hata: $e',
                            isError: true,
                          );
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(8)),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
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
