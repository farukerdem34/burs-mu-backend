import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/create_scholarship_request.dart';
import '../../models/income_level.dart';
import '../../models/user_role.dart';
import '../../providers/scholarship_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/reference_service.dart';
import '../../widgets/stacked_notification.dart';

class ScholarshipCreateScreen extends ConsumerStatefulWidget {
  const ScholarshipCreateScreen({super.key});

  @override
  ConsumerState<ScholarshipCreateScreen> createState() =>
      _ScholarshipCreateScreenState();
}

class _ScholarshipCreateScreenState
    extends ConsumerState<ScholarshipCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _quotaController = TextEditingController();
  final _minGpaController = TextEditingController();
  final _amountController = TextEditingController();
  final _durationController = TextEditingController();
  final _maxSemesterController = TextEditingController();
  final _minExtracurricularController = TextEditingController();
  final _maxHouseholdIncomeController = TextEditingController();

  bool _isActive = true;
  String? _scholarshipType;
  String? _preferredGender;
  bool _requiresEssay = false;
  bool _requiresInterview = false;
  bool _acceptsDisability = false;
  bool _acceptsOrphan = false;
  bool _acceptsRefugee = false;
  final List<String> _selectedCities = [];
  final List<String> _selectedDepartments = [];
  final List<IncomeLevel> _selectedIncomeLevels = [];
  List<String> _cities = [];
  List<String> _departments = [];

  bool _isLoading = true;

  static const _scholarshipTypes = [
    'full_tuition',
    'partial_tuition',
    'living_stipend',
    'one_time',
  ];

  static const _genders = ['male', 'female'];

  @override
  void initState() {
    super.initState();
    _loadReferences();
  }

  Future<void> _loadReferences() async {
    final dio = ref.read(dioProvider);
    final refService = ReferenceService(dio);
    try {
      final cities = await refService.getCities();
      final departments = await refService.getDepartments();
      setState(() {
        _cities =
            cities.map((e) => e.name ?? '').where((n) => n.isNotEmpty).toList();
        _departments = departments
            .map((e) => e.name ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quotaController.dispose();
    _minGpaController.dispose();
    _amountController.dispose();
    _durationController.dispose();
    _maxSemesterController.dispose();
    _minExtracurricularController.dispose();
    _maxHouseholdIncomeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authProvider);
    final donorId = authState.role == UserRole.donor ? authState.token : null;

    try {
      final request = CreateScholarshipRequest(
        donorId: donorId,
        title: _titleController.text.trim(),
        quota: int.tryParse(_quotaController.text),
        isActive: _isActive,
        minGpa: double.tryParse(_minGpaController.text),
        targetCities:
            _selectedCities.isEmpty ? null : _selectedCities,
        targetDepartments:
            _selectedDepartments.isEmpty ? null : _selectedDepartments,
        targetIncomeLevels:
            _selectedIncomeLevels.isEmpty ? null : _selectedIncomeLevels,
        amountPerYear: double.tryParse(_amountController.text),
        durationMonths: int.tryParse(_durationController.text),
        scholarshipType: _scholarshipType,
        preferredGender: _preferredGender,
        requiresEssay: _requiresEssay ? true : null,
        requiresInterview: _requiresInterview ? true : null,
        acceptsDisability: _acceptsDisability ? true : null,
        acceptsOrphan: _acceptsOrphan ? true : null,
        acceptsRefugee: _acceptsRefugee ? true : null,
        maxSemester: int.tryParse(_maxSemesterController.text),
        minExtracurricularScore: int.tryParse(_minExtracurricularController.text),
        maxHouseholdIncome: double.tryParse(_maxHouseholdIncomeController.text),
      );

      await ref.read(scholarshipServiceProvider).create(request);

      if (mounted) {
        ref.read(notificationStackProvider.notifier).show('Burs oluşturuldu');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationStackProvider.notifier).show('Hata: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yeni Burs')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Burs')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Burs Adı *'),
                validator: (v) =>
                    v != null && v.isNotEmpty ? null : 'Burs adı gerekli',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Yıllık Burs Miktarı (TL)',
                  prefixText: '₺ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Süre (ay)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quotaController,
                decoration: const InputDecoration(labelText: 'Kota'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minGpaController,
                decoration: const InputDecoration(labelText: 'Min GPA'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _scholarshipType,
                decoration: const InputDecoration(labelText: 'Burs Türü'),
                items: _scholarshipTypes
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_scholarshipTypeLabel(t)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _scholarshipType = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _preferredGender,
                decoration: const InputDecoration(labelText: 'Cinsiyet Tercihi'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Farketmez')),
                  ..._genders
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(_genderLabel(g)),
                          )),
                ],
                onChanged: (v) => setState(() => _preferredGender = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxHouseholdIncomeController,
                decoration: const InputDecoration(
                  labelText: 'Maksimum Aile Geliri (TL)',
                  prefixText: '₺ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxSemesterController,
                decoration: const InputDecoration(labelText: 'Maksimum Dönem'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minExtracurricularController,
                decoration: const InputDecoration(
                  labelText: 'Min. Sosyal Aktivite Puanı',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Aktif'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              SwitchListTile(
                title: const Text('Kompozisyon Gerekli'),
                value: _requiresEssay,
                onChanged: (v) => setState(() => _requiresEssay = v),
              ),
              SwitchListTile(
                title: const Text('Mülakat Gerekli'),
                value: _requiresInterview,
                onChanged: (v) => setState(() => _requiresInterview = v),
              ),
              SwitchListTile(
                title: const Text('Engelli Adaylara Açık'),
                value: _acceptsDisability,
                onChanged: (v) => setState(() => _acceptsDisability = v),
              ),
              SwitchListTile(
                title: const Text('Yetim Adaylara Açık'),
                value: _acceptsOrphan,
                onChanged: (v) => setState(() => _acceptsOrphan = v),
              ),
              SwitchListTile(
                title: const Text('Mülteci Adaylara Açık'),
                value: _acceptsRefugee,
                onChanged: (v) => setState(() => _acceptsRefugee = v),
              ),
              const SizedBox(height: 16),
              const Text('Hedef Şehirler (opsiyonel):'),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _cities
                    .map((c) => FilterChip(
                          label: Text(c),
                          selected: _selectedCities.contains(c),
                          onSelected: (sel) {
                            setState(() {
                              if (sel) {
                                _selectedCities.add(c);
                              } else {
                                _selectedCities.remove(c);
                              }
                            });
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              const Text('Hedef Bölümler (opsiyonel):'),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _departments
                    .map((d) => FilterChip(
                          label: Text(d),
                          selected: _selectedDepartments.contains(d),
                          onSelected: (sel) {
                            setState(() {
                              if (sel) {
                                _selectedDepartments.add(d);
                              } else {
                                _selectedDepartments.remove(d);
                              }
                            });
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              const Text('Hedef Gelir Düzeyleri (opsiyonel):'),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: IncomeLevel.values
                    .map((l) => FilterChip(
                          label: Text(l.displayName),
                          selected: _selectedIncomeLevels.contains(l),
                          onSelected: (sel) {
                            setState(() {
                              if (sel) {
                                _selectedIncomeLevels.add(l);
                              } else {
                                _selectedIncomeLevels.remove(l);
                              }
                            });
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Oluştur'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _scholarshipTypeLabel(String type) {
    switch (type) {
      case 'full_tuition':
        return 'Tam Burs';
      case 'partial_tuition':
        return 'Kısmi Burs';
      case 'living_stipend':
        return 'Yaşam Desteği';
      case 'one_time':
        return 'Tek Seferlik';
      default:
        return type;
    }
  }

  String _genderLabel(String gender) {
    switch (gender) {
      case 'male':
        return 'Erkek';
      case 'female':
        return 'Kadın';
      default:
        return gender;
    }
  }
}
