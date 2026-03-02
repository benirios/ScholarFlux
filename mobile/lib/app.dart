import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/clerk_auth_service.dart';
import 'core/env_config.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class ScholarFluxApp extends StatelessWidget {
  const ScholarFluxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ClerkAuth(
      config: ClerkAuthConfig(publishableKey: EnvConfig.clerkPublishableKey),
      child: const _AuthBridge(),
    );
  }
}

/// Bridges Clerk widget-tree auth state into Riverpod providers
/// and sets the global reference for Supabase's accessToken callback.
class _AuthBridge extends StatelessWidget {
  const _AuthBridge();

  @override
  Widget build(BuildContext context) {
    final authState = ClerkAuth.of(context);

    // Set global reference so Supabase accessToken callback can reach Clerk
    globalClerkAuthState = authState;

    return ProviderScope(
      overrides: [
        clerkAuthStateProvider.overrideWithValue(authState),
      ],
      child: MaterialApp.router(
        title: 'ScholarFlux',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: goRouter,
      ),
    );
  }
}
