import 'package:Lore/artifact.dart';
import 'package:Lore/lore_api.dart';
import 'package:Lore/remark.dart';
import 'package:Lore/remark_entry_widget.dart';
import 'package:Lore/remark_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/artifact_service.dart';
import 'services/auth_manager.dart';
import 'services/chrome_service.dart';
import 'services/service_locator.dart';

// Reference to the Supabase client instance
late final SupabaseClient supabaseInstance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await initializeSupabase();
  
  // Setup service locator for dependency injection
  await setupServiceLocator();
  
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
  
  // Services
  late final AuthManager _authManager;
  late final ArtifactService _artifactService;
  
  @override
  void initState() {
    super.initState();
    _authManager = serviceLocator<AuthManager>();
    _artifactService = serviceLocator<ArtifactService>();
    _initializeExtension();
  }
  
  Future<void> _initializeExtension() async {
    setState(() {
      _isLoading = true;
      _isAuthenticating = true;
    });
    
    try {
      // First try to authenticate automatically with Auth0
      final authResult = await _authManager.authenticateSilently();
      if (!authResult.success) {
        setState(() {
          _authError = 'Auto-sign in not available. Please sign in manually.';
        });
      }
    } catch (e) {
      debugPrint('Automatic authentication error: $e');
      setState(() {
        _authError = 'Auto-sign in not available. Please sign in manually.';
      });
    }
    
    setState(() {
      _isAuthenticating = false;
    });
    
    // Proceed with loading the current URL and artifacts
    try {
      final currentUrl = await serviceLocator<ChromeService>().getCurrentUrl();
      
      if (currentUrl != null) {
        setState(() {
          _currentUrl = currentUrl;
        });
        
        // Create the artifact from the URL
        final artifact = _artifactService.createArtifactFromUrl(currentUrl);
        setState(() {
          _currentArtifact = artifact;
        });
        
        // Load remarks for this artifact
        await _loadRemarks();
      }
    } catch (e) {
      debugPrint('Error getting current tab: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _loadRemarks() async {
    if (_currentArtifact == null) return;
    
    try {
      final remarks = await _artifactService.loadRemarks(_currentArtifact!.md5sum);
      setState(() {
        _remarks = remarks;
      });
    } catch (e) {
      debugPrint('Error loading remarks: $e');
    }
  }
  
  void _showAuthPrompt() async {
    setState(() {
      _isAuthenticating = true;
      _authError = null;
    });
    
    try {
      final authResult = await _authManager.authenticateInteractively();
      
      if (!authResult.success) {
        setState(() {
          _authError = authResult.error;
        });
      }
      
      // Refresh remarks after authentication
      await _loadRemarks();
    } catch (e) {
      debugPrint('Interactive authentication error: $e');
      setState(() {
        _authError = 'Authentication failed: $e';
      });
    }
    
    setState(() {
      _isAuthenticating = false;
    });
  }
  
  Future<void> _logout() async {
    try {
      await _authManager.signOut();
      await _loadRemarks(); // Refresh remarks after logout
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }
  
  Future<void> _submitRemark(String remark) async {
    if (_currentArtifact == null) return;
    
    try {
      await _artifactService.saveRemark(
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
      await _artifactService.deleteRemark(remark);
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
            else if (_authManager.isAuthenticated)
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
                    child: Text('Signed in as ${_authManager.currentUser?.email ?? "User"}'),
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
          enabled: _authManager.isAuthenticated,
          onSubmitted: _submitRemark,
          onLogin: _showAuthPrompt,
        ),
      ],
    );
  }
}