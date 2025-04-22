import 'package:Lore/artifact.dart';
import 'package:Lore/auth_widget.dart';
import 'package:Lore/lore_api.dart';
import 'package:Lore/md5_utils.dart';
import 'package:Lore/remark.dart';
import 'package:Lore/remark_entry_widget.dart';
import 'package:Lore/remark_list_widget.dart';
import 'package:chrome_extension/chrome_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'auth0_config.dart'; // Import Auth0 configuration

// Reference to the Supabase client instance
late final SupabaseClient supabaseInstance;
// Auth0 configuration is imported from auth0_config.dart
final String redirectUri = chrome.identity.getRedirectURL();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await initializeSupabase();
  
  runApp(const LoreChromeExtension());
}

Future<void> initializeSupabase() async {
  await dotenv.load(fileName: 'supabase.env');
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );
  supabaseInstance = Supabase.instance.client;
}

class LoreChromeExtension extends StatefulWidget {
  const LoreChromeExtension({Key? key}) : super(key: key);

  @override
  State<LoreChromeExtension> createState() => _LoreChromeExtensionState();
}

class _LoreChromeExtensionState extends State<LoreChromeExtension> {
  String? _currentUrl;
  Artifact? _currentArtifact;
  List<Remark>? _remarks;
  bool _isLoading = true;
  bool _isAuthenticating = false;
  String? _authError;
  String? _userEmail;
  String? _userName;
  
  @override
  void initState() {
    super.initState();
    _initializeExtension();
  }
  
