import 'dart:convert';

class ApiConfig {
  final String host;
  final int port;
  final bool useHttps;

  const ApiConfig({
    this.host = 'bursmu-api.ofesec.net',
    this.port = 80,
    this.useHttps = false,
  });

  String get baseUrl => '${useHttps ? "https" : "http"}://$host:$port';

  ApiConfig copyWith({
    String? host,
    int? port,
    bool? useHttps,
  }) {
    return ApiConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      useHttps: useHttps ?? this.useHttps,
    );
  }

  Map<String, dynamic> toJson() => {
        'host': host,
        'port': port,
        'useHttps': useHttps,
      };

  factory ApiConfig.fromJson(Map<String, dynamic> json) => ApiConfig(
        host: json['host'] as String? ?? 'bursmu-api.ofesec.net',
        port: json['port'] as int? ?? 80,
        useHttps: json['useHttps'] as bool? ?? false,
      );

  String encode() => jsonEncode(toJson());

  factory ApiConfig.decode(String data) =>
      ApiConfig.fromJson(jsonDecode(data) as Map<String, dynamic>);
}
