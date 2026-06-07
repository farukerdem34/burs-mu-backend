import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api_config.dart';
import '../../core/secure_storage.dart';
import '../../core/theme.dart';
import '../../core/screen_utils.dart';
import '../../services/api_client.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  bool _useHttps = false;
  bool _saving = false;
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await SecureStorage.getApiConfig();
    if (config != null) {
      _hostController.text = config.host;
      _portController.text = config.port.toString();
      setState(() => _useHttps = config.useHttps);
    } else {
      _hostController.text = '127.0.0.1';
      _portController.text = '8080';
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  ApiConfig _buildConfig() {
    final host = _hostController.text.trim().isEmpty ? '127.0.0.1' : _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8080;
    return ApiConfig(host: host, port: port, useHttps: _useHttps);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final config = _buildConfig();
      await SecureStorage.saveApiConfig(config);
      ApiClient.setBaseUrl(config);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayarlar kaydedildi')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final config = _buildConfig();
      final dio = Dio(BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final response = await dio.get('/health');
      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _testResult = 'Başarılı!';
            _testing = false;
          });
        } else {
          setState(() {
            _testResult = 'Bağlantı Başarısız';
            _testing = false;
          });
        }
      }
    } on DioException catch (_) {
      if (mounted) {
        setState(() {
          _testResult = 'Bağlantı Başarısız';
          _testing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _testResult = 'Bağlantı Başarısız';
          _testing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('API Ayarları'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.w(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sunucu Yapılandırması',
              style: AppTheme.notoSerif(context,
                size: 22, weight: FontWeight.w600, color: cs.onSurface),
            ),
            SizedBox(height: context.h(8)),
            Text(
              'API sunucusunun adresini, portunu ve protokolünü ayarlayın.',
              style: AppTheme.inter(context,
                size: 14, color: cs.onSurfaceVariant),
            ),
            SizedBox(height: context.h(32)),
            Text(
              'Hedef Domain / IP',
              style: AppTheme.inter(context,
                size: 14, weight: FontWeight.w500, color: cs.onSurface),
            ),
            SizedBox(height: context.h(8)),
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(
                hintText: 'örn. 127.0.0.1 veya api.example.com',
              ),
              keyboardType: TextInputType.url,
            ),
            SizedBox(height: context.h(20)),
            Text(
              'Hedef Port',
              style: AppTheme.inter(context,
                size: 14, weight: FontWeight.w500, color: cs.onSurface),
            ),
            SizedBox(height: context.h(8)),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(hintText: 'örn. 8080'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: context.h(20)),
            Row(
              children: [
                Text(
                  'HTTPS Kullan',
                  style: AppTheme.inter(context,
                    size: 14, weight: FontWeight.w500, color: cs.onSurface),
                ),
                const Spacer(),
                Switch(
                  value: _useHttps,
                  onChanged: (v) => setState(() => _useHttps = v),
                  activeThumbColor: cs.primary,
                ),
              ],
            ),
            SizedBox(height: context.h(8)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.w(16)),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppTheme.smRadius),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, size: context.f(18), color: cs.onSurfaceVariant),
                  SizedBox(width: context.w(10)),
                  Expanded(
                    child: Text(
                      _buildConfig().baseUrl,
                      style: AppTheme.inter(context,
                        size: 13, color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.h(32)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Kaydet'),
              ),
            ),
            SizedBox(height: context.h(12)),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _testing ? null : _testConnection,
                child: _testing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Bağlantıyı Test Et'),
              ),
            ),
            if (_testResult != null) ...[
              SizedBox(height: context.h(16)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.w(16)),
                decoration: BoxDecoration(
                  color: _testResult!.startsWith('Başarılı')
                      ? Colors.green.withAlpha(25)
                      : cs.error.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppTheme.smRadius),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testResult!.startsWith('Başarılı')
                          ? Icons.check_circle
                          : Icons.error,
                      size: context.f(18),
                      color: _testResult!.startsWith('Başarılı')
                          ? Colors.green
                          : cs.error,
                    ),
                    SizedBox(width: context.w(10)),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: AppTheme.inter(context,
                          size: 13,
                          color: _testResult!.startsWith('Başarılı')
                              ? Colors.green.shade800
                              : cs.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
