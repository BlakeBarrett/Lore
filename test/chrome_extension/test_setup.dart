import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mocks/mock_artifact_service.dart';
import 'mocks/mock_auth0_service.dart';
import 'mocks/mock_auth_manager.dart';
import 'mocks/mock_chrome_service.dart';
import 'mocks/mock_supabase_client.dart';

/// Test service locator
final GetIt testServiceLocator = GetIt.instance;

/// Set up test services for unit testing
Future<void> setupTestServices() async {
  // Reset any previous registrations
  if (testServiceLocator.isRegistered<MockChromeService>()) {
    await testServiceLocator.reset();
  }
  
  // Register Chrome service
  final mockChromeService = MockChromeService();
  testServiceLocator.registerSingleton<MockChromeService>(mockChromeService);
  
  // Register Auth0 service
  final mockAuth0Service = MockAuth0Service(mockChromeService);
  testServiceLocator.registerSingleton<MockAuth0Service>(mockAuth0Service);
  
  // Register Supabase client
  final mockSupabaseClient = MockSupabaseClient();
  testServiceLocator.registerSingleton<MockSupabaseClient>(mockSupabaseClient);
  
  // Register Auth manager
  final mockAuthManager = MockAuthManager(
    auth0Service: mockAuth0Service,
    chromeService: mockChromeService,
    supabaseClient: mockSupabaseClient,
  );
  testServiceLocator.registerSingleton<MockAuthManager>(mockAuthManager);
  
  // Register Artifact service
  final mockArtifactService = MockArtifactService();
  testServiceLocator.registerSingleton<MockArtifactService>(mockArtifactService);
}