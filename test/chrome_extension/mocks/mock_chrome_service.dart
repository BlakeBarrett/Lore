import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../chrome_extension/lib/services/chrome_service.dart';

// Generate a Mock class
@GenerateMocks([ChromeService])
class MockChromeService extends Mock implements ChromeService {
  String? _currentUrl;
  final Map<String, String> _localStorage = {};
  final String _redirectUrl = 'https://mock-extension-id.chromiumapp.org/';
  
  void setCurrentUrl(String url) {
    _currentUrl = url;
  }

  @override
  Future<String?> getCurrentUrl() async {
    return _currentUrl;
  }
  
  @override
  String getRedirectUrl() {
    return _redirectUrl;
  }
  
  @override
  Future<String?> launchWebAuthFlow({required String url, required bool interactive}) async {
    if (!interactive && url.contains('auth')) {
      return null; // Simulate non-interactive auth failure
    }
    
    // Simulate successful auth flow with redirect
    if (url.contains('auth0') && interactive) {
      return '$_redirectUrl#access_token=test_token&expires_in=86400&token_type=Bearer';
    }
    
    return null;
  }
  
  @override
  Future<void> storeValue({required String key, required String value}) async {
    _localStorage[key] = value;
  }
  
  @override
  Future<String?> getValue({required String key}) async {
    return _localStorage[key];
  }
  
  @override
  Future<void> removeValue({required String key}) async {
    _localStorage.remove(key);
  }
}