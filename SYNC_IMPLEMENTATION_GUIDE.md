# Offline Sync - Practical Implementation Guide

## Quick Start: 5-Step Implementation

### Step 1: Add Database Tables for Sync Infrastructure (Drift)
```dart
// lib/core/database/sync_conflict_table.dart

import 'package:drift/drift.dart';

/// Stores sync conflicts for user review
@DataClassName("SyncConflictData")
class SyncConflicts extends Table {
  TextColumn get queueId => text()();
  TextColumn get entityType => text()();
  TextColumn get conflictType => text()(); // version_mismatch, duplicate, validation_error
  TextColumn get error => text()();
  IntColumn get detectedAt => integer()();
  BoolColumn get resolved => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {queueId};
}

/// Tracks versions for optimistic locking
@DataClassName("EntityVersionData")
class EntityVersions extends Table {
  TextColumn get entityId => text()();
  TextColumn get entityType => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get updatedAt => integer()();
  
  @override
  Set<Column> get primaryKey => {entityId, entityType};
}

/// Stores sync batch results for idempotency
@DataClassName("SyncBatchData")
class SyncBatches extends Table {
  TextColumn get syncBatchId => text()();
  TextColumn get results => text()(); // JSON
  IntColumn get processedAt => integer()();
  
  @override
  Set<Column> get primaryKey => {syncBatchId};
}
```

### Step 2: Update SyncQueueItem to Include Version Tracking
```dart
// lib/core/database/sync_queue_table.dart

import 'package:drift/drift.dart';

@DataClassName("SyncQueueItemData")
class SyncQueueItems extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get action => text()();
  IntColumn get localTimestamp => integer()();
  TextColumn get payloadJson => text()();
  IntColumn get clientVersion => integer().nullable()(); // NEW: For conflict detection
  IntColumn get createdAt => integer()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

### Step 3: Extend AppDatabase DAO Methods
```dart
// lib/core/database/app_database.dart (additions)

