import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'core/env_config.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class ScholarFluxApp extends StatelessWidget {
  const ScholarFluxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ClerkAuth(
      config: ClerkAuthConfig(publishableKey: EnvConfig.clerkPublishableKey),
      child: MaterialApp.router(
        title: 'ScholarFlux',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: goRouter,
      ),
    );
  }
}
