/// Interface for Auth0 authentication operations
abstract class Auth0Service {
  /// Get the Auth0 domain
  String get domain;
  
  /// Get the Auth0 client ID
  String get clientId;
  
  /// Get the Auth0 audience
  String get audience;
  
  /// Get the redirect URL
  String get redirectUrl;
  
  /// Generate Auth0 authorization URL
  String getAuthUrl({required String redirectUrl});
  
  /// Extract token from redirect URL
  String? extractTokenFromRedirect(String redirectUrl);
  
  /// Extract error from redirect URL
  String? extractErrorFromRedirect(String redirectUrl);
  
  /// Get user information from Auth0 using the token
  Future<Map<String, dynamic>?> getUserInfo(String token);
  
  /// Cache the auth token
  Future<void> cacheAuthToken(String token);
  
  /// Get the cached auth token
  Future<String?> getCachedAuthToken();
  
  /// Clear the cached auth token
  Future<void> clearCachedAuthToken();
}