/// Environment configuration for Clerk and Supabase.
///
/// Replace these with your actual values from:
/// - Clerk Dashboard → API Keys
/// - Supabase Dashboard → Settings → API
class EnvConfig {
  // Clerk
  static const String clerkPublishableKey = 'pk_test_YOUR_CLERK_KEY';

  // Supabase
  static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
