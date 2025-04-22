import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'artifact_service.dart';
import 'auth0_service.dart';
import 'auth0_service_impl.dart';
import 'auth_manager.dart';
import 'chrome_service.dart';
import 'chrome_service_impl.dart';

/// Global service locator instance
final GetIt serviceLocator = GetIt.instance;

/// Initialize all services for dependency injection
Future<void> setupServiceLocator() async {
  // Register Chrome service
  serviceLocator.registerLazySingleton<ChromeService>(
    () => ChromeServiceImpl()
  );
  
  // Register Auth0 service
  serviceLocator.registerLazySingleton<Auth0Service>(
    () => Auth0ServiceImpl(serviceLocator<ChromeService>())
  );
  
  // Register Auth manager
  serviceLocator.registerLazySingleton<AuthManager>(
    () => AuthManager(
      auth0Service: serviceLocator<Auth0Service>(),
      chromeService: serviceLocator<ChromeService>(),
      supabaseClient: Supabase.instance.client,
    )
  );
  
  // Register Artifact service
  serviceLocator.registerLazySingleton<ArtifactService>(
    () => ArtifactService()
  );
}