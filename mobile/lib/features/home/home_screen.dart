import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
                context.go('/login');
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
          icon: Icons.account_balance,
          label: 'Bursları Gör',
          onTap: () => context.push('/scholarships'),
        ),
        _menuButton(
          context,
          icon: Icons.assessment,
          label: 'Eşleşme Sonuçlarım',
          onTap: () => context.push('/match'),
        ),
      ];

  List<Widget> _donorButtons(BuildContext context) => [
        _menuButton(
          context,
          icon: Icons.list_alt,
          label: 'Burslar',
          onTap: () => context.push('/scholarships'),
        ),
        _menuButton(
          context,
          icon: Icons.add_circle,
          label: 'Yeni Burs Oluştur',
          onTap: () => context.push('/scholarships/create'),
        ),
      ];

  List<Widget> _adminButtons(BuildContext context) => [
        _menuButton(
          context,
          icon: Icons.verified_user,
          label: 'Donör Doğrula',
          onTap: () => context.push('/admin/verify-donors'),
        ),
        _menuButton(
          context,
          icon: Icons.business,
          label: 'Tüm Donörler',
          onTap: () => context.push('/donors'),
        ),
        _menuButton(
          context,
          icon: Icons.category,
          label: 'Departman Yönetimi',
          onTap: () => context.push('/admin/departments'),
        ),
      ];

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
