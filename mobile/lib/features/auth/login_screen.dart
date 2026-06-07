import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/screen_utils.dart';
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
              padding: EdgeInsets.symmetric(horizontal: context.w(24)),
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
                      SizedBox(height: context.h(40)),
                      _buildFormCard(context, authState),
                      SizedBox(height: context.h(24)),
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
          width: context.w(80),
          height: context.w(80),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.w(20)),
            gradient: AppTheme.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withAlpha(50),
                blurRadius: context.w(24),
                offset: Offset(0, context.h(8)),
              ),
            ],
          ),
          child: Icon(Icons.school, color: Colors.white, size: context.f(40)),
        ),
        SizedBox(height: context.h(20)),
        Text(
          'Burs Eşleştirme',
          style: AppTheme.notoSerif(context, size: 28, weight: FontWeight.w700, height: 1.2, color: cs.onSurface),
        ),
        SizedBox(height: context.h(6)),
        Text(
          'Size en uygun bursu bulalım',
          style: AppTheme.inter(context, size: 15, height: 1.4, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context, AuthState authState) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(28)),
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
            SizedBox(height: context.h(20)),
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
            SizedBox(height: context.h(8)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: cs.primary,
                  padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(4)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Şifremi Unuttum', style: AppTheme.inter(context, size: 14, color: cs.primary, weight: FontWeight.w500)),
              ),
            ),
            SizedBox(height: context.h(12)),
            if (authState.error != null)
              Padding(
                padding: EdgeInsets.only(bottom: context.h(16)),
                child: Container(
                  padding: EdgeInsets.all(context.w(12)),
                  decoration: BoxDecoration(
                    color: cs.error.withAlpha(12),
                    borderRadius: BorderRadius.circular(AppTheme.smRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: cs.error, size: context.f(18)),
                      SizedBox(width: context.w(8)),
                      Flexible(
                        child: Text(
                          authState.error!,
                          style: TextStyle(
                            color: cs.error,
                            fontSize: context.f(13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(
              height: context.h(52),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.smRadius),
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withAlpha(60),
                      blurRadius: context.w(16),
                      offset: Offset(0, context.h(4)),
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
                      ? SizedBox(
                          height: context.f(22),
                          width: context.f(22),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Giriş Yap'),
                            SizedBox(width: context.w(8)),
                            Icon(Icons.arrow_forward, size: context.f(18)),
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
          style: AppTheme.inter(context, size: 14, color: cs.onSurfaceVariant),
        ),
        SizedBox(width: context.w(4)),
        TextButton(
          onPressed: () => context.push('/register'),
          style: TextButton.styleFrom(
            foregroundColor: cs.primary,
            padding: EdgeInsets.symmetric(horizontal: context.w(8)),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Kayıt Ol'),
        ),
      ],
    );
  }
}
