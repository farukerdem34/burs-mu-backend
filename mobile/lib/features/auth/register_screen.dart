import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/screen_utils.dart';
import '../../providers/auth_provider.dart';
import '../../services/reference_service.dart';
import '../../models/register_request.dart';
import '../../models/user_role.dart';
import '../../models/income_level.dart';
import '../../models/academic_standing.dart';

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
  final _nameController = TextEditingController();
  final _gpaController = TextEditingController();
  final _familyIncomeController = TextEditingController();
  final _householdSizeController = TextEditingController();
  final _numSiblingsController = TextEditingController();

  UserRole _role = UserRole.student;
  String? _selectedCity;
  String? _selectedDepartment;
  IncomeLevel? _incomeStatus;
  AcademicStanding? _academicStanding;
  int? _semester;
  int? _extracurricularScore;
  bool _hasDisability = false;
  bool _isOrphan = false;
  bool _isRefugee = false;

  List<String> _cities = [];
  List<String> _departments = [];
  bool _isLoadingRefs = true;
  String? _refsError;
  int _currentStep = 0;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  List<String> get _stepLabels {
    if (_role == UserRole.student) {
      return ['Hesap', 'Profil', 'Akademik', 'Aile', 'Tamamla'];
    }
    return ['Hesap', 'Tamamla'];
  }

  List<IconData> get _stepIcons {
    if (_role == UserRole.student) {
      return [
        Icons.person_outline,
        Icons.description_outlined,
        Icons.school_outlined,
        Icons.family_restroom,
        Icons.check_circle_outlined,
      ];
    }
    return [
      Icons.person_outline,
      Icons.check_circle_outlined,
    ];
  }

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
    _nameController.dispose();
    _gpaController.dispose();
    _familyIncomeController.dispose();
    _householdSizeController.dispose();
    _numSiblingsController.dispose();
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
    setState(() => _currentStep++);
    _slideController.reset();
    _slideController.forward();
  }

  void _prevStep() {
    setState(() => _currentStep--);
    _slideController.reset();
    _slideController.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final request = RegisterRequest(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _role,
      name: _role == UserRole.donor ? _nameController.text.trim() : null,
      city: _role == UserRole.student ? _selectedCity : null,
      department: _role == UserRole.student ? _selectedDepartment : null,
      incomeStatus: _role == UserRole.student ? _incomeStatus : null,
      gpa: _role == UserRole.student && _gpaController.text.isNotEmpty
          ? double.tryParse(_gpaController.text)
          : null,
      semester: _role == UserRole.student ? _semester : null,
      familyIncome:
          _role == UserRole.student && _familyIncomeController.text.isNotEmpty
              ? double.tryParse(_familyIncomeController.text)
              : null,
      householdSize:
          _role == UserRole.student && _householdSizeController.text.isNotEmpty
              ? int.tryParse(_householdSizeController.text)
              : null,
      numSiblingsInEducation:
          _role == UserRole.student && _numSiblingsController.text.isNotEmpty
              ? int.tryParse(_numSiblingsController.text)
              : null,
      hasDisability: _role == UserRole.student ? _hasDisability : null,
      isOrphan: _role == UserRole.student ? _isOrphan : null,
      isRefugee: _role == UserRole.student ? _isRefugee : null,
      academicStanding: _role == UserRole.student ? _academicStanding : null,
      extracurricularScore:
          _role == UserRole.student ? _extracurricularScore : null,
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
          style: AppTheme.inter(context, size: 18, weight: FontWeight.w600, color: cs.onSurface),
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
            colors: [cs.surface, cs.surfaceContainerLow],
          ),
        ),
        child: Column(
          children: [
            _buildStepIndicator(cs, context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(context.w(20), context.h(12), context.w(20), context.h(32)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SlideTransition(
                        position: _slideAnimation,
                        child: _buildCurrentStep(cs, context),
                      ),
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

  Widget _buildStepIndicator(ColorScheme cs, BuildContext context) {
    final steps = _stepLabels;
    final icons = _stepIcons;

    return Padding(
      padding: EdgeInsets.fromLTRB(context.w(20), context.h(16), context.w(20), 0),
      child: Column(
        children: [
          Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                final stepIdx = i ~/ 2;
                final isPast = stepIdx < _currentStep;
                return Expanded(
                  child: Container(
                    height: context.h(2),
                    color: isPast
                        ? cs.primary
                        : cs.outlineVariant.withAlpha(80),
                  ),
                );
              }
              final stepIdx = i ~/ 2;
              final isActive = stepIdx == _currentStep;
              final isPast = stepIdx < _currentStep;
              return Container(
                width: context.w(32),
                height: context.w(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPast || isActive ? cs.primary : Colors.transparent,
                  border: Border.all(
                    color: isPast || isActive ? cs.primary : cs.outlineVariant,
                    width: context.w(2),
                  ),
                ),
                child: Center(
                  child: isPast
                      ? Icon(Icons.check, size: context.f(16), color: cs.onPrimary)
                      : Icon(
                          icons[stepIdx],
                          size: context.f(16),
                          color: isActive
                              ? cs.onPrimary
                              : cs.onSurfaceVariant,
                        ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(ColorScheme cs, BuildContext context) {
    if (_role == UserRole.student) {
      switch (_currentStep) {
        case 0:
          return _buildAccountStep(cs, context);
        case 1:
          return _buildStudentProfileStep(cs, context);
        case 2:
          return _buildAcademicStep(cs, context);
        case 3:
          return _buildFamilyStep(cs, context);
        case 4:
          return _buildReviewStep(cs, context);
      }
    } else {
      switch (_currentStep) {
        case 0:
          return _buildAccountStep(cs, context);
        case 1:
          return _buildReviewStep(cs, context);
      }
    }
    return _buildAccountStep(cs, context);
  }

  Widget _buildSectionTitle(String title, ColorScheme cs, BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(16)),
      child: Text(
        title,
        style: AppTheme.notoSerif(context, size: 20, weight: FontWeight.w600, height: 1.3, color: cs.onSurface),
      ),
    );
  }

  Widget _sectionCard({required Widget child, required BuildContext context}) {
    return Container(
      padding: EdgeInsets.all(context.w(24)),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(AppTheme.lgRadius),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withAlpha(25)),
      ),
      child: child,
    );
  }

  Widget _navButtons({
    required BuildContext context,
    required bool showPrev,
    required VoidCallback? onNext,
    String nextLabel = 'Devam Et',
    IconData nextIcon = Icons.arrow_forward,
  }) {
    return Row(
      children: [
        if (showPrev)
          Expanded(
            child: OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                minimumSize: Size(0, context.h(52)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.smRadius),
                ),
              ),
              child: const Text('Geri'),
            ),
          ),
        if (showPrev) SizedBox(width: context.w(12)),
        Expanded(
          flex: showPrev ? 2 : 1,
          child: SizedBox(
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
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.transparent,
                  disabledForegroundColor: Colors.white38,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(nextLabel),
                    SizedBox(width: context.w(8)),
                    Icon(nextIcon, size: context.f(18)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountStep(ColorScheme cs, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Hesap Bilgileri', cs, context),
        _sectionCard(
          context: context,
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
              SizedBox(height: context.h(20)),
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
              if (_role == UserRole.donor) ...[
                SizedBox(height: context.h(20)),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Kurum veya Kişi Adı',
                    prefixIcon: Icon(Icons.business, size: 20),
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ],
              SizedBox(height: context.h(20)),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                items: UserRole.values
                    .where((r) => r != UserRole.admin)
                    .map((r) => DropdownMenuItem(
                        value: r, child: Text(r.displayName)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _role = v!;
                    _currentStep = 0;
                  });
                  _slideController.reset();
                  _slideController.forward();
                },
              ),
            ],
          ),
        ),
        SizedBox(height: context.h(24)),
        _navButtons(context: context, showPrev: false, onNext: _nextStep),
      ],
    );
  }

  Widget _buildStudentProfileStep(ColorScheme cs, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Öğrenci Profili', cs, context),
        _sectionCard(
          context: context,
          child: _isLoadingRefs
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: context.h(32)),
                  child: const Center(child: CircularProgressIndicator()),
                )
              : _refsError != null
                  ? Column(
                      children: [
                        Icon(Icons.cloud_off, size: context.f(40), color: cs.error),
                        SizedBox(height: context.h(12)),
                        Text(_refsError!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: cs.error, fontSize: context.f(13))),
                        SizedBox(height: context.h(12)),
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
                                  value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedCity = v),
                          validator: (v) => v == null ? 'Şehir seçin' : null,
                        ),
                        SizedBox(height: context.h(20)),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDepartment,
                          decoration: const InputDecoration(
                            labelText: 'Bölüm',
                            prefixIcon:
                                Icon(Icons.school_outlined, size: 20),
                          ),
                          items: _departments
                              .map((d) => DropdownMenuItem(
                                  value: d, child: Text(d)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedDepartment = v),
                          validator: (v) =>
                              v == null ? 'Bölüm seçin' : null,
                        ),
                        SizedBox(height: context.h(20)),
                        DropdownButtonFormField<IncomeLevel>(
                          initialValue: _incomeStatus,
                          decoration: const InputDecoration(
                            labelText: 'Gelir Düzeyi',
                            prefixIcon: Icon(
                                Icons.monetization_on_outlined, size: 20),
                          ),
                          items: IncomeLevel.values
                              .map((l) => DropdownMenuItem(
                                  value: l,
                                  child: Text(l.displayName)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _incomeStatus = v),
                          validator: (v) =>
                              v == null ? 'Gelir düzeyi seçin' : null,
                        ),
                      ],
                    ),
        ),
        SizedBox(height: context.h(24)),
        _navButtons(context: context, showPrev: true, onNext: _nextStep),
      ],
    );
  }

  Widget _buildAcademicStep(ColorScheme cs, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Akademik Bilgiler', cs, context),
        _sectionCard(
          context: context,
          child: Column(
            children: [
              TextFormField(
                controller: _gpaController,
                decoration: const InputDecoration(
                  labelText: 'GPA',
                  hintText: '0.00 - 4.00',
                  prefixIcon: Icon(Icons.stars_outlined, size: 20),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: context.h(20)),
              DropdownButtonFormField<int>(
                initialValue: _semester,
                decoration: const InputDecoration(
                  labelText: 'Dönem',
                  prefixIcon: Icon(Icons.numbers, size: 20),
                ),
                items: List.generate(8, (i) => i + 1).map((s) {
                  final label = switch (s) {
                    1 => '1. Dönem',
                    2 => '2. Dönem',
                    3 => '3. Dönem',
                    4 => '4. Dönem',
                    5 => '5. Dönem',
                    6 => '6. Dönem',
                    7 => '7. Dönem',
                    _ => '8. Dönem',
                  };
                  return DropdownMenuItem(value: s, child: Text(label));
                }).toList(),
                onChanged: (v) => setState(() => _semester = v),
              ),
              SizedBox(height: context.h(20)),
              DropdownButtonFormField<AcademicStanding>(
                initialValue: _academicStanding,
                decoration: const InputDecoration(
                  labelText: 'Akademik Durum',
                  prefixIcon: Icon(Icons.assessment, size: 20),
                ),
                items: AcademicStanding.values
                    .map((a) => DropdownMenuItem(
                        value: a, child: Text(a.displayName)))
                    .toList(),
                onChanged: (v) => setState(() => _academicStanding = v),
              ),
              SizedBox(height: context.h(20)),
              DropdownButtonFormField<int>(
                initialValue: _extracurricularScore,
                decoration: const InputDecoration(
                  labelText: 'Ekstraküler Puan',
                  prefixIcon: Icon(Icons.emoji_events_outlined, size: 20),
                ),
                items: List.generate(11, (i) => i).map((s) {
                  return DropdownMenuItem(value: s, child: Text('$s'));
                }).toList(),
                onChanged: (v) => setState(() => _extracurricularScore = v),
              ),
            ],
          ),
        ),
        SizedBox(height: context.h(24)),
        _navButtons(context: context, showPrev: true, onNext: _nextStep),
      ],
    );
  }

  Widget _buildFamilyStep(ColorScheme cs, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Aile ve Kişisel Bilgiler', cs, context),
        _sectionCard(
          context: context,
          child: Column(
            children: [
              TextFormField(
                controller: _familyIncomeController,
                decoration: const InputDecoration(
                  labelText: 'Aylık Aile Geliri (TL)',
                  prefixIcon: Icon(Icons.account_balance_wallet, size: 20),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: context.h(20)),
              TextFormField(
                controller: _householdSizeController,
                decoration: const InputDecoration(
                  labelText: 'Hane Halkı Sayısı',
                  prefixIcon: Icon(Icons.people, size: 20),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: context.h(20)),
              TextFormField(
                controller: _numSiblingsController,
                decoration: const InputDecoration(
                  labelText: 'Eğitimdeki Kardeş Sayısı',
                  prefixIcon: Icon(Icons.school, size: 20),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: context.h(20)),
              SwitchListTile(
                title: const Text('Engel Durumu'),
                subtitle: const Text('Bir engeliniz var mı?'),
                value: _hasDisability,
                onChanged: (v) => setState(() => _hasDisability = v),
              ),
              SwitchListTile(
                title: const Text('Yetim'),
                subtitle: const Text('Anneniz veya babanız vefat etmiş mi?'),
                value: _isOrphan,
                onChanged: (v) => setState(() => _isOrphan = v),
              ),
              SwitchListTile(
                title: const Text('Mülteci'),
                subtitle: const Text('Mülteci statüsünde misiniz?'),
                value: _isRefugee,
                onChanged: (v) => setState(() => _isRefugee = v),
              ),
            ],
          ),
        ),
        SizedBox(height: context.h(24)),
        _navButtons(context: context, showPrev: true, onNext: _nextStep),
      ],
    );
  }

  Widget _buildReviewStep(ColorScheme cs, BuildContext context) {
    final authState = ref.watch(authProvider);

    String displayValue(String? val) => (val != null && val.isNotEmpty) ? val : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Bilgilerinizi Onaylayın', cs, context),
        _sectionCard(
          context: context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoRow(context, 'E-posta', _emailController.text, cs),
              SizedBox(height: context.h(16)),
              _buildInfoRow(context, 'Rol', _role.displayName, cs),
              if (_role == UserRole.donor) ...[
                const Divider(height: 24),
                _buildInfoRow(context, 'Ad', displayValue(_nameController.text), cs),
              ],
              if (_role == UserRole.student) ...[
                const Divider(height: 24),
                _buildInfoRow(context, 'Şehir', displayValue(_selectedCity), cs),
                SizedBox(height: context.h(16)),
                _buildInfoRow(context, 'Bölüm', displayValue(_selectedDepartment), cs),
                SizedBox(height: context.h(16)),
                _buildInfoRow(context, 'Gelir Düzeyi',
                    _incomeStatus?.displayName ?? '-', cs),
                const Divider(height: 24),
                _buildInfoRow(context, 'GPA',
                    _gpaController.text.isNotEmpty ? _gpaController.text : '-',
                    cs),
                SizedBox(height: context.h(16)),
                _buildInfoRow(context, 'Dönem', _semester?.toString() ?? '-', cs),
                SizedBox(height: context.h(16)),
                _buildInfoRow(context, 'Akademik Durum',
                    _academicStanding?.displayName ?? '-', cs),
                SizedBox(height: context.h(16)),
                _buildInfoRow(context,
                    'Ekstraküler Puan',
                    _extracurricularScore?.toString() ?? '-',
                    cs),
                const Divider(height: 24),
                _buildInfoRow(context, 'Aile Geliri',
                    _familyIncomeController.text.isNotEmpty
                        ? '${_familyIncomeController.text} TL'
                        : '-',
                    cs),
                SizedBox(height: context.h(16)),
                _buildInfoRow(context, 'Hane Halkı',
                    _householdSizeController.text.isNotEmpty
                        ? _householdSizeController.text
                        : '-',
                    cs),
                SizedBox(height: context.h(16)),
                _buildInfoRow(context, 'Eğitimdeki Kardeş',
                    _numSiblingsController.text.isNotEmpty
                        ? _numSiblingsController.text
                        : '-',
                    cs),
                SizedBox(height: context.h(16)),
                _buildInfoRow(context, 'Engel Durumu', _hasDisability ? 'Var' : 'Yok', cs),
                SizedBox(height: context.h(16)),
                _buildInfoRow(context, 'Yetim', _isOrphan ? 'Evet' : 'Hayır', cs),
                SizedBox(height: context.h(16)),
                _buildInfoRow(context, 'Mülteci', _isRefugee ? 'Evet' : 'Hayır', cs),
              ],
            ],
          ),
        ),
        SizedBox(height: context.h(24)),
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
                      style: TextStyle(color: cs.error, fontSize: context.f(13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        _navButtons(
          context: context,
          showPrev: true,
          onNext: authState.status == AuthStatus.loading ? null : _submit,
          nextLabel: 'Kayıt Ol',
          nextIcon: Icons.check_circle_outline,
        ),
        SizedBox(height: context.h(16)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Zaten hesabın var mı?',
              style: AppTheme.inter(context, size: 14, color: cs.onSurfaceVariant),
            ),
            SizedBox(width: context.w(4)),
            TextButton(
              onPressed: () => context.go('/login'),
              style: TextButton.styleFrom(
                foregroundColor: cs.primary,
                padding: EdgeInsets.symmetric(horizontal: context.w(8)),
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

  Widget _buildInfoRow(BuildContext context, String label, String value, ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: context.w(130),
          child: Text(
            label,
            style: AppTheme.publicSans(context, size: 12, weight: FontWeight.w500, letterSpacing: 0.5, color: cs.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTheme.inter(context, size: 14, weight: FontWeight.w500, color: cs.onSurface),
          ),
        ),
      ],
    );
  }
}
