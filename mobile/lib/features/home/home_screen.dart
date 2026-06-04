import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_role.dart';
import '../auth/login_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.status != AuthStatus.authenticated) {
      return const LoginScreen();
    }

    final role = authState.role;

    return Scaffold(
      appBar: AppBar(
        title: Text('${role?.name ?? 'Kullanıcı'} Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (role == UserRole.student) ..._studentButtons(context),
            if (role == UserRole.donor) ..._donorButtons(context),
            if (role == UserRole.admin) ..._adminButtons(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _studentButtons(BuildContext context) => [
        _menuButton(
          context,
          icon: Icons.school,
          label: 'Bursları Gör',
          onTap: () => _showComingSoon(context),
        ),
        _menuButton(
          context,
          icon: Icons.assessment,
          label: 'Eşleşme Sonuçlarım',
          onTap: () => _showComingSoon(context),
        ),
        _menuButton(
          context,
          icon: Icons.people,
          label: 'Tüm Öğrenciler',
          onTap: () => _showComingSoon(context),
        ),
      ];

  List<Widget> _donorButtons(BuildContext context) => [
        _menuButton(
          context,
          icon: Icons.list_alt,
          label: 'Burslarım',
          onTap: () => _showComingSoon(context),
        ),
        _menuButton(
          context,
          icon: Icons.add_circle,
          label: 'Yeni Burs Oluştur',
          onTap: () => _showComingSoon(context),
        ),
      ];

  List<Widget> _adminButtons(BuildContext context) => [
        _menuButton(
          context,
          icon: Icons.verified_user,
          label: 'Donör Doğrula',
          onTap: () => _showComingSoon(context),
        ),
        _menuButton(
          context,
          icon: Icons.school,
          label: 'Tüm Öğrenciler',
          onTap: () => _showComingSoon(context),
        ),
        _menuButton(
          context,
          icon: Icons.business,
          label: 'Tüm Donörler',
          onTap: () => _showComingSoon(context),
        ),
        _menuButton(
          context,
          icon: Icons.category,
          label: 'Departman Yönetimi',
          onTap: () => _showComingSoon(context),
        ),
      ];

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bu özellik henüz eklenmedi')),
    );
  }

  Widget _menuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
