import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeSlide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeSlide = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (mounted && ref.read(authProvider).status == AuthStatus.authenticated) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.surface,
              cs.surfaceContainerLow,
              cs.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeSlide,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(_fadeSlide),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHero(context),
                      const SizedBox(height: 40),
                      _buildFormCard(context, authState),
                      const SizedBox(height: 24),
                      _buildFooter(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: AppTheme.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withAlpha(50),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.school, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        Text(
          'Burs Eşleştirme',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Size en uygun bursu bulalım',
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.4,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context, AuthState authState) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(AppTheme.lgRadius),
        border: Border.all(
          color: cs.outlineVariant.withAlpha(25),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icon(Icons.mail_outline, size: 20),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v != null && v.contains('@') ? null : 'Geçerli bir e-posta girin',
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Şifre',
                prefixIcon: Icon(Icons.lock_outline, size: 20),
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (v) =>
                  v != null && v.isNotEmpty ? null : 'Şifre girin',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: cs.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Şifremi Unuttum'),
              ),
            ),
            const SizedBox(height: 12),
            if (authState.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.error.withAlpha(12),
                    borderRadius: BorderRadius.circular(AppTheme.smRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: cs.error, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          authState.error!,
                          style: TextStyle(
                            color: cs.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.smRadius),
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withAlpha(60),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed:
                      authState.status == AuthStatus.loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor: Colors.white38,
                  ),
                  child: authState.status == AuthStatus.loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Giriş Yap'),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Hesabın yok mu?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () => context.push('/register'),
          style: TextButton.styleFrom(
            foregroundColor: cs.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Kayıt Ol'),
        ),
      ],
    );
  }
}