  Future<void> _initializeExtension() async {
    setState(() {
      _isLoading = true;
      _isAuthenticating = true;
    });
    
    try {
      // First try to authenticate automatically with Auth0
      await _authenticateWithAuth0(false); // false means non-interactive initially
    } catch (e) {
      debugPrint('Automatic authentication error: $e');
      setState(() {
        _authError = 'Auto-sign in not available. Please sign in manually.';
        _isAuthenticating = false;
      });
    }
    
    // Proceed with loading the current URL and artifacts
    try {
      final tabs = await chrome.tabs.query({
        'active': true,
        'currentWindow': true,
      });
      
      if (tabs.isNotEmpty) {
        final currentTab = tabs.first;
        setState(() {
          _currentUrl = currentTab.url;
        });
        
        // Create the artifact from the URL
        if (_currentUrl != null) {
          final artifact = Artifact.fromURI(Uri.parse(_currentUrl!));
          setState(() {
            _currentArtifact = artifact;
          });
          
          // Load remarks for this artifact
          await _loadRemarks();
        }
      }
    } catch (e) {
      debugPrint('Error getting current tab: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _authenticateWithAuth0(bool interactive) async {
    setState(() {
      _isAuthenticating = true;
      _authError = null;
    });
    
    try {
      // Check if we have a cached token first
      String? cachedToken = await _getCachedAuthToken();
      
      if (cachedToken != null) {
        // Use cached token
        await _handleAuth0Token(cachedToken);
      } else if (interactive) {
        // If no cached token and interactive mode is allowed, launch the auth flow
        final String authUrl = 'https://$auth0Domain/authorize'
          '?response_type=token'
          '&client_id=$auth0ClientId'
          '&redirect_uri=$redirectUri'
          '&scope=openid%20profile%20email'
          '&audience=$audience';
          
        final String? resultUrl = await _launchChromeAuth(authUrl);
        
        if (resultUrl != null) {
          // Extract the access token from the redirect URL
          final Uri uri = Uri.parse(resultUrl);
          
          // For token flow, token comes in the fragment, not query params
          final String fragment = uri.fragment;
          final Map<String, String> params = Uri.splitQueryString(fragment);
          
          final String? token = params['access_token'];
          final String? error = params['error'];
          
          if (error != null) {
            throw Exception('Auth0 error: $error');
          }
          
          if (token != null) {
            await _cacheAuthToken(token);
            await _handleAuth0Token(token);
          } else {
            throw Exception('No access token returned from Auth0');
          }
        } else {
          throw Exception('Authentication was canceled or failed');
        }
      } else {
        // Non-interactive mode and no cached token
        throw Exception('No cached credentials available');
      }
    } catch (e) {
      debugPrint('Auth0 authentication error: $e');
      setState(() {
        _authError = 'Authentication failed: $e';
        _isAuthenticating = false;
      });
      rethrow;
    }
    
    setState(() {
      _isAuthenticating = false;
    });
  }
  
  Future<String?> _launchChromeAuth(String authUrl) async {
    try {
      // Use Chrome's identity API to launch the OAuth flow
      final dynamic result = await js_util.promiseToFuture<dynamic>(
        js.context.callMethod('eval', [
          '''
          new Promise((resolve, reject) => {
            chrome.identity.launchWebAuthFlow({
              url: '$authUrl',
              interactive: true
            }, function(responseUrl) {
              if (chrome.runtime.lastError) {
                reject(chrome.runtime.lastError.message);
              } else {
                resolve(responseUrl);
              }
            });
          })
          '''
        ])
      );
      
      return result as String?;
    } catch (e) {
      debugPrint('Error launching auth flow: $e');
      return null;
    }
  }
  
  Future<void> _handleAuth0Token(String token) async {
    try {
      // Fetch user info from Auth0
      final userInfo = await _fetchUserInfoFromAuth0(token);
      
      if (userInfo != null && userInfo['email'] != null) {
        setState(() {
          _userEmail = userInfo['email'] as String;
          _userName = userInfo['name'] as String? ?? _userEmail!.split('@').first;
        });
        
        // Sign in to Supabase with the Auth0 token
        final AuthResponse response = await supabaseInstance.auth.signInWithIdToken(
          provider: Provider.auth0,
          idToken: token,
          accessToken: token,
        );
        
        debugPrint('User authenticated: ${response.user?.email}');
      } else {
        throw Exception('Could not retrieve user information from Auth0');
      }
    } catch (e) {
      debugPrint('Error handling Auth0 token: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>?> _fetchUserInfoFromAuth0(String token) async {
    try {
      final result = await js_util.promiseToFuture<dynamic>(
        js.context.callMethod('eval', [
          '''
          new Promise((resolve, reject) => {
            fetch('https://$auth0Domain/userinfo', {
              headers: {
                'Authorization': 'Bearer ' + '$token'
              }
            })
            .then(response => {
              if (!response.ok) {
                throw new Error('Failed to fetch user info: ' + response.status);
              }
              return response.json();
            })
            .then(data => resolve(data))
            .catch(error => reject(error));
          })
          '''
        ])
      );
      
      return result != null ? Map<String, dynamic>.from(result as Map) : null;
    } catch (e) {
      debugPrint('Error fetching Auth0 user info: $e');
      return null;
    }
  }
  
  Future<String?> _getCachedAuthToken() async {
    try {
      final result = await js_util.promiseToFuture<dynamic>(
        js.context.callMethod('eval', [
          '''
          new Promise((resolve) => {
            chrome.storage.local.get(['auth0_access_token'], function(result) {
              if (result && result.auth0_access_token) {
                resolve(result.auth0_access_token);
              } else {
                resolve(null);
              }
            });
          })
          '''
        ])
      );
      
      return result as String?;
    } catch (e) {
      debugPrint('Error getting cached token: $e');
      return null;
    }
  }
  
  Future<void> _cacheAuthToken(String token) async {
    try {
      await js_util.promiseToFuture<void>(
        js.context.callMethod('eval', [
          '''
          new Promise((resolve) => {
            chrome.storage.local.set({auth0_access_token: '$token'}, function() {
              resolve();
            });
          })
          '''
        ])
      );
    } catch (e) {
      debugPrint('Error caching token: $e');
    }
  }
  
  Future<void> _clearCachedAuthToken() async {
    try {
      await js_util.promiseToFuture<void>(
        js.context.callMethod('eval', [
          '''
          new Promise((resolve) => {
            chrome.storage.local.remove(['auth0_access_token'], function() {
              resolve();
            });
          })
          '''
        ])
      );
    } catch (e) {
      debugPrint('Error clearing cached token: $e');
    }
  }
  
  Future<void> _loadRemarks() async {
    if (_currentArtifact == null) return;
    
    try {
      final remarks = await LoreAPI.loadRemarks(md5sum: _currentArtifact!.md5sum);
      setState(() {
        _remarks = remarks;
      });
    } catch (e) {
      debugPrint('Error loading remarks: $e');
    }
  }
  
  void _showAuthPrompt() async {
    try {
      await _authenticateWithAuth0(true); // true means interactive
      await _loadRemarks(); // Refresh remarks after authentication
    } catch (e) {
      debugPrint('Interactive authentication error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _logout() async {
    try {
      await _clearCachedAuthToken();
      await supabaseInstance.auth.signOut();
      setState(() {
        _userEmail = null;
        _userName = null;
      });
      await _loadRemarks(); // Refresh remarks after logout
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }
  
  Future<void> _submitRemark(String remark) async {
    if (_currentArtifact == null) return;
    
    try {
      await LoreAPI.saveRemark(
        remark: remark,
        md5sum: _currentArtifact!.md5sum,
        userId: LoreAPI.userId,
      );
      
      // Reload remarks to show the new one
      await _loadRemarks();
    } catch (e) {
      debugPrint('Error submitting remark: $e');
    }
  }
  
  void _deleteRemark(Remark remark) async {
    try {
      await LoreAPI.deleteRemark(remark: remark);
      await _loadRemarks();
    } catch (e) {
      debugPrint('Error deleting remark: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lore',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Lore'),
          backgroundColor: Colors.orange,
          actions: [
            if (_isAuthenticating)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (LoreAPI.userId != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.person, color: Colors.white),
                onSelected: (value) {
                  if (value == 'logout') {
                    _logout();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'profile',
                    enabled: false,
                    child: Text('Signed in as $_userEmail'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Sign out'),
                  ),
                ],
              )
            else
              IconButton(
                icon: const Icon(Icons.login, color: Colors.white),
                onPressed: _showAuthPrompt,
                tooltip: 'Sign in',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_currentUrl == null) {
      return const Center(child: Text('Unable to get current URL'));
    }
    
    return Column(
      children: [
        // Authentication error message if any
        if (_authError != null)
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.red[100],
            width: double.infinity,
            child: Text(
              '$_authError',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
          
        // URL info section
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.orange[100],
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current URL:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      _currentUrl!,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Artifact ID: ${_currentArtifact?.md5sum ?? "N/A"}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadRemarks,
                tooltip: 'Refresh remarks',
              ),
            ],
          ),
        ),
        
        // Remarks section
        Expanded(
          child: CustomScrollView(
            slivers: [
              RemarkList(
                remarks: _remarks,
                userId: LoreAPI.userId,
                onDeleteRemark: _deleteRemark,
              ),
            ],
          ),
        ),
        
        // Remark entry widget at bottom
        RemarkEntryWidget(
          enabled: LoreAPI.userId != null,
          onSubmitted: _submitRemark,
          onLogin: _showAuthPrompt,
        ),
      ],
    );
  }
}