import 'package:drift/drift.dart';
import 'sync_conflict_table.dart';
import 'sync_queue_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    // ... existing tables
    SyncQueueItems,
    SyncConflicts,
    EntityVersions,
    SyncBatches,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  // ============================================================================
  // VERSION TRACKING
  // ============================================================================
  
  /// Get version of an entity for conflict detection
  Future<int> getEntityVersion(String entityId, String entityType) async {
    final version = await (select(entityVersions)
          ..where((tbl) => tbl.entityId.equals(entityId) & tbl.entityType.equals(entityType))
        ).getSingleOrNull();
    
    return version?.version ?? 1;
  }
  
  /// Update entity version after successful sync
  Future<void> updateEntityVersion(String entityId, String entityType) async {
    final current = await getEntityVersion(entityId, entityType);
    
    await into(entityVersions).insertOnConflictUpdate(
      EntityVersionsCompanion(
        entityId: Value(entityId),
        entityType: Value(entityType),
        version: Value(current + 1),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
  
  // ============================================================================
  // CONFLICT MANAGEMENT
  // ============================================================================
  
  /// Store a sync conflict for user review
  Future<void> insertConflict(SyncConflictData conflict) async {
    await into(syncConflicts).insertOnConflictUpdate(
      SyncConflictsCompanion(
        queueId: Value(conflict.queueId),
        entityType: Value(conflict.entityType),
        conflictType: Value(conflict.conflictType),
        error: Value(conflict.error),
        detectedAt: Value(conflict.detectedAt),
        resolved: Value(false),
      ),
    );
  }
  
  /// Get all unresolved conflicts
  Future<List<SyncConflictData>> getUnresolvedConflicts() async {
    return (select(syncConflicts)
          ..where((tbl) => tbl.resolved.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.detectedAt)])
        ).get();
  }
  
  /// Resolve a conflict
  Future<void> markConflictResolved(String queueId, String strategy) async {
    await (update(syncConflicts)..where((tbl) => tbl.queueId.equals(queueId)))
        .write(SyncConflictsCompanion(resolved: Value(true)));
  }
  
  /// Count unresolved conflicts
  Future<int> getConflictCount() async {
    return await (selectOnly(syncConflicts)
          ..addColumns([countAll()]))
        .map((row) => row.read(countAll()))
        .getSingle();
  }
  
  // ============================================================================
  // IDEMPOTENCY
  // ============================================================================
  
  /// Store sync batch results for idempotency
  Future<void> insertSyncBatch(String syncBatchId, String resultsJson) async {
    await into(syncBatches).insertOnConflictUpdate(
      SyncBatchesCompanion(
        syncBatchId: Value(syncBatchId),
        results: Value(resultsJson),
        processedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
  
  /// Get cached batch results
  Future<String?> getCachedBatchResults(String syncBatchId) async {
    final batch = await (select(syncBatches)
          ..where((tbl) => tbl.syncBatchId.equals(syncBatchId))
        ).getSingleOrNull();
    
    return batch?.results;
  }
  
  // ============================================================================
  // UPDATED QUEUE OPERATIONS
  // ============================================================================
  
  /// Insert queue item with version tracking
  Future<void> insertQueueItemWithVersion(
    String queueId,
    String entityType,
    String action,
    String payloadJson, {
    int? clientVersion,
  }) async {
    await into(syncQueueItems).insert(
      SyncQueueItemsCompanion(
        id: Value(queueId),
        entityType: Value(entityType),
        action: Value(action),
        localTimestamp: Value(DateTime.now().millisecondsSinceEpoch),
        payloadJson: Value(payloadJson),
        clientVersion: clientVersion != null ? Value(clientVersion) : const Value.absent(),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
  
  /// Get pending queue count
  Future<int> getPendingQueueCount() async {
    return await (selectOnly(syncQueueItems)
          ..addColumns([countAll()])
          ..where(syncQueueItems.synced.equals(false)))
        .map((row) => row.read(countAll()))
        .getSingle();
  }
  
  /// Get all pending items
  Future<List<SyncQueueItemData>> getPendingQueue() async {
    return (select(syncQueueItems)
          ..where((tbl) => tbl.synced.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
        ).get();
  }
}
```

### Step 4: Update SyncEngine to Use New Infrastructure
```dart
// lib/core/sync/sync_engine.dart (key updates)

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../network/convex_client.dart';
import '../database/app_database.dart';

class SyncEngine extends ChangeNotifier {
  final AppDatabase db;
  final ConvexClient convexClient;
  final String businessId;
  final String userId;
  final String deviceId;

  SyncState _state = const SyncState();
  String? _currentSyncBatchId;
  static const _uuid = Uuid();
  static const _maxRetries = 3;
  static const _retryDelayMs = 2000;

  SyncEngine({
    required this.db,
    required this.convexClient,
    required this.businessId,
    required this.userId,
    required this.deviceId,
  }) {
    _startAutoSync();
  }

  /// Enqueue mutation with version tracking
  Future<String> enqueueMutation({
    required String entityType,
    required String action,
    required Map<String, dynamic> payload,
    int? timestamp,
    int? clientVersion,
  }) async {
    final queueId = _uuid.v4();
    final now = timestamp ?? DateTime.now().millisecondsSinceEpoch;

    // Get current version if updating
    int? version;
    if (action == 'update' && payload['id'] != null) {
      version = await db.getEntityVersion(payload['id'] as String, entityType);
    }

    await db.insertQueueItemWithVersion(
      queueId,
      entityType,
      action,
      jsonEncode(payload),
      clientVersion: version,
    );

    await refreshPendingCount();
    syncNow();
    return queueId;
  }

  /// Enhanced sync with conflict handling
  Future<void> syncNow() async {
    if (_state.isSyncing || _currentSyncBatchId != null) return;

    final items = await db.getPendingQueue();
    if (items.isEmpty) return;

    _state = _state.copyWith(isSyncing: true, lastError: null);
    notifyListeners();

    final syncBatchId = _uuid.v4();
    _currentSyncBatchId = syncBatchId;

    try {
      // Check if batch was already processed (idempotency)
      final cachedResults = await db.getCachedBatchResults(syncBatchId);
      if (cachedResults != null) {
        if (kDebugMode) print('Using cached sync results for batch $syncBatchId');
        await _processSyncResults(jsonDecode(cachedResults), items);
        return;
      }

      final payloads = items
          .map((item) => {
                'queueId': item.id,
                'entityType': item.entityType,
                'action': item.action,
                'localTimestamp': item.localTimestamp,
                'data': item.payloadJson,
                'clientVersion': item.clientVersion ?? 0,
              })
          .toList();

      // Sync with retry logic
      Map<String, dynamic>? result;
      int retryCount = 0;

      while (retryCount < _maxRetries && result == null) {
        try {
          result = await convexClient.mutation(
            'sync:processBatchOfflineSync',
            {
              'businessId': businessId,
              'userId': userId,
              'deviceId': deviceId,
              'syncBatchId': syncBatchId,
              'payloads': payloads,
            },
          );
          break;
        } catch (e) {
          retryCount++;
          if (retryCount < _maxRetries) {
            await Future.delayed(Duration(milliseconds: _retryDelayMs * retryCount));
          } else {
            throw e;
          }
        }
      }

      if (result != null) {
        // Cache results
        await db.insertSyncBatch(syncBatchId, jsonEncode(result));
        await _processSyncResults(result, items);
      }

      _state = _state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      _state = _state.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      );
      if (kDebugMode) print('Sync error: $e');
    } finally {
      _currentSyncBatchId = null;
      notifyListeners();
      await refreshPendingCount();
    }
  }

  /// Process sync results and handle conflicts
  Future<void> _processSyncResults(
    Map<String, dynamic> result,
    List<SyncQueueItemData> originalItems,
  ) async {
    final results = result['results'] as List;

    for (final res in results) {
      final queueId = res['queueId'] as String?;
      final status = res['status'] as String?;
      final serverId = res['serverId'] as String?;

      if (queueId == null) continue;

      if (status == 'success') {
        // Mark as synced and update version
        await db.markQueueItemSynced(queueId);
        
        if (serverId != null) {
          final item = originalItems.firstWhere((i) => i.id == queueId);
          await db.updateEntityVersion(serverId, item.entityType);
        }
      } else if (status == 'conflict') {
        // Store conflict for user review
        await db.insertConflict(
          SyncConflictData(
            queueId: queueId,
            entityType: res['entityType'] ?? 'unknown',
            conflictType: res['conflictType'] ?? 'unknown',
            error: res['error'] ?? 'Unknown conflict',
            detectedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        if (kDebugMode) print('Conflict detected: ${res['error']}');
      }
    }
  }

  /// Get unresolved conflicts
  Future<List<SyncConflictData>> getUnresolvedConflicts() async {
    return await db.getUnresolvedConflicts();
  }

  /// User resolves conflict
  Future<void> resolveConflict({
    required String conflictQueueId,
    required String strategy,
  }) async {
    try {
      await convexClient.mutation('sync:resolveConflict', {
        'businessId': businessId,
        'entityId': conflictQueueId,
        'strategy': strategy,
      });

      await db.markConflictResolved(conflictQueueId, strategy);

      if (strategy == 'client') {
        // Re-queue for retry
        // Implementation depends on your queue structure
      } else {
        // Remove from queue
        await db.removeQueueItem(conflictQueueId);
      }

      await refreshPendingCount();
    } catch (e) {
      if (kDebugMode) print('Failed to resolve conflict: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
```

### Step 5: Update UI to Show Conflicts
```dart
// lib/features/settings/presentation/sync_conflicts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sync/sync_engine.dart';

class SyncConflictsScreen extends ConsumerStatefulWidget {
  const SyncConflictsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SyncConflictsScreen> createState() =>
      _SyncConflictsScreenState();
}

class _SyncConflictsScreenState extends ConsumerState<SyncConflictsScreen> {
  late Future<List<SyncConflictData>> _conflicts;

  @override
  void initState() {
    super.initState();
    _loadConflicts();
  }

  void _loadConflicts() {
    final syncEngine = ref.read(syncEngineProvider);
    _conflicts = syncEngine.getUnresolvedConflicts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync Conflicts')),
      body: FutureBuilder<List<SyncConflictData>>(
        future: _conflicts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No conflicts found'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final conflict = snapshot.data![index];
              return ConflictCard(
                conflict: conflict,
                onResolve: (strategy) => _resolveConflict(conflict, strategy),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _resolveConflict(
    SyncConflictData conflict,
    String strategy,
  ) async {
    final syncEngine = ref.read(syncEngineProvider);
    
    try {
      await syncEngine.resolveConflict(
        conflictQueueId: conflict.queueId,
        strategy: strategy,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conflict resolved with "$strategy" strategy')),
      );
      
      setState(() => _loadConflicts());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resolving conflict: $e')),
      );
    }
  }
}

class ConflictCard extends StatelessWidget {
  final SyncConflictData conflict;
  final Function(String) onResolve;

  const ConflictCard({
    required this.conflict,
    required this.onResolve,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conflict.entityType.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${conflict.conflictType}: ${conflict.error}',
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => onResolve('server'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: const Text('Use Server'),
                ),
                ElevatedButton(
                  onPressed: () => onResolve('client'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                  ),
                  child: const Text('Retry Locally'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Testing the Implementation

```bash
# Run Dart tests
flutter test lib/core/sync/sync_engine_test.dart

# Monitor Convex logs
npx convex logs --tailf
```

---

## Rollback Plan

If issues occur:

```bash
# Revert schema
git checkout HEAD -- convex/schema.ts

# Revert sync engine
git checkout HEAD -- lib/core/sync/sync_engine.dart

# Redeploy
npx convex deploy
flutter pub get
```
