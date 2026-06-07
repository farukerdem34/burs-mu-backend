import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/screen_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_provider.dart';
import '../../models/user_role.dart';
import '../../widgets/stacked_notification.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';

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
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, authState, ref),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(context.w(20), context.h(24), context.w(20), context.h(32)),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildGreeting(context, authState),
                SizedBox(height: context.h(24)),
                if (role == UserRole.student) ..._studentContent(context, authState.token),
                if (role == UserRole.donor) ..._donorContent(context, authState.token),
                if (role == UserRole.admin) ..._adminContent(context, ref),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(
      BuildContext context, AuthState authState, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return SliverAppBar(
      expandedHeight: context.screenHeight * 0.28,
      pinned: true,
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary,
                cs.primary.withAlpha(200),
                Color.lerp(cs.primary, cs.tertiary, 0.3)!,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(context.w(20), context.h(16), context.w(20), context.h(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: context.w(36),
                        height: context.w(36),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(context.w(10)),
                        ),
                        child: const Icon(
                          Icons.school,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: context.w(36),
                        height: context.w(36),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(context.w(10)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white, size: 20),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: context.w(8)),
                      Container(
                        width: context.w(36),
                        height: context.w(36),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(context.w(10)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                          onPressed: () async {
                            await ref
                                .read(authProvider.notifier)
                                .logout();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        width: context.w(32),
                        height: context.w(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (authState.role?.displayName.isNotEmpty == true
                                    ? authState.role!.displayName[0]
                                    : '?')
                                .toUpperCase(),
                            style: AppTheme.publicSans(context,
                              size: 18, weight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(width: context.w(12)),
                      Text(
                        authState.role?.displayName ?? '',
                        style: AppTheme.publicSans(context,
                          size: 14, weight: FontWeight.w500,
                          color: Colors.white.withAlpha(200),
                          letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, AuthState authState) {
    final cs = Theme.of(context).colorScheme;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Günaydın'
        : hour < 18
            ? 'Merhaba'
            : 'İyi Akşamlar';

    return Text(
      greeting,
      style: AppTheme.notoSerif(context,
        size: 24, weight: FontWeight.w700, height: 1.2, color: cs.onSurface),
    );
  }

  List<Widget> _studentContent(BuildContext context, String? profileId) {
    final cs = Theme.of(context).colorScheme;

    return [
      _buildSectionTitle('İşlemler', context),
      SizedBox(height: context.h(12)),
      _buildActionCard(
        context,
        icon: Icons.account_balance,
        iconBgColor: cs.primary,
        title: 'Bursları Keşfet',
        subtitle: 'Size uygun bursları görüntüleyin',
        onTap: () => context.push('/scholarships'),
      ),
      SizedBox(height: context.h(12)),
      _buildActionCard(
        context,
        icon: Icons.assessment,
        iconBgColor: cs.tertiary,
        title: 'Eşleşme Sonuçlarım',
        subtitle: 'Burs eşleşme puanlarınızı inceleyin',
        onTap: () => context.push('/match'),
      ),
      SizedBox(height: context.h(12)),
      _buildActionCard(
        context,
        icon: Icons.edit,
        iconBgColor: const Color(0xFF7B61FF),
        title: 'Profilimi Düzenle',
        subtitle: 'Öğrenci bilgilerinizi güncelleyin',
        onTap: () {
          if (profileId != null) {
            context.push('/students/$profileId/edit');
          }
        },
      ),
    ];
  }

  List<Widget> _donorContent(BuildContext context, String? profileId) {
    final cs = Theme.of(context).colorScheme;

    return [
      SizedBox(height: context.h(12)),
      _buildSectionTitle('İşlemler', context),
      SizedBox(height: context.h(12)),
      _buildActionCard(
        context,
        icon: Icons.list_alt,
        iconBgColor: cs.primary,
        title: 'Burslarım',
        subtitle: 'Oluşturduğunuz bursları yönetin',
        onTap: () => profileId != null
            ? context.push('/donors/$profileId/scholarships')
            : context.push('/scholarships'),
      ),
      SizedBox(height: context.h(12)),
      _buildActionCard(
        context,
        icon: Icons.add_circle,
        iconBgColor: const Color(0xFF3068CC),
        title: 'Yeni Burs Oluştur',
        subtitle: 'Yeni bir burs ilanı ekleyin',
        onTap: () => context.push('/scholarships/create'),
      ),
    ];
  }

  List<Widget> _adminContent(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return [
      _buildSectionTitle('Yönetim', context),
      SizedBox(height: context.h(12)),
      _buildActionCard(
        context,
        icon: Icons.verified_user,
        iconBgColor: cs.primary,
        title: 'Donör Doğrula',
        subtitle: 'Donör hesaplarını onaylayın',
        onTap: () => context.push('/admin/verify-donors'),
      ),
      SizedBox(height: context.h(12)),
      _buildActionCard(
        context,
        icon: Icons.business,
        iconBgColor: cs.tertiary,
        title: 'Tüm Donörler',
        subtitle: 'Donör listesini görüntüleyin',
        onTap: () => context.push('/donors'),
      ),
      SizedBox(height: context.h(12)),

      _buildActionCard(
        context,
        icon: Icons.add_circle,
        iconBgColor: const Color(0xFF3068CC),
        title: 'Yeni Burs Oluştur',
        subtitle: 'Yeni bir burs ilanı ekleyin',
        onTap: () => context.push('/scholarships/create'),
      ),
      SizedBox(height: context.h(12)),
      _buildActionCard(
        context,
        icon: Icons.category,
        iconBgColor: const Color(0xFF7B61FF),
        title: 'Departman Yönetimi',
        subtitle: 'Bölümleri ekleyin veya kaldırın',
        onTap: () => context.push('/admin/departments'),
      ),
      SizedBox(height: context.h(24)),
      _buildSectionTitle('Eşleştirme', context),
      SizedBox(height: context.h(12)),
      _buildActionCard(
        context,
        icon: Icons.sync,
        iconBgColor: const Color(0xFFE11D48),
        title: 'Eşleştirmeyi Çalıştır',
        subtitle: 'Tüm öğrenciler için eşleştirme yapın',
        onTap: () async {
          try {
            await ref.read(matchServiceProvider).runMatching();
            if (context.mounted) {
              ref.read(notificationStackProvider.notifier).show(
                'Eşleştirme başlatıldı',
              );
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
      ),
    ];
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Text(
      title,
      style: AppTheme.notoSerif(context,
        size: 20, weight: FontWeight.w600, height: 1.3, color: cs.onSurface),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.mdRadius),
        child: Container(
          padding: EdgeInsets.all(context.w(16)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.mdRadius),
            border: Border.all(color: cs.outlineVariant.withAlpha(25)),
          ),
          child: Row(
            children: [
              Container(
                width: context.w(48),
                height: context.w(48),
                decoration: BoxDecoration(
                  color: iconBgColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(context.w(14)),
                ),
                child: Icon(icon, color: iconBgColor, size: context.f(24)),
              ),
              SizedBox(width: context.w(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.inter(context,
                        size: 15, weight: FontWeight.w600, height: 1.3, color: cs.onSurface),
                    ),
                    SizedBox(height: context.h(2)),
                    Text(
                      subtitle,
                      style: AppTheme.inter(context,
                        size: 13, height: 1.4, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.outline, size: context.f(20)),
            ],
          ),
        ),
      ),
    );
  }
}
