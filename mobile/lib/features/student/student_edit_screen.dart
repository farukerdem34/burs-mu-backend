import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/student_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/update_student_request.dart';
import '../../models/income_level.dart';
import '../../services/reference_service.dart';

class StudentEditScreen extends ConsumerStatefulWidget {
  final String profileId;

  const StudentEditScreen({super.key, required this.profileId});

  @override
  ConsumerState<StudentEditScreen> createState() => _StudentEditScreenState();
}

class _StudentEditScreenState extends ConsumerState<StudentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gpaController = TextEditingController();
  final _aboutController = TextEditingController();

  String? _selectedCity;
  String? _selectedDepartment;
  IncomeLevel? _incomeStatus;
  List<String> _cities = [];
  List<String> _departments = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dio = ref.read(dioProvider);
    final refService = ReferenceService(dio);
    try {
      final cities = await refService.getCities();
      final departments = await refService.getDepartments();
      final student = await ref.read(studentServiceProvider).getById(widget.profileId);

      setState(() {
        _cities = cities.map((e) => e.name ?? '').where((n) => n.isNotEmpty).toList();
        _departments = departments.map((e) => e.name ?? '').where((n) => n.isNotEmpty).toList();
        _selectedCity = student.city;
        _selectedDepartment = student.department;
        _incomeStatus = student.incomeStatus;
        _gpaController.text = student.gpa?.toString() ?? '';
        _aboutController.text = student.about ?? '';
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _gpaController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final request = UpdateStudentRequest(
        city: _selectedCity,
        department: _selectedDepartment,
        incomeStatus: _incomeStatus,
        gpa: double.tryParse(_gpaController.text),
        about: _aboutController.text.trim().isEmpty ? null : _aboutController.text.trim(),
      );

      await ref.read(studentUpdateProvider).update(widget.profileId, request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil güncellendi')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncelleme hatası: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profili Düzenle')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profili Düzenle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedCity,
                decoration: const InputDecoration(labelText: 'Şehir'),
                items: _cities
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCity = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedDepartment,
                decoration: const InputDecoration(labelText: 'Bölüm'),
                items: _departments
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDepartment = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<IncomeLevel>(
                initialValue: _incomeStatus,
                decoration: const InputDecoration(labelText: 'Gelir Düzeyi'),
                items: IncomeLevel.values
                    .map((l) => DropdownMenuItem(value: l, child: Text(l.name)))
                    .toList(),
                onChanged: (v) => setState(() => _incomeStatus = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gpaController,
                decoration: const InputDecoration(labelText: 'GPA'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _aboutController,
                decoration: const InputDecoration(labelText: 'Hakkında'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
