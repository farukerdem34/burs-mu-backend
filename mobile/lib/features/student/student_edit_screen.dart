import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/update_student_request.dart';
import '../../models/income_level.dart';
import '../../providers/student_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/stacked_notification.dart';
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
  bool _isSaving = false;

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

      if (mounted) {
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
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

    setState(() => _isSaving = true);

    try {
      final request = UpdateStudentRequest(
        city: _selectedCity,
        department: _selectedDepartment,
        incomeStatus: _incomeStatus,
        gpa: double.tryParse(_gpaController.text),
        about: _aboutController.text.trim().isEmpty
            ? null
            : _aboutController.text.trim(),
      );

      await ref.read(studentUpdateProvider).update(widget.profileId, request);

      if (mounted) {
        ref.read(notificationStackProvider.notifier).show('Profil güncellendi');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationStackProvider.notifier).show(
          'Güncelleme hatası: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profili Düzenle',
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionTitle('Öğrenci Bilgileri', cs),
                      const SizedBox(height: 4),
                      _buildCard(
                        cs,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCity,
                            decoration: const InputDecoration(
                              labelText: 'Şehir',
                              prefixIcon:
                                  Icon(Icons.location_city, size: 20),
                            ),
                            items: _cities
                                .map((c) => DropdownMenuItem(
                                    value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCity = v),
                          ),
                          const SizedBox(height: 20),
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
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<IncomeLevel>(
                            initialValue: _incomeStatus,
                            decoration: const InputDecoration(
                              labelText: 'Gelir Düzeyi',
                              prefixIcon: Icon(
                                  Icons.monetization_on_outlined,
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
                              labelText: 'GPA',
                              prefixIcon:
                                  Icon(Icons.stars_outlined, size: 20),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _aboutController,
                            decoration: const InputDecoration(
                              labelText: 'Hakkında',
                              prefixIcon:
                                  Icon(Icons.info_outline, size: 20),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
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
                            onPressed: _isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.transparent,
                              disabledForegroundColor: Colors.white38,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text('Değişiklikleri Kaydet'),
                                      SizedBox(width: 8),
                                      Icon(Icons.check_circle_outline,
                                          size: 20),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
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

  Widget _buildCard(ColorScheme cs, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(AppTheme.lgRadius),
        border: Border.all(color: cs.outlineVariant.withAlpha(25)),
      ),
      child: Column(children: children),
    );
  }
}
