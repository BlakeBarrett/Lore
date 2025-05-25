# Migration Guide: Abstracting Backend Implementation

This guide outlines the migration strategy from the current Supabase-specific implementation to a flexible, multi-backend architecture.

## 🎯 Migration Goals

1. **Backend Agnostic**: Support Firebase, Supabase, local SQLite, and future providers
2. **Zero Downtime**: Maintain existing functionality during migration
3. **Configuration Driven**: Easy switching between backends via configuration
4. **Future Proof**: Easy to add new backend providers

## 📋 Migration Steps

### Phase 1: Foundation (Current State ✅)
- [x] Created `LoreBackend` abstract interface
- [x] Created `BackendConfig` configuration classes
- [x] Created `SupabaseBackendAdapter` for legacy compatibility
- [x] Created configuration templates
- [x] Documented migration strategy

### Phase 2: Core Migration
1. **Extract Data Layer Methods**
   ```dart
   // Move from LoreAPI to SupabaseBackendAdapter
   Future<Artifact?> loadArtifact(String md5) // ✅ Interface defined
   Future<List<Remark>> loadRemarks(String md5) // ✅ Interface defined
   Future<void> saveRemark(...) // ✅ Interface defined
   ```

2. **Update LoreAPI to use Backend Interface**
   ```dart
   class LoreAPI {
     static LoreBackend _backend = createDefaultBackend();
     
     static Future<Artifact?> loadArtifact(String md5) {
       return _backend.loadArtifact(md5);
     }
   }
   ```

3. **Migrate Console App**
   ```dart
   // In lore_console.dart
   final backend = createDefaultBackend();
   await backend.initialize(await BackendConfigLoader.loadBestAvailable());
   ```

### Phase 3: Alternative Backend Implementations

#### Firebase Backend
```dart
class FirebaseBackend implements LoreBackend {
  @override
  Future<void> initialize(BackendConfig config) async {
    Firebase.initializeApp(
      options: FirebaseOptions(
        projectId: config.config['project_id'],
        apiKey: config.config['api_key'],
      ),
    );
  }
  
  @override
  Future<Artifact?> loadArtifact(String md5) async {
    final doc = await FirebaseFirestore.instance
        .collection('artifacts')
        .doc(md5)
        .get();
    return doc.exists ? Artifact.fromMap(doc.data()!) : null;
  }
}
```

#### Local SQLite Backend
```dart
class LocalBackend implements LoreBackend {
  late Database _db;
  
  @override
  Future<void> initialize(BackendConfig config) async {
    _db = await openDatabase(
      config.config['db_path'],
      version: 1,
      onCreate: _createTables,
    );
  }
  
  @override
  Future<Artifact?> loadArtifact(String md5) async {
    final maps = await _db.query(
      'artifacts',
      where: 'md5sum = ?',
      whereArgs: [md5],
    );
    return maps.isNotEmpty ? Artifact.fromMap(maps.first) : null;
  }
}
```

### Phase 4: Configuration Management

1. **Environment Detection**
   ```dart
   Future<BackendConfig> detectBestBackend() async {
     // Try Firebase
     if (await canUseFirebase()) return loadFirebaseConfig();
     
     // Try Supabase
     if (await canUseSupabase()) return loadSupabaseConfig();
     
     // Fall back to local
     return BackendConfig.local();
   }
   ```

2. **Multi-Environment Support**
   ```yaml
   # backend_config.yaml
   environments:
     development:
       backend: { type: local }
     staging:
       backend: { type: firebase, project_id: "lore-staging" }
     production:
       backend: { type: firebase, project_id: "lore-prod" }
   ```

### Phase 5: Advanced Features

1. **Backend Health Monitoring**
   ```dart
   class BackendHealthMonitor {
     Stream<bool> monitorConnection(LoreBackend backend);
     Future<void> switchBackend(BackendConfig newConfig);
   }
   ```

2. **Data Synchronization**
   ```dart
   class BackendSyncManager {
     Future<void> syncBetweenBackends(LoreBackend source, LoreBackend target);
     Future<void> createBackup(LoreBackend backend, String path);
   }
   ```

## 🔧 Implementation Priority

### High Priority (Next Sprint)
1. ✅ Abstract backend interface
2. **Migrate LoreAPI to use backend interface**
3. **Implement Firebase backend**
4. **Add configuration loading**

### Medium Priority
1. **Implement local SQLite backend**
2. **Add backend switching UI**
3. **Add health monitoring**

### Low Priority
1. **Data synchronization between backends**
2. **Advanced configuration management**
3. **Backend analytics and metrics**

## 🧪 Testing Strategy

### Unit Tests
```dart
void main() {
  group('Backend Interface Tests', () {
    test('Firebase backend loads artifacts', () async {
      final backend = FirebaseBackend();
      await backend.initialize(BackendConfig.firebase(...));
      final artifact = await backend.loadArtifact('test-md5');
      expect(artifact, isNotNull);
    });
  });
}
```

### Integration Tests
```dart
void main() {
  group('Multi-Backend Tests', () {
    test('Can switch between backends', () async {
      final firebase = FirebaseBackend();
      final local = LocalBackend();
      
      // Test data consistency across backends
      await testDataConsistency(firebase, local);
    });
  });
}
```

## 📁 File Structure Changes

```
lib/
├── backends/
│   ├── lore_backend.dart           # Abstract interface
│   ├── firebase_backend.dart       # Firebase implementation
│   ├── supabase_backend.dart       # Supabase implementation  
│   ├── local_backend.dart          # SQLite implementation
│   └── mock_backend.dart           # Testing implementation
├── config/
│   ├── backend_config.dart         # Configuration classes
│   ├── config_loader.dart          # Configuration loading
│   └── environment_detector.dart   # Auto-detection logic
├── migration/
│   ├── backend_adapter.dart        # Legacy compatibility
│   └── migration_utils.dart        # Migration helpers
└── lore_api.dart                   # Updated to use backends
```

## 🚀 Quick Start for Next Branch

1. **Create new branch**: `git checkout -b feature/abstract-backend-layer`

2. **Start with Firebase implementation**:
   ```bash
   flutter pub add firebase_core firebase_firestore firebase_auth
   ```

3. **Implement FirebaseBackend** using the interface in `lib/lore_backend.dart`

4. **Update LoreAPI** to use the backend interface

5. **Test with both Firebase and Supabase** configurations

6. **Add configuration switching** in the Flutter app UI

## 💡 Benefits of This Architecture

- **Flexibility**: Easy to switch backends without code changes
- **Resilience**: Fallback options if one backend is unavailable
- **Testing**: Mock backends for reliable unit tests
- **Performance**: Local backend for offline usage
- **Cost Management**: Switch providers based on pricing/features
- **Future Proof**: Easy to add new providers as they emerge

---

**Next Steps**: Start with Firebase backend implementation, then gradually migrate existing LoreAPI calls to use the abstracted interface.
