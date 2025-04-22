import 'package:flutter_test/flutter_test.dart';

import '../mocks/mock_auth_manager.dart';
import '../mocks/mock_auth0_service.dart';
import '../mocks/mock_chrome_service.dart';
import '../mocks/mock_supabase_client.dart';
import '../test_setup.dart';

void main() {
  late MockAuthManager mockAuthManager;
  late MockAuth0Service mockAuth0Service;
  late MockChromeService mockChromeService;
  late MockSupabaseClient mockSupabaseClient;

  setUp(() async {
    // Initialize test services
    await setupTestServices();
    mockAuthManager = testServiceLocator<MockAuthManager>();
    mockAuth0Service = testServiceLocator<MockAuth0Service>();
    mockChromeService = testServiceLocator<MockChromeService>();
    mockSupabaseClient = testServiceLocator<MockSupabaseClient>();
  });

  group('AuthManager', () {
    test('initially not authenticated', () {
      // Assert
      expect(mockAuthManager.isAuthenticated, isFalse);
      expect(mockAuthManager.currentUser, isNull);
    });
    
    test('authenticateSilently returns failure when not authenticated', () async {
      // Act
      final result = await mockAuthManager.authenticateSilently();
      
      // Assert
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });
    
    test('authenticateSilently returns success when authenticated', () async {
      // Arrange
      mockAuthManager.setAuthenticated(true);
      
      // Act
      final result = await mockAuthManager.authenticateSilently();
      
      // Assert
      expect(result.success, isTrue);
      expect(result.userProfile, isNotNull);
    });
    
    test('authenticateInteractively returns success', () async {
      // Act
      final result = await mockAuthManager.authenticateInteractively();
      
      // Assert
      expect(result.success, isTrue);
      expect(result.userProfile, isNotNull);
      expect(mockAuthManager.isAuthenticated, isTrue);
    });
    
    test('signOut clears authentication state', () async {
      // Arrange
      mockAuthManager.setAuthenticated(true);
      expect(mockAuthManager.isAuthenticated, isTrue);
      
      // Act
      final success = await mockAuthManager.signOut();
      
      // Assert
      expect(success, isTrue);
      expect(mockAuthManager.isAuthenticated, isFalse);
      expect(mockAuthManager.currentUser, isNull);
    });
    
    test('setAuthenticated updates user profile', () {
      // Arrange
      const testEmail = 'custom@example.com';
      const testName = 'Custom User';
      const testId = 'custom_id';
      
      // Act
      mockAuthManager.setAuthenticated(true, email: testEmail, name: testName, id: testId);
      
      // Assert
      expect(mockAuthManager.isAuthenticated, isTrue);
      expect(mockAuthManager.currentUser?.email, equals(testEmail));
      expect(mockAuthManager.currentUser?.name, equals(testName));
      expect(mockAuthManager.currentUser?.id, equals(testId));
    });
  });
}