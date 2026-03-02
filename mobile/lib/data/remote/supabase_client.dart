import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env_config.dart';

/// Initializes and provides the Supabase client with Clerk JWT auth.
class SupabaseClientWrapper {
  late final SupabaseClient client;

  SupabaseClientWrapper() {
    client = Supabase.instance.client;
  }

  /// Initialize Supabase (call once at app start).
  static Future<void> init() async {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );
  }

  /// Set a JWT token on the Supabase client for authenticated requests.
  Future<void> setAuthToken(String token) async {
    await client.auth.setSession(token);
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
