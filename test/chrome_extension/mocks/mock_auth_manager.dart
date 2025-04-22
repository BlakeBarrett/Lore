import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// We need to adjust these imports to point to the correct location
// relative to where our test file is located
import '../../../chrome_extension/lib/services/auth_manager.dart';
import '../../../chrome_extension/lib/services/auth0_service.dart';
import '../../../chrome_extension/lib/services/chrome_service.dart';

// Generate a Mock class
@GenerateMocks([AuthManager])
class MockAuthManager extends Mock implements AuthManager {
  final Auth0Service auth0Service;
  final ChromeService chromeService;
  final SupabaseClient supabaseClient;
  UserProfile? _currentUser;
  bool _isAuthenticated = false;

  MockAuthManager({
    required this.auth0Service,
    required this.chromeService,
    required this.supabaseClient,
  });
  
  @override
  UserProfile? get currentUser => _currentUser;
  
  @override
  bool get isAuthenticated => _isAuthenticated;
  
  // Helper method to set authentication state for testing
  void setAuthenticated(bool authenticated, {String? email, String? name, String? id}) {
    _isAuthenticated = authenticated;
    if (authenticated) {
      _currentUser = UserProfile(
        id: id ?? 'test_user_id',
        email: email ?? 'test@example.com',
        name: name ?? 'Test User',
      );
    } else {
      _currentUser = null;
    }
  }
  
  @override
  Future<AuthResult> authenticateSilently() async {
    if (_isAuthenticated) {
      return AuthResult.success(_currentUser!);
    }
    return AuthResult.failure('No cached token available');
  }
  
  @override
  Future<AuthResult> authenticateInteractively() async {
    // Simulate successful authentication
    _isAuthenticated = true;
    _currentUser = UserProfile(
      id: 'test_user_id',
      email: 'test@example.com',
      name: 'Test User',
    );
    return AuthResult.success(_currentUser!);
  }
  
  @override
  Future<bool> signOut() async {
    _isAuthenticated = false;
    _currentUser = null;
    return true;
  }
}