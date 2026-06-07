import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/create_scholarship_request.dart';
import '../../models/income_level.dart';
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

  bool _isActive = true;
  List<String> _selectedCities = [];
  List<String> _selectedDepartments = [];
  List<IncomeLevel> _selectedIncomeLevels = [];
  List<String> _cities = [];
  List<String> _departments = [];

  bool _isLoading = true;

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
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final request = CreateScholarshipRequest(
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
                decoration: const InputDecoration(labelText: 'Burs Adı'),
                validator: (v) =>
                    v != null && v.isNotEmpty ? null : 'Burs adı gerekli',
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
              SwitchListTile(
                title: const Text('Aktif'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
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
}
