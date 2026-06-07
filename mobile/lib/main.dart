import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/secure_storage.dart';
import 'services/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await SecureStorage.getApiConfig();
  if (config != null) {
    ApiClient.setBaseUrl(config);
  }
  runApp(const ProviderScope(child: BursApp()));
}
