class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const String login = '/login';
  static const String register = '/register';

  static const String students = '/students';

  static const String profiles = '/profiles';

  static const String donors = '/donors';

  static const String scholarships = '/scholarships';

  static const String match = '/match';

  static const String cities = '/cities';
  static const String departments = '/departments';
  static const String incomeLevels = '/income-levels';
  static const String userRoles = '/user-roles';
}
