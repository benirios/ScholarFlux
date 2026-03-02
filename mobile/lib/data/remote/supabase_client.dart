import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/clerk_auth_service.dart';
import '../../core/env_config.dart';

/// Initializes and provides the Supabase client with Clerk JWT auth.
class SupabaseClientWrapper {
  late final SupabaseClient client;

  SupabaseClientWrapper() {
    client = Supabase.instance.client;
  }

  /// Initialize Supabase with Clerk JWT as the access token provider.
  static Future<void> init() async {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      accessToken: _clerkAccessToken,
    );
  }

  /// Called by Supabase for every authenticated request.
  /// Returns the Clerk-issued JWT for the "supabase" template.
  static Future<String?> _clerkAccessToken() async {
    final authState = globalClerkAuthState;
    if (authState == null || authState.user == null) return null;
    try {
      return await ClerkAuthHelper.getToken(authState);
    } catch (e) {
      debugPrint('[SupabaseClient] Failed to get Clerk token: $e');
      return null;
    }
  }
}

/// Provider for the Supabase client wrapper.
final supabaseClientProvider = Provider<SupabaseClientWrapper>((ref) {
  return SupabaseClientWrapper();
});

/// Convenience provider for the raw Supabase client.
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return ref.watch(supabaseClientProvider).client;
});
