import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/screen_utils.dart';
import '../../services/reference_service.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants.dart';
import '../../widgets/stacked_notification.dart';

class DepartmentManageScreen extends ConsumerStatefulWidget {
  const DepartmentManageScreen({super.key});

  @override
  ConsumerState<DepartmentManageScreen> createState() =>
      _DepartmentManageScreenState();
}

class _DepartmentManageScreenState
    extends ConsumerState<DepartmentManageScreen> {
  List<String> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final dio = ref.read(dioProvider);
    final refService = ReferenceService(dio);
    try {
      final deps = await refService.getDepartments();
      setState(() {
        _departments =
            deps.map((e) => e.name ?? '').where((n) => n.isNotEmpty).toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createDepartment(String name) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post(ApiConstants.departments, data: {'name': name});
      if (mounted) {
        ref.read(notificationStackProvider.notifier).show('"$name" oluşturuldu');
        _loadDepartments();
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationStackProvider.notifier).show('Hata: $e', isError: true);
      }
    }
  }

  Future<void> _showCreateDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Departman Ekle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Departman adı',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await _createDepartment(name);
    }
  }

  Future<void> _deleteDepartment(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Departmanı Sil'),
        content: Text('"$name" departmanını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final dio = ref.read(dioProvider);
      final refService = ReferenceService(dio);
      await refService.deleteDepartment(name);
      if (mounted) {
        ref.read(notificationStackProvider.notifier).show('"$name" silindi');
        _loadDepartments();
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
        appBar: AppBar(title: const Text('Departman Yönetimi')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Departman Yönetimi')),
      body: _departments.isEmpty
          ? const Center(child: Text('Henüz departman yok'))
          : ListView.builder(
              itemCount: _departments.length,
              itemBuilder: (context, index) {
                final dept = _departments[index];
                return Dismissible(
                  key: ValueKey(dept),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: context.w(24)),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteDepartment(dept),
                  child: ListTile(
                    title: Text(dept),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteDepartment(dept),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
