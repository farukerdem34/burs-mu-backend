import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/reference_service.dart';
import '../../models/register_request.dart';
import '../../models/user_role.dart';
import '../../models/income_level.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _gpaController = TextEditingController();
  TextEditingController? _deptController;

  UserRole _role = UserRole.student;
  String? _selectedCity;
  IncomeLevel? _incomeStatus;
  List<String> _cities = [];
  List<String> _departments = [];
  bool _isLoadingRefs = true;
  String? _refsError;
  int _currentStep = 0;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReferences());
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.03, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
  }

  Future<void> _loadReferences() async {
    setState(() {
      _isLoadingRefs = true;
      _refsError = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final refService = ReferenceService(dio);
      final results = await Future.wait([
        refService.getCities(),
        refService.getDepartments(),
      ]);
      if (mounted) {
        setState(() {
          _cities = results[0]
              .map((e) => e.name ?? '')
              .where((n) => n.isNotEmpty)
              .toList();
          _departments = results[1]
              .map((e) => e.name ?? '')
              .where((n) => n.isNotEmpty)
              .toList();
          _isLoadingRefs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _refsError = 'Referanslar yüklenemedi: $e';
          _isLoadingRefs = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _gpaController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'E-posta girin';
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) return 'Geçerli bir e-posta girin';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Şifre girin';

    int score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[a-z]').hasMatch(value)) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) score++;

    if (score < 3) {
      return 'Şifre çok zayıf. En az 8 karakter, büyük/küçük harf, rakam ve özel karakter içermeli';
    }
    if (score < 4) {
      return 'Şifre yeterince güçlü değil. Rakam ve özel karakter ekleyin';
    }
    return null;
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
    _slideController.reset();
    _slideController.forward();
  }

  void _prevStep() {
    setState(() {
      _currentStep--;
    });
    _slideController.reset();
    _slideController.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final request = RegisterRequest(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _role,
      city: _role == UserRole.student ? _selectedCity : null,
      department: _role == UserRole.student ? _deptController?.text.trim() : null,
      incomeStatus: _role == UserRole.student ? _incomeStatus : null,
      gpa: _role == UserRole.student && _gpaController.text.isNotEmpty
          ? double.tryParse(_gpaController.text)
          : null,
    );

    await ref.read(authProvider.notifier).register(request);

    if (mounted && ref.read(authProvider).status == AuthStatus.authenticated) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kayıt Ol',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.surface,
              cs.surfaceContainerLow,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStepIndicator(cs),
                const SizedBox(height: 24),
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildCurrentStep(cs),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(ColorScheme cs) {
    final steps = _role == UserRole.student
        ? ['Hesap', 'Profil', 'Tamamla']
        : ['Hesap', 'Tamamla'];

    return Column(
      children: [
        Row(
          children: List.generate(steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              final stepIdx = i ~/ 2;
              final isActive = stepIdx == _currentStep;
              final isPast = stepIdx < _currentStep;
              return Expanded(
                child: Container(
                  height: 2,
                  color: isPast || isActive
                      ? cs.primary
                      : cs.outlineVariant.withAlpha(80),
                ),
              );
            }
            final stepIdx = i ~/ 2;
            final isActive = stepIdx == _currentStep;
            final isPast = stepIdx < _currentStep;
            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPast || isActive
                    ? cs.primary
                    : Colors.transparent,
                border: Border.all(
                  color: isPast || isActive
                      ? cs.primary
                      : cs.outlineVariant,
                  width: 2,
                ),
              ),
              child: Center(
                child: isPast
                    ? Icon(Icons.check, size: 16, color: cs.onPrimary)
                    : Text(
                        '${stepIdx + 1}',
                        style: GoogleFonts.publicSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? cs.onPrimary
                              : cs.onSurfaceVariant,
                        ),
                      ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              return const Expanded(child: SizedBox());
            }
            final stepIdx = i ~/ 2;
            return Expanded(
              child: Text(
                steps[stepIdx],
                textAlign: TextAlign.center,
                style: GoogleFonts.publicSans(
                  fontSize: 11,
                  fontWeight:
                      stepIdx == _currentStep ? FontWeight.w600 : FontWeight.w500,
                  color: stepIdx == _currentStep
                      ? cs.primary
                      : cs.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(ColorScheme cs) {
    switch (_currentStep) {
      case 0:
        return _buildAccountStep(cs);
      case 1:
        if (_role == UserRole.student) return _buildProfileStep(cs);
        return _buildReviewStep(cs);
      case 2:
        return _buildReviewStep(cs);
      default:
        return _buildAccountStep(cs);
    }
  }

  Widget _buildSectionTitle(String title, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.notoSerif(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: cs.onSurface,
        ),
      ),
    );
  }

  Widget _buildAccountStep(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Hesap Bilgileri', cs),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(230),
            borderRadius: BorderRadius.circular(AppTheme.lgRadius),
            border: Border.all(color: cs.outlineVariant.withAlpha(25)),
          ),
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.mail_outline, size: 20),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: _validateEmail,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: Icon(Icons.lock_outline, size: 20),
                ),
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: _validatePassword,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                items: UserRole.values
                    .where((r) => r != UserRole.admin)
                    .map((r) => DropdownMenuItem(
                        value: r, child: Text(r.name)))
                    .toList(),
                onChanged: (v) => setState(() => _role = v!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
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
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Devam Et'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStep(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Öğrenci Profili', cs),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(230),
            borderRadius: BorderRadius.circular(AppTheme.lgRadius),
            border: Border.all(color: cs.outlineVariant.withAlpha(25)),
          ),
          child: _isLoadingRefs
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _refsError != null
                  ? Column(
                      children: [
                        Icon(Icons.cloud_off, size: 40, color: cs.error),
                        const SizedBox(height: 12),
                        Text(
                          _refsError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.error, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _loadReferences,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Tekrar Dene'),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCity,
                          decoration: const InputDecoration(
                            labelText: 'Şehir',
                            prefixIcon: Icon(Icons.location_city, size: 20),
                          ),
                          items: _cities
                              .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCity = v),
                          validator: (v) =>
                              v == null ? 'Şehir seçin' : null,
                        ),
                        const SizedBox(height: 20),
                        Autocomplete<String>(
                          optionsBuilder: (textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return _departments;
                            }
                            return _departments.where((d) => d
                                .toLowerCase()
                                .contains(
                                    textEditingValue.text.toLowerCase()));
                          },
                          onSelected: (v) => _deptController?.text = v,
                          fieldViewBuilder: (context, controller,
                              focusNode, onSubmitted) {
                            _deptController = controller;
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Bölüm',
                                hintText: 'Ara veya yazın',
                                prefixIcon:
                                    Icon(Icons.school_outlined, size: 20),
                              ),
                              validator: (v) => v != null &&
                                      v.trim().isNotEmpty
                                  ? null
                                  : 'Bölüm girin',
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<IncomeLevel>(
                          initialValue: _incomeStatus,
                          decoration: const InputDecoration(
                            labelText: 'Gelir Düzeyi',
                            prefixIcon: Icon(Icons.monetization_on_outlined,
                                size: 20),
                          ),
                          items: IncomeLevel.values
                              .map((l) => DropdownMenuItem(
                                  value: l,
                                  child: Text(l.displayName)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _incomeStatus = v),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _gpaController,
                          decoration: const InputDecoration(
                            labelText: 'GPA (opsiyonel)',
                            prefixIcon:
                                Icon(Icons.stars_outlined, size: 20),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.smRadius),
                  ),
                ),
                child: const Text('Geri'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppTheme.smRadius),
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
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Devam Et'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewStep(ColorScheme cs) {
    final authState = ref.watch(authProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Bilgilerinizi Onaylayın', cs),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(230),
            borderRadius: BorderRadius.circular(AppTheme.lgRadius),
            border: Border.all(color: cs.outlineVariant.withAlpha(25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoRow('E-posta', _emailController.text, cs),
              const SizedBox(height: 16),
              _buildInfoRow('Rol', _role.name, cs),
              if (_role == UserRole.student) ...[
                const SizedBox(height: 16),
                _buildInfoRow('Şehir', _selectedCity ?? '-', cs),
                const SizedBox(height: 16),
                _buildInfoRow(
                    'Bölüm', _deptController?.text ?? '-', cs),
                const SizedBox(height: 16),
                _buildInfoRow(
                    'Gelir Düzeyi',
                    _incomeStatus?.displayName ?? '-',
                    cs),
                const SizedBox(height: 16),
                _buildInfoRow(
                    'GPA',
                    _gpaController.text.isNotEmpty
                        ? _gpaController.text
                        : '-',
                    cs),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
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
                      style: TextStyle(color: cs.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.smRadius),
                  ),
                ),
                child: const Text('Geri'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppTheme.smRadius),
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
                    onPressed: authState.status == AuthStatus.loading
                        ? null
                        : _submit,
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
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Kayıt Ol'),
                              SizedBox(width: 8),
                              Icon(Icons.check_circle_outline, size: 20),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Zaten hesabın var mı?',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () => context.go('/login'),
              style: TextButton.styleFrom(
                foregroundColor: cs.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Giriş Yap'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.publicSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
