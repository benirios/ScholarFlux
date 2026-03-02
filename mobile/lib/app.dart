import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/clerk_auth_service.dart';
import 'core/env_config.dart';
import 'core/routing/app_router.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/app_theme.dart';

class ScholarFluxApp extends StatelessWidget {
  const ScholarFluxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: ClerkAuth(
        config: ClerkAuthConfig(publishableKey: EnvConfig.clerkPublishableKey),
        child: const _AuthBridge(),
      ),
    );
  }
}

/// Bridges Clerk widget-tree auth state into Riverpod providers,
/// sets the global reference for Supabase's accessToken callback,
/// and triggers initial sync when user is signed in.
class _AuthBridge extends ConsumerStatefulWidget {
  const _AuthBridge();

  @override
  ConsumerState<_AuthBridge> createState() => _AuthBridgeState();
}

class _AuthBridgeState extends ConsumerState<_AuthBridge> {
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    final authState = ClerkAuth.of(context);
    final userId = authState.user?.id;

    // Set global reference so Supabase accessToken callback can reach Clerk
    globalClerkAuthState = authState;

    // When userId changes, update Riverpod and trigger sync
    if (userId != _lastUserId) {
      _lastUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(clerkUserIdProvider.notifier).set(userId);

        if (userId != null) {
          Future.microtask(() {
            final syncService = ref.read(syncServiceProvider);
            syncService.fullSync();
            syncService.subscribeToRealtime();
          });
        }
      });
    }

    return MaterialApp.router(
      title: 'ScholarFlux',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: goRouter,
    );
  }
}
