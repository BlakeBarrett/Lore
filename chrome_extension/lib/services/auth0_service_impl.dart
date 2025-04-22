import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../auth0_config.dart';
import 'chrome_service.dart';
import 'auth0_service.dart';

const String AUTH_TOKEN_KEY = 'auth0_access_token';

class Auth0ServiceImpl implements Auth0Service {
  final ChromeService _chromeService;
  
  Auth0ServiceImpl(this._chromeService);
  
  @override
  String get domain => auth0Domain;
  
  @override
  String get clientId => auth0ClientId;
  
  @override
  String get audience => auth0Audience;
  
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
    try {
      final uri = Uri.parse(redirectUrl);
      final fragment = uri.fragment;
      final params = Uri.splitQueryString(fragment);
      return params['access_token'];
    } catch (e) {
      debugPrint('Error extracting token: $e');
      return null;
    }
  }
  
  @override
  String? extractErrorFromRedirect(String redirectUrl) {
    try {
      final uri = Uri.parse(redirectUrl);
      final fragment = uri.fragment;
      final params = Uri.splitQueryString(fragment);
      return params['error'];
    } catch (e) {
      debugPrint('Error extracting error: $e');
      return null;
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getUserInfo(String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://$domain/userinfo'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> userInfo = json.decode(response.body);
        return userInfo;
      } else {
        throw Exception('Failed to get user info: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting user info: $e');
      return null;
    }
  }
  
  @override
  Future<void> cacheAuthToken(String token) async {
    await _chromeService.storeValue(key: AUTH_TOKEN_KEY, value: token);
  }
  
  @override
  Future<String?> getCachedAuthToken() async {
    return await _chromeService.getValue(key: AUTH_TOKEN_KEY);
  }
  
  @override
  Future<void> clearCachedAuthToken() async {
    await _chromeService.removeValue(key: AUTH_TOKEN_KEY);
  }
}