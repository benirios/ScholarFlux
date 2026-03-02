import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global reference to ClerkAuthState, set by _AuthBridge in app.dart.
/// Used by the Supabase accessToken callback to get the Clerk JWT.
ClerkAuthState? globalClerkAuthState;

/// Clerk authentication service wrapping the Clerk Flutter SDK.
class ClerkAuthHelper {
  /// Get the current session token (JWT) for Supabase requests.
  static Future<String?> getToken(ClerkAuthState authState,
      {String? template}) async {
    try {
      final sessionToken =
          await authState.sessionToken(templateName: template ?? 'supabase');
      return sessionToken.jwt;
    } catch (_) {
      return null;
    }
  }

  /// Whether a user is currently signed in.
  static bool isSignedIn(ClerkAuthState authState) {
    return authState.user is clerk.User;
  }

  /// The current Clerk user ID, or null.
  static String? userId(ClerkAuthState authState) {
    return authState.user?.id;
  }

  /// Sign out the current user.
  static Future<void> signOut(ClerkAuthState authState) async {
    await authState.signOut();
  }
}

/// Provider that holds a reference to the ClerkAuthState.
/// Must be overridden at the ProviderScope level after ClerkAuth initializes.
final clerkAuthStateProvider = Provider<ClerkAuthState?>((ref) => null);

/// Auth state — true if signed in.
final isSignedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(clerkAuthStateProvider);
  if (authState == null) return false;
  return ClerkAuthHelper.isSignedIn(authState);
});

/// Current user ID.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(clerkAuthStateProvider);
  if (authState == null) return null;
  return ClerkAuthHelper.userId(authState);
});
