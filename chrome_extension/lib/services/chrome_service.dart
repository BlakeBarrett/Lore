import 'package:flutter/foundation.dart';

/// Interface for Chrome browser API interactions
abstract class ChromeService {
  /// Get the current URL from the active tab
  Future<String?> getCurrentUrl();
  
  /// Get the redirect URL used for OAuth authentication
  String getRedirectUrl();
  
  /// Launch Chrome web auth flow
  Future<String?> launchWebAuthFlow({required String url, required bool interactive});
  
  /// Store a value in Chrome's local storage
  Future<void> storeValue({required String key, required String value});
  
  /// Get a value from Chrome's local storage
  Future<String?> getValue({required String key});
  
  /// Remove a value from Chrome's local storage
  Future<void> removeValue({required String key});
}