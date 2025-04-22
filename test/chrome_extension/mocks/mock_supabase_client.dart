import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Generate mock classes for Supabase related classes
@GenerateMocks([SupabaseClient, GoTrueClient])
class MockGoTrueClient extends Mock implements GoTrueClient {
  User? _currentUser;
  
  @override
  User? get currentUser => _currentUser;
  
  void setCurrentUser(User user) {
    _currentUser = user;
  }
  
  @override
  Future<AuthResponse> signInWithIdToken({
    required Provider provider,
    required String idToken,
    String? accessToken,
  }) async {
    if (idToken == 'test_token' || idToken == 'mock_auth_token') {
      _currentUser = User(
        id: 'test_user_id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'test@example.com',
      );
      
      return AuthResponse(
        session: Session(
          accessToken: idToken,
          tokenType: 'bearer',
          refreshToken: 'refresh_token',
          expiresIn: 3600,
          user: _currentUser!,
        ),
        user: _currentUser,
      );
    } else {
      throw AuthException('Invalid token');
    }
  }
  
  @override
  Future<void> signOut() async {
    _currentUser = null;
  }
}

class MockSupabaseClient extends Mock implements SupabaseClient {
  final MockGoTrueClient _authClient = MockGoTrueClient();
  
  @override
  GoTrueClient get auth => _authClient;
  
  // Set the current user for testing
  void setCurrentUser({
    required String id, 
    required String email
  }) {
    _authClient.setCurrentUser(User(
      id: id,
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email,
    ));
  }
  
  void clearCurrentUser() {
    _authClient.signOut();
  }
}