import 'package:flutter_test/flutter_test.dart';

import '../mocks/mock_chrome_service.dart';
import '../test_setup.dart';

void main() {
  late MockChromeService mockChromeService;

  setUp(() async {
    // Initialize test services
    await setupTestServices();
    mockChromeService = testServiceLocator<MockChromeService>();
  });

  group('ChromeService', () {
    test('returns null when current URL is not set', () async {
      // Act
      final currentUrl = await mockChromeService.getCurrentUrl();
      
      // Assert
      expect(currentUrl, isNull);
    });
    
    test('returns current URL when set', () async {
      // Arrange
      const testUrl = 'https://example.com';
      mockChromeService.setCurrentUrl(testUrl);
      
      // Act
      final currentUrl = await mockChromeService.getCurrentUrl();
      
      // Assert
      expect(currentUrl, equals(testUrl));
    });
    
    test('returns redirect URL', () {
      // Act
      final redirectUrl = mockChromeService.getRedirectUrl();
      
      // Assert
      expect(redirectUrl, equals('https://mock-extension-id.chromiumapp.org/'));
    });
    
    test('launches auth flow and returns result URL', () async {
      // Arrange
      const authUrl = 'https://auth0.com/authorize?client_id=test&redirect_uri=test';
      
      // Act
      final resultUrl = await mockChromeService.launchWebAuthFlow(url: authUrl, interactive: true);
      
      // Assert
      expect(resultUrl, isNotNull);
      expect(resultUrl, contains('access_token='));
    });
    
    test('returns null for non-interactive auth flow', () async {
      // Arrange
      const authUrl = 'https://auth0.com/authorize?client_id=test&redirect_uri=test';
      
      // Act
      final resultUrl = await mockChromeService.launchWebAuthFlow(url: authUrl, interactive: false);
      
      // Assert
      expect(resultUrl, isNull);
    });
    
    test('stores and retrieves values', () async {
      // Arrange
      const key = 'test_key';
      const value = 'test_value';
      
      // Act
      await mockChromeService.storeValue(key: key, value: value);
      final retrievedValue = await mockChromeService.getValue(key: key);
      
      // Assert
      expect(retrievedValue, equals(value));
    });
    
    test('removes values', () async {
      // Arrange
      const key = 'test_key';
      const value = 'test_value';
      await mockChromeService.storeValue(key: key, value: value);
      
      // Act
      await mockChromeService.removeValue(key: key);
      final retrievedValue = await mockChromeService.getValue(key: key);
      
      // Assert
      expect(retrievedValue, isNull);
    });
  });
}