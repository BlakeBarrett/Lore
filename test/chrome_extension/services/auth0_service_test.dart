import 'package:flutter_test/flutter_test.dart';

import '../mocks/mock_auth0_service.dart';
import '../mocks/mock_chrome_service.dart';
import '../test_setup.dart';

void main() {
  late MockChromeService mockChromeService;
  late MockAuth0Service mockAuth0Service;

  setUp(() async {
    // Initialize test services
    await setupTestServices();
    mockChromeService = testServiceLocator<MockChromeService>();
    mockAuth0Service = testServiceLocator<MockAuth0Service>();
  });

  group('Auth0Service', () {
    test('generates correct auth URL', () {
      // Arrange
      final redirectUrl = mockChromeService.getRedirectUrl();
      
      // Act
      final authUrl = mockAuth0Service.getAuthUrl(redirectUrl: redirectUrl);
      
      // Assert
      expect(authUrl, contains('https://mock-tenant.auth0.com/authorize'));
      expect(authUrl, contains('response_type=token'));
      expect(authUrl, contains('client_id=mock_client_id'));
      expect(authUrl, contains('redirect_uri=$redirectUrl'));
    });
    
    test('extracts token from redirect URL', () {
      // Arrange
      const token = 'test_token';
      final redirectUrl = 'https://example.chromiumapp.org/#access_token=$token&expires_in=86400';
      
      // Act
      final extractedToken = mockAuth0Service.extractTokenFromRedirect(redirectUrl);
      
      // Assert
      expect(extractedToken, equals(token));
    });
    
    test('extracts error from redirect URL', () {
      // Arrange
      const error = 'invalid_request';
      final redirectUrl = 'https://example.chromiumapp.org/#error=$error&error_description=Invalid%20request';
      
      // Act
      final extractedError = mockAuth0Service.extractErrorFromRedirect(redirectUrl);
      
      // Assert
      expect(extractedError, equals(error));
    });
    
    test('returns user info for valid token', () async {
      // Arrange
      const token = 'test_token';
      
      // Act
      final userInfo = await mockAuth0Service.getUserInfo(token);
      
      // Assert
      expect(userInfo, isNotNull);
      expect(userInfo!['email'], equals('test@example.com'));
      expect(userInfo['name'], equals('Test User'));
    });
    
    test('returns null for invalid token', () async {
      // Arrange
      const token = 'invalid_token';
      
      // Act
      final userInfo = await mockAuth0Service.getUserInfo(token);
      
      // Assert
      expect(userInfo, isNull);
    });
    
    test('caches and retrieves auth token', () async {
      // Arrange
      const token = 'cached_test_token';
      
      // Act
      await mockAuth0Service.cacheAuthToken(token);
      final retrievedToken = await mockAuth0Service.getCachedAuthToken();
      
      // Assert
      expect(retrievedToken, equals(token));
    });
    
    test('clears cached auth token', () async {
      // Arrange
      const token = 'cached_test_token';
      await mockAuth0Service.cacheAuthToken(token);
      
      // Act
      await mockAuth0Service.clearCachedAuthToken();
      final retrievedToken = await mockAuth0Service.getCachedAuthToken();
      
      // Assert
      expect(retrievedToken, isNull);
    });
  });
}