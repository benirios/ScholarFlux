import 'package:flutter/material.dart';
import 'core/routing/app_router.dart';

class ScholarFluxApp extends StatelessWidget {
  const ScholarFluxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ScholarFlux',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      routerConfig: goRouter,
    );
  }
}
