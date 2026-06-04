import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/reference_service.dart';
import '../../models/register_request.dart';
import '../../models/user_role.dart';
import '../../models/income_level.dart';
import '../home/home_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReferences());
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
    super.dispose();
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-posta'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v != null && v.contains('@') ? null : 'Geçerli bir e-posta girin',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Şifre'),
                obscureText: true,
                validator: (v) =>
                    v != null && v.length >= 6 ? null : 'Şifre en az 6 karakter olmalı',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: UserRole.values
                    .where((r) => r != UserRole.admin)
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                    .toList(),
                onChanged: (v) => setState(() => _role = v!),
              ),
              if (_role == UserRole.student) ...[
                const SizedBox(height: 16),
                if (_isLoadingRefs)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_refsError != null)
                  Column(
                    children: [
                      Text(
                        _refsError!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _loadReferences,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar Dene'),
                      ),
                    ],
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCity,
                    decoration: const InputDecoration(labelText: 'Şehir'),
                    items: _cities
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCity = v),
                    validator: (v) => v == null ? 'Şehir seçin' : null,
                  ),
                  const SizedBox(height: 16),
                  Autocomplete<String>(
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _departments;
                      }
                      return _departments.where((d) => d
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (v) => _deptController?.text = v,
                    fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                      _deptController = controller;
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Bölüm',
                          hintText: 'Ara veya yazın',
                        ),
                        validator: (v) =>
                            v != null && v.trim().isNotEmpty ? null : 'Bölüm girin',
                      );
                    },
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
                    decoration: const InputDecoration(labelText: 'GPA (opsiyonel)'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
              const SizedBox(height: 24),
              if (authState.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    authState.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ElevatedButton(
                onPressed: authState.status == AuthStatus.loading ? null : _submit,
                child: authState.status == AuthStatus.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kayıt Ol'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Zaten hesabın var mı? Giriş Yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
