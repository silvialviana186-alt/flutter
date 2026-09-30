// import 'package:flutter/material.dart';
import 'package:flutter_application_3/sreens/splash/splash_screen.dart';
import 'package:go_router/go_router.dart';
// import '../screens/splash/splash_screen.dart';
import 'app_routes.dart';
class AppPages {
static final router = GoRouter(
initialLocation: AppRoutes.splash,
routes: [
GoRoute(
path: AppRoutes.splash,
builder: (context, state) => const SplashScreen(),
),
],
);
}