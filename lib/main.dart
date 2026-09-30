import 'package:flutter/material.dart';
import 'package:flutter_application_3/routes/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter, // <-- Langsung panggil variabel dari app_router.dart
    );
  }
}