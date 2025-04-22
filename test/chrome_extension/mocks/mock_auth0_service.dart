import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../chrome_extension/lib/services/auth0_service.dart';
import '../../../chrome_extension/lib/services/chrome_service.dart';

const String MOCK_AUTH_TOKEN = 'mock_auth_token';

// Generate a Mock class
@GenerateMocks([Auth0Service])
class MockAuth0Service extends Mock implements Auth0Service {
  final ChromeService _chromeService;
  
  MockAuth0Service(this._chromeService);
  
  @override
  String get domain => 'mock-tenant.auth0.com';
  
  @override
  String get clientId => 'mock_client_id';
  
  @override
  String get audience => 'https://mock-api.com';
  
  @override
  String get redirectUrl => _chromeService.getRedirectUrl();

  @override
  String getAuthUrl({required String redirectUrl}) {
    return 'https://$domain/authorize'
      '?response_type=token'
      '&client_id=$clientId'
      '&redirect_uri=$redirectUrl'
      '&scope=openid%20profile%20email'
      '&audience=$audience';
  }
  
  @override
  String? extractTokenFromRedirect(String redirectUrl) {
    if (redirectUrl.contains('access_token=')) {
      // Simple parsing for test purpose
      final startIndex = redirectUrl.indexOf('access_token=') + 'access_token='.length;
      final endIndex = redirectUrl.indexOf('&', startIndex);
      if (endIndex > startIndex) {
        return redirectUrl.substring(startIndex, endIndex);
      } else {
        return redirectUrl.substring(startIndex);
      }
    }
    return null;
  }
  
  @override
  String? extractErrorFromRedirect(String redirectUrl) {
    if (redirectUrl.contains('error=')) {
      // Simple parsing for test purpose
      final startIndex = redirectUrl.indexOf('error=') + 'error='.length;
      final endIndex = redirectUrl.indexOf('&', startIndex);
      if (endIndex > startIndex) {
        return redirectUrl.substring(startIndex, endIndex);
      } else {
        return redirectUrl.substring(startIndex);
      }
    }
    return null;
  }
  
  @override
  Future<Map<String, dynamic>?> getUserInfo(String token) async {
    if (token == MOCK_AUTH_TOKEN || token == 'test_token') {
      return {
        'email': 'test@example.com',
        'name': 'Test User',
        'sub': 'auth0|12345',
        'picture': 'https://example.com/avatar.png',
      };
    }
    return null;
  }
  
  @override
  Future<void> cacheAuthToken(String token) async {
    await _chromeService.storeValue(key: 'auth0_access_token', value: token);
  }
  
  @override
  Future<String?> getCachedAuthToken() async {
    return _chromeService.getValue(key: 'auth0_access_token');
  }
  
  @override
  Future<void> clearCachedAuthToken() async {
    await _chromeService.removeValue(key: 'auth0_access_token');
  }
}