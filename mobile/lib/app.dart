import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/home/home_screen.dart';
import 'features/student/student_detail_screen.dart';
import 'features/student/student_edit_screen.dart';
import 'features/student/match_result_screen.dart';
import 'features/donor/donor_list_screen.dart';
import 'features/donor/donor_detail_screen.dart';
import 'features/scholarship/scholarship_list_screen.dart';
import 'features/scholarship/scholarship_detail_screen.dart';
import 'features/scholarship/scholarship_create_screen.dart';
import 'features/admin/donor_verify_screen.dart';
import 'features/admin/department_manage_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/match',
      builder: (_, __) => const MatchResultScreen(),
    ),
    GoRoute(
      path: '/students',
      redirect: (_, __) => '/',
      routes: [
        GoRoute(
          path: ':profileId',
          builder: (_, state) => StudentDetailScreen(
            profileId: state.pathParameters['profileId']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, state) => StudentEditScreen(
                profileId: state.pathParameters['profileId']!,
              ),
            ),
            GoRoute(
              path: 'match',
              builder: (_, state) => MatchResultScreen(
                studentId: state.pathParameters['profileId']!,
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/donors',
      builder: (_, __) => const DonorListScreen(),
      routes: [
        GoRoute(
          path: ':profileId',
          builder: (_, state) => DonorDetailScreen(
            profileId: state.pathParameters['profileId']!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/scholarships',
      builder: (_, __) => const ScholarshipListScreen(),
      routes: [
        GoRoute(
          path: 'create',
          builder: (_, __) => const ScholarshipCreateScreen(),
        ),
        GoRoute(
          path: ':id',
          builder: (_, state) => ScholarshipDetailScreen(
            scholarshipId: state.pathParameters['id']!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/admin/verify-donors',
      builder: (_, __) => const DonorVerifyScreen(),
    ),
    GoRoute(
      path: '/admin/departments',
      builder: (_, __) => const DepartmentManageScreen(),
    ),
  ],
);

class BursApp extends StatelessWidget {
  const BursApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Burs Eşleştirme',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
