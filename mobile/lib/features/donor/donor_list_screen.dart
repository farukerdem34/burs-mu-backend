import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/donor_provider.dart';
import 'donor_detail_screen.dart';

class DonorListScreen extends ConsumerWidget {
  const DonorListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donorsAsync = ref.watch(donorListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Donörler')),
      body: donorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (donors) => donors.isEmpty
            ? const Center(child: Text('Henüz donör yok'))
            : ListView.builder(
                itemCount: donors.length,
                itemBuilder: (context, index) {
                  final donor = donors[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        donor.isVerified == true
                            ? Icons.verified
                            : Icons.pending,
                        color: donor.isVerified == true
                            ? Colors.green
                            : Colors.orange,
                      ),
                      title:
                          Text('Profil: ${donor.profileId?.substring(0, 8) ?? '-'}...'),
                      subtitle: Text(
                        donor.isVerified == true
                            ? 'Doğrulanmış'
                            : 'Doğrulanmamış',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DonorDetailScreen(
                            profileId: donor.profileId!,
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
