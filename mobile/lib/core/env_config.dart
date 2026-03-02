/// Environment configuration for Clerk and Supabase.
///
/// Replace these with your actual values from:
/// - Clerk Dashboard → API Keys
/// - Supabase Dashboard → Settings → API
class EnvConfig {
  // Clerk
  static const String clerkPublishableKey = 'pk_test_bWFnaWNhbC1naG9zdC0yOC5jbGVyay5hY2NvdW50cy5kZXYk';

  // Supabase
  static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
