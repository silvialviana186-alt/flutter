import 'package:flutter_application_3/sreens/splash/auth/login_page.dart';
import 'package:flutter_application_3/sreens/splash/auth/register_page.dart';
import 'package:flutter_application_3/sreens/splash/dashboard/dashboard_page.dart';
import 'package:flutter_application_3/sreens/splash/profile/edit_profil.dart';
import 'package:flutter_application_3/sreens/splash/profile/profile_page.dart';
import 'package:flutter_application_3/survey/survey_detail_page.dart';

import 'package:go_router/go_router.dart';

// Variabel diubah dari _router jadi appRouter
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const Dashboard(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfilePage(),
    ),
    GoRoute(
      path: '/survey-detail/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
        return SurveyDetailPage(surveyId: id);
      },
    ),
  ],
);