import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth0_service.dart';
import 'chrome_service.dart';

/// User profile information
class UserProfile {
  final String? id;
  final String? email;
  final String? name;
  
  UserProfile({this.id, this.email, this.name});
}

/// Result of authentication attempt
class AuthResult {
  final bool success;
  final UserProfile? userProfile;
  final String? error;
  
  AuthResult({
    required this.success, 
    this.userProfile, 
    this.error,
  });
  
  factory AuthResult.success(UserProfile profile) => 
      AuthResult(success: true, userProfile: profile);
      
  factory AuthResult.failure(String error) => 
      AuthResult(success: false, error: error);
}

/// Manages authentication for the Chrome extension
class AuthManager {
  final Auth0Service auth0Service;
  final ChromeService chromeService;
  final SupabaseClient supabaseClient;
  
  AuthManager({
    required this.auth0Service,
    required this.chromeService,
    required this.supabaseClient,
  });
  
  /// Current user profile
  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;
  
  /// Authenticate user silently (non-interactive)
  Future<AuthResult> authenticateSilently() async {
    try {
      // Try to get cached token
      final token = await auth0Service.getCachedAuthToken();
      if (token == null) {
        return AuthResult.failure('No cached token available');
      }
      
      return await _processAuthToken(token);
    } catch (e) {
      debugPrint('Silent auth error: $e');
      return AuthResult.failure('Silent authentication failed: $e');
    }
  }
  
  /// Authenticate user interactively
  Future<AuthResult> authenticateInteractively() async {
    try {
      // Generate Auth0 URL
      final authUrl = auth0Service.getAuthUrl(redirectUrl: auth0Service.redirectUrl);
      
      // Launch Chrome auth flow
      final resultUrl = await chromeService.launchWebAuthFlow(
        url: authUrl, 
        interactive: true
      );
      
      if (resultUrl == null) {
        return AuthResult.failure('Authentication flow was canceled');
      }
      
      // Extract token or error
      final error = auth0Service.extractErrorFromRedirect(resultUrl);
      if (error != null) {
        return AuthResult.failure('Auth0 error: $error');
      }
      
      final token = auth0Service.extractTokenFromRedirect(resultUrl);
      if (token == null) {
        return AuthResult.failure('No token returned from Auth0');
      }
      
      // Cache the token
      await auth0Service.cacheAuthToken(token);
      
      // Process the token
      return await _processAuthToken(token);
    } catch (e) {
      debugPrint('Interactive auth error: $e');
      return AuthResult.failure('Authentication failed: $e');
    }
  }
  
  /// Process an Auth0 token to sign in with Supabase and get user info
  Future<AuthResult> _processAuthToken(String token) async {
    try {
      // Get user info from Auth0
      final userInfo = await auth0Service.getUserInfo(token);
      if (userInfo == null || userInfo['email'] == null) {
        return AuthResult.failure('Could not retrieve user information from Auth0');
      }
      
      // Sign in to Supabase with Auth0 token
      final response = await supabaseClient.auth.signInWithIdToken(
        provider: Provider.auth0,
        idToken: token,
        accessToken: token,
      );
      
      if (response.user == null) {
        return AuthResult.failure('Failed to authenticate with Supabase');
      }
      
      // Create user profile
      _currentUser = UserProfile(
        id: response.user?.id,
        email: userInfo['email'] as String,
        name: userInfo['name'] as String? ?? (userInfo['email'] as String).split('@').first,
      );
      
      return AuthResult.success(_currentUser!);
    } catch (e) {
      debugPrint('Token processing error: $e');
      return AuthResult.failure('Error processing authentication: $e');
    }
  }
  
  /// Sign out the current user
  Future<bool> signOut() async {
    try {
      await auth0Service.clearCachedAuthToken();
      await supabaseClient.auth.signOut();
      _currentUser = null;
      return true;
    } catch (e) {
      debugPrint('Sign out error: $e');
      return false;
    }
  }
  
  /// Check if user is authenticated
  bool get isAuthenticated => 
      supabaseClient.auth.currentUser != null && _currentUser != null;
}