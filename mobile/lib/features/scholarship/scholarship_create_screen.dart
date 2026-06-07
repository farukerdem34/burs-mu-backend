import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/screen_utils.dart';
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

  Future<void> _showMultiSelectDialog({
    required String title,
    required List<String> allItems,
    required List<String> currentSelection,
    required void Function(List<String>) onDone,
  }) async {
    final searchController = TextEditingController();
    final selected = List<String>.from(currentSelection);

    await showDialog(
      context: context,
      builder: (ctx) {
        var searchQuery = '';
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = searchQuery.isEmpty
                ? allItems
                : allItems
                    .where((i) =>
                        i.toLowerCase().contains(searchQuery.toLowerCase()))
                    .toList();
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Ara...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        searchQuery = v;
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: filtered.map((item) {
                          final isSelected = selected.contains(item);
                          return CheckboxListTile(
                            title: Text(item),
                            value: isSelected,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (_) {
                              setDialogState(() {
                                if (isSelected) {
                                  selected.remove(item);
                                } else {
                                  selected.add(item);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    searchController.dispose();
                    Navigator.pop(ctx);
                  },
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed: () {
                    searchController.dispose();
                    onDone(selected);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Tamam'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authProvider);
    final donorId = authState.role == UserRole.donor ? authState.token : null;

    try {
      final request = CreateScholarshipRequest(
        donorId: donorId,
        title: _titleController.text.trim(),
        quota: int.tryParse(_quotaController.text) ?? 1,
        isActive: _isActive,
        minGpa: double.tryParse(_minGpaController.text) ?? 0.0,
        targetCities:
            _selectedCities.isEmpty ? <String>[] : _selectedCities,
        targetDepartments:
            _selectedDepartments.isEmpty ? <String>[] : _selectedDepartments,
        targetIncomeLevels:
            _selectedIncomeLevels.isEmpty ? <IncomeLevel>[] : _selectedIncomeLevels,
        amountPerYear: double.tryParse(_amountController.text) ?? 0.0,
        durationMonths: int.tryParse(_durationController.text) ?? 12,
        scholarshipType: _scholarshipType ?? 'full_tuition',
        preferredGender: _preferredGender,
        requiresEssay: _requiresEssay,
        requiresInterview: _requiresInterview,
        acceptsDisability: _acceptsDisability,
        acceptsOrphan: _acceptsOrphan,
        acceptsRefugee: _acceptsRefugee,
        maxSemester: int.tryParse(_maxSemesterController.text) ?? 0,
        minExtracurricularScore: int.tryParse(_minExtracurricularController.text) ?? 0,
        maxHouseholdIncome: double.tryParse(_maxHouseholdIncomeController.text) ?? 0.0,
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
        padding: EdgeInsets.all(context.w(24)),
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
              SizedBox(height: context.h(16)),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Yıllık Burs Miktarı (TL)',
                  prefixText: '₺ ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Burs miktarı gerekli';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Geçerli bir miktar girin';
                  return null;
                },
              ),
              SizedBox(height: context.h(16)),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Süre (ay)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Süre gerekli';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Geçerli bir süre girin';
                  return null;
                },
              ),
              SizedBox(height: context.h(16)),
              TextFormField(
                controller: _quotaController,
                decoration: const InputDecoration(labelText: 'Kota'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Kota gerekli';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Geçerli bir kota girin';
                  return null;
                },
              ),
              SizedBox(height: context.h(16)),
              TextFormField(
                controller: _minGpaController,
                decoration: const InputDecoration(labelText: 'Min GPA'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Min GPA gerekli';
                  final n = double.tryParse(v);
                  if (n == null || n < 0 || n > 4) return '0-4 arası girin';
                  return null;
                },
              ),
              SizedBox(height: context.h(16)),
              DropdownButtonFormField<String>(
                initialValue: _scholarshipType,
                decoration: const InputDecoration(labelText: 'Burs Türü *'),
                items: _scholarshipTypes
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_scholarshipTypeLabel(t)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _scholarshipType = v),
                validator: (v) => v == null ? 'Burs türü seçin' : null,
              ),
              SizedBox(height: context.h(16)),
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
              SizedBox(height: context.h(16)),
              TextFormField(
                controller: _maxHouseholdIncomeController,
                decoration: const InputDecoration(
                  labelText: 'Maksimum Aile Geliri (TL)',
                  prefixText: '₺ ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Aile geliri gerekli';
                  final n = double.tryParse(v);
                  if (n == null || n < 0) return 'Geçerli bir gelir girin';
                  return null;
                },
              ),
              SizedBox(height: context.h(16)),
              TextFormField(
                controller: _maxSemesterController,
                decoration: const InputDecoration(labelText: 'Maksimum Dönem'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Dönem gerekli';
                  final n = int.tryParse(v);
                  if (n == null || n < 0) return 'Geçerli bir dönem girin';
                  return null;
                },
              ),
              SizedBox(height: context.h(16)),
              TextFormField(
                controller: _minExtracurricularController,
                decoration: const InputDecoration(
                  labelText: 'Min. Sosyal Aktivite Puanı',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Puan gerekli';
                  final n = int.tryParse(v);
                  if (n == null || n < 0) return 'Geçerli bir puan girin';
                  return null;
                },
              ),
              SizedBox(height: context.h(16)),
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
              InkWell(
                onTap: () => _showMultiSelectDialog(
                  title: 'Hedef Şehirler',
                  allItems: _cities,
                  currentSelection: _selectedCities,
                  onDone: (v) => setState(() => _selectedCities
                    ..clear()
                    ..addAll(v)),
                ),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Hedef Şehirler',
                    suffixIcon: Icon(Icons.search),
                  ),
                  child: _selectedCities.isEmpty
                      ? const Text('Tüm şehirler',
                          style: TextStyle(color: Colors.grey))
                      : Text('${_selectedCities.length} şehir seçildi'),
                ),
              ),
              if (_selectedCities.isNotEmpty) ...[
                SizedBox(height: context.h(4)),
                Wrap(
                  spacing: context.w(4),
                  runSpacing: context.h(4),
                  children: _selectedCities
                      .map((c) => Chip(
                            label: Text(c,
                                style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onDeleted: () =>
                                setState(() => _selectedCities.remove(c)),
                          ))
                      .toList(),
                ),
              ],
              SizedBox(height: context.h(16)),
              InkWell(
                onTap: () => _showMultiSelectDialog(
                  title: 'Hedef Bölümler',
                  allItems: _departments,
                  currentSelection: _selectedDepartments,
                  onDone: (v) => setState(() => _selectedDepartments
                    ..clear()
                    ..addAll(v)),
                ),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Hedef Bölümler',
                    suffixIcon: Icon(Icons.search),
                  ),
                  child: _selectedDepartments.isEmpty
                      ? const Text('Tüm bölümler',
                          style: TextStyle(color: Colors.grey))
                      : Text('${_selectedDepartments.length} bölüm seçildi'),
                ),
              ),
              if (_selectedDepartments.isNotEmpty) ...[
                SizedBox(height: context.h(4)),
                Wrap(
                  spacing: context.w(4),
                  runSpacing: context.h(4),
                  children: _selectedDepartments
                      .map((d) => Chip(
                            label: Text(d,
                                style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onDeleted: () => setState(
                                () => _selectedDepartments.remove(d)),
                          ))
                      .toList(),
                ),
              ],
              SizedBox(height: context.h(16)),
              InkWell(
                onTap: () => _showMultiSelectDialog(
                  title: 'Hedef Gelir Düzeyleri',
                  allItems: IncomeLevel.values
                      .map((l) => l.displayName)
                      .toList(),
                  currentSelection:
                      _selectedIncomeLevels.map((l) => l.displayName).toList(),
                  onDone: (v) => setState(() {
                    final map = <String, IncomeLevel>{
                      for (final l in IncomeLevel.values) l.displayName: l,
                    };
                    _selectedIncomeLevels
                      ..clear()
                      ..addAll(v.map((n) => map[n]).whereType<IncomeLevel>().toList());
                  }),
                ),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Hedef Gelir Düzeyleri',
                    suffixIcon: Icon(Icons.search),
                  ),
                  child: _selectedIncomeLevels.isEmpty
                      ? const Text('Tüm gelir düzeyleri',
                          style: TextStyle(color: Colors.grey))
                      : Text(
                          '${_selectedIncomeLevels.length} gelir düzeyi seçildi'),
                ),
              ),
              if (_selectedIncomeLevels.isNotEmpty) ...[
                SizedBox(height: context.h(4)),
                Wrap(
                  spacing: context.w(4),
                  runSpacing: context.h(4),
                  children: _selectedIncomeLevels
                      .map((l) => Chip(
                            label: Text(l.displayName,
                                style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onDeleted: () => setState(
                                () => _selectedIncomeLevels.remove(l)),
                          ))
                      .toList(),
                ),
              ],
              SizedBox(height: context.h(24)),
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
