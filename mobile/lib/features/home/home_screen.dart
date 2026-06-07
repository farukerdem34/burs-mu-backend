import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_provider.dart';
import '../../models/user_role.dart';
import '../../widgets/stacked_notification.dart';
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
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, authState, ref),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildGreeting(context, authState),
                const SizedBox(height: 24),
                if (role == UserRole.student) ..._studentContent(context, authState.token),
                if (role == UserRole.donor) ..._donorContent(context),
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
      expandedHeight: 180,
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
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.school,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
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
                        width: 40,
                        height: 40,
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
                            style: GoogleFonts.publicSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        authState.role?.displayName ?? '',
                        style: GoogleFonts.publicSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withAlpha(200),
                          letterSpacing: 0.5,
                        ),
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
      style: GoogleFonts.notoSerif(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: cs.onSurface,
      ),
    );
  }

  List<Widget> _studentContent(BuildContext context, String? profileId) {
    final cs = Theme.of(context).colorScheme;

    return [
      _buildSectionTitle('İşlemler', context),
      const SizedBox(height: 12),
      _buildActionCard(
        context,
        icon: Icons.account_balance,
        iconBgColor: cs.primary,
        title: 'Bursları Keşfet',
        subtitle: 'Size uygun bursları görüntüleyin',
        onTap: () => context.push('/scholarships'),
      ),
      const SizedBox(height: 12),
      _buildActionCard(
        context,
        icon: Icons.assessment,
        iconBgColor: cs.tertiary,
        title: 'Eşleşme Sonuçlarım',
        subtitle: 'Burs eşleşme puanlarınızı inceleyin',
        onTap: () => context.push('/match'),
      ),
      const SizedBox(height: 12),
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

  List<Widget> _donorContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return [
      _buildQuickStats(context),
      const SizedBox(height: 28),
      _buildSectionTitle('İşlemler', context),
      const SizedBox(height: 12),
      _buildActionCard(
        context,
        icon: Icons.list_alt,
        iconBgColor: cs.primary,
        title: 'Burslarım',
        subtitle: 'Oluşturduğunuz bursları yönetin',
        onTap: () => context.push('/scholarships'),
      ),
      const SizedBox(height: 12),
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
      const SizedBox(height: 12),
      _buildActionCard(
        context,
        icon: Icons.verified_user,
        iconBgColor: cs.primary,
        title: 'Donör Doğrula',
        subtitle: 'Donör hesaplarını onaylayın',
        onTap: () => context.push('/admin/verify-donors'),
      ),
      const SizedBox(height: 12),
      _buildActionCard(
        context,
        icon: Icons.business,
        iconBgColor: cs.tertiary,
        title: 'Tüm Donörler',
        subtitle: 'Donör listesini görüntüleyin',
        onTap: () => context.push('/donors'),
      ),
      const SizedBox(height: 12),

      _buildActionCard(
        context,
        icon: Icons.add_circle,
        iconBgColor: const Color(0xFF3068CC),
        title: 'Yeni Burs Oluştur',
        subtitle: 'Yeni bir burs ilanı ekleyin',
        onTap: () => context.push('/scholarships/create'),
      ),
      const SizedBox(height: 12),
      _buildActionCard(
        context,
        icon: Icons.category,
        iconBgColor: const Color(0xFF7B61FF),
        title: 'Departman Yönetimi',
        subtitle: 'Bölümleri ekleyin veya kaldırın',
        onTap: () => context.push('/admin/departments'),
      ),
      const SizedBox(height: 24),
      _buildSectionTitle('Eşleştirme', context),
      const SizedBox(height: 12),
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

  Widget _buildQuickStats(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 88,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.mdRadius),
                border: Border.all(color: cs.outlineVariant.withAlpha(25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.account_balance, color: cs.primary, size: 22),
                  const Spacer(),
                  Text(
                    'Burslar',
                    style: GoogleFonts.publicSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.mdRadius),
                border: Border.all(color: cs.outlineVariant.withAlpha(25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.assessment, color: cs.tertiary, size: 22),
                  const Spacer(),
                  Text(
                    'Eşleşmeler',
                    style: GoogleFonts.publicSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.mdRadius),
                border: Border.all(color: cs.outlineVariant.withAlpha(25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.stars_outlined,
                      color: const Color(0xFF7B61FF), size: 22),
                  const Spacer(),
                  Text(
                    'Puan',
                    style: GoogleFonts.publicSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Text(
      title,
      style: GoogleFonts.notoSerif(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: cs.onSurface,
      ),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.mdRadius),
            border: Border.all(color: cs.outlineVariant.withAlpha(25)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconBgColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.4,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
