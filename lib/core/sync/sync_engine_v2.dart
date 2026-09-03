import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../network/convex_client.dart';
import '../database/app_database.dart';

/// Improved sync state with conflict tracking
class SyncState {
  final bool isSyncing;
  final int pendingCount;
  final int conflictCount;
  final DateTime? lastSyncTime;
  final String? lastError;
  final List<SyncConflict> recentConflicts;

  const SyncState({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.conflictCount = 0,
    this.lastSyncTime,
    this.lastError,
    this.recentConflicts = const [],
  });

  SyncState copyWith({
    bool? isSyncing,
    int? pendingCount,
    int? conflictCount,
    DateTime? lastSyncTime,
    String? lastError,
    List<SyncConflict>? recentConflicts,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      conflictCount: conflictCount ?? this.conflictCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError,
      recentConflicts: recentConflicts ?? this.recentConflicts,
    );
  }
}

/// Represents a sync conflict that requires resolution
class SyncConflict {
  final String queueId;
  final String entityType;
  final String
      conflictType; // version_mismatch, duplicate_prevention, validation_error
  final String error;
  final DateTime detectedAt;
  final bool resolved;

  SyncConflict({
    required this.queueId,
    required this.entityType,
    required this.conflictType,
    required this.error,
    required this.detectedAt,
    this.resolved = false,
  });

  factory SyncConflict.fromMap(Map<String, dynamic> map) {
    return SyncConflict(
      queueId: map['queueId'] as String,
      entityType: map['entityType'] as String,
      conflictType: map['conflictType'] as String,
      error: map['error'] as String,
      detectedAt: DateTime.fromMillisecondsSinceEpoch(map['detectedAt'] as int),
      resolved: map['resolved'] as bool? ?? false,
    );
  }
}

/// Enhanced Sync Engine with Conflict Resolution & Idempotency
class SyncEngine extends ChangeNotifier {
  final AppDatabase db;
  final ConvexClient convexClient;
  final String businessId;
  final String userId;
  final String deviceId;

  SyncState _state = const SyncState();
  final List<SyncConflict> _conflicts = [];
  SyncState get state => _state;
  bool get isSyncing => _state.isSyncing;
  int get pendingCount => _state.pendingCount;
  int get conflictCount => _state.conflictCount;

  Timer? _autoSyncTimer;
  StreamSubscription<void>? _dbSubscription;
  static const _uuid = Uuid();

  // Retry configuration
  static const _maxRetries = 3;
  static const _retryDelayMs = 2000;

  // Track in-flight syncs to prevent concurrent syncs
  String? _currentSyncBatchId;

  SyncEngine({
    required this.db,
    required this.convexClient,
    required this.businessId,
    required this.userId,
    required this.deviceId,
  }) {
    _dbSubscription = db.onChange.listen((_) => refreshPendingCount());
    _startAutoSync();
    refreshPendingCount();
  }

  void _startAutoSync() {
    // Auto-sync every 30 seconds if items are pending
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      syncNow();
    });
  }

  Future<void> refreshPendingCount() async {
    try {
      final count = await db.getPendingQueueCount();
      _state = _state.copyWith(
        pendingCount: count,
        conflictCount:
            _conflicts.where((conflict) => !conflict.resolved).length,
      );
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error counting queue: $e');
    }
  }

  /// Enqueue an offline mutation with optional version tracking
  Future<String> enqueueMutation({
    required String entityType,
    required String action,
    required Map<String, dynamic> payload,
    int? timestamp,
  }) async {
    final queueId = _uuid.v4();
    final now = timestamp ?? DateTime.now().millisecondsSinceEpoch;

    await db.insertQueueItem(
      SyncQueueItem(
        id: queueId,
        entityType: entityType,
        action: action,
        localTimestamp: now,
        payloadJson: jsonEncode(payload),
        createdAt: now,
      ),
    );

    await refreshPendingCount();
    syncNow(); // Trigger immediate sync attempt
    return queueId;
  }

  /// Process pending queue items with conflict detection & retry logic
  Future<void> syncNow() async {
    // Prevent concurrent syncs
    if (_state.isSyncing || _currentSyncBatchId != null) {
      if (kDebugMode) print('Sync already in progress, skipping');
      return;
    }

    final items = await db.getPendingQueue();
    if (items.isEmpty) {
      _state = _state.copyWith(pendingCount: 0);
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isSyncing: true, lastError: null);
    notifyListeners();

    // Generate unique batch ID for idempotency
    final syncBatchId = _uuid.v4();
    _currentSyncBatchId = syncBatchId;

    try {
      final payloads = items
          .map((item) => {
                'queueId': item.id,
                'entityType': item.entityType,
                'action': item.action,
                'localTimestamp': item.localTimestamp,
                'data': item.payloadJson,
              })
          .toList();

      // Attempt sync with exponential backoff retry
      dynamic result;
      int retryCount = 0;

      while (retryCount < _maxRetries && result == null) {
        try {
          result = await convexClient.mutation('sync:processBatchOfflineSync', {
            'businessId': businessId,
            'userId': userId,
            'deviceId': deviceId,
            'syncBatchId': syncBatchId,
            'payloads': payloads,
          });
          break;
        } catch (e) {
          retryCount++;
          if (retryCount < _maxRetries) {
            if (kDebugMode) {
              print('Sync attempt $retryCount failed: $e. Retrying...');
            }
            await Future.delayed(
              Duration(milliseconds: _retryDelayMs * retryCount),
            );
          } else {
            throw e;
          }
        }
      }

      if (result == null) {
        throw Exception('Sync failed after $_maxRetries retries');
      }

      // Process results with conflict handling
      if (result is List) {
        await _processSyncResults(result, items);
      }

      _state = _state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      );
      await refreshPendingCount();
    } catch (e) {
      if (kDebugMode) print('SyncEngine sync failed: $e');
      _state = _state.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      );
      notifyListeners();
    } finally {
      _currentSyncBatchId = null;
    }
  }

  /// Process sync results and handle conflicts
  Future<void> _processSyncResults(
    List<dynamic> results,
    List<SyncQueueItem> originalItems,
  ) async {
    final conflicts = <SyncConflict>[];

    for (final res in results) {
      final queueId = res['queueId'] as String?;
      final status = res['status'] as String?;
      final serverId = res['serverId'] as String?;
      final conflictType = res['conflictType'] as String?;
      final error = res['error'] as String?;

      if (queueId == null) continue;

      // Find original queue item
      final queuedItem = originalItems.firstWhere(
        (item) => item.id == queueId,
        orElse: () => null as dynamic,
      ) as SyncQueueItem?;

      if (queuedItem == null) continue;

      Map<String, dynamic> localPayload = {};
      try {
        localPayload =
            jsonDecode(queuedItem.payloadJson) as Map<String, dynamic>;
      } catch (_) {}

      final localRecordId = localPayload['id'] as String? ?? queueId;

      if (status == 'success') {
        // Successfully synced - remove from queue
        await db.removeQueueItem(queueId);
        await db.markSaleSynced(localRecordId, serverId: serverId);
        await db.markTransactionSynced(localRecordId, serverId: serverId);
      } else if (status == 'conflict') {
        // Conflict detected - store for user review
        final conflict = SyncConflict(
          queueId: queueId,
          entityType: queuedItem.entityType,
          conflictType: conflictType ?? 'unknown',
          error: error ?? 'Unknown conflict',
          detectedAt: DateTime.now(),
        );

        _conflicts.add(conflict);
        conflicts.add(conflict);

        if (kDebugMode) {
          print(
              'Sync conflict detected: ${conflict.conflictType} - ${conflict.error}');
        }
      } else if (status == 'error') {
        // Non-conflict error - log and skip
        if (kDebugMode) {
          print('Sync error for $queueId: $error');
        }
        // Keep in queue for retry, but don't process further
      }
    }

    // Update state with conflicts
    if (conflicts.isNotEmpty) {
      _state = _state.copyWith(
        conflictCount: _conflicts.length,
        recentConflicts: conflicts,
      );
      notifyListeners();
    }
  }

  /// User resolves a conflict by choosing server or client version
  Future<void> resolveConflict({
    required String conflictQueueId,
    required String strategy, // 'server' or 'client'
  }) async {
    try {
      // Notify server of resolution
      await convexClient.mutation('sync:resolveConflict', {
        'businessId': businessId,
        'entityId': conflictQueueId,
        'strategy': strategy,
      });

      // Mark conflict as resolved locally
      final conflictIndex = _conflicts.indexWhere(
        (conflict) => conflict.queueId == conflictQueueId,
      );
      if (conflictIndex >= 0) {
        final conflict = _conflicts[conflictIndex];
        _conflicts[conflictIndex] = SyncConflict(
          queueId: conflict.queueId,
          entityType: conflict.entityType,
          conflictType: conflict.conflictType,
          error: conflict.error,
          detectedAt: conflict.detectedAt,
          resolved: true,
        );
      }

      // If client strategy, re-queue the item for retry
      if (strategy == 'client') {
        final conflict = _conflicts.cast<SyncConflict?>().firstWhere(
              (item) => item?.queueId == conflictQueueId,
              orElse: () => null,
            );
        if (conflict != null) {
          // Re-insert to queue for retry
          // (implementation depends on your DB schema)
        }
      } else {
        // Server strategy: remove from queue
        await db.removeQueueItem(conflictQueueId);
      }

      await refreshPendingCount();
    } catch (e) {
      if (kDebugMode) print('Failed to resolve conflict: $e');
      rethrow;
    }
  }

  /// Get all unresolved conflicts
  Future<List<SyncConflict>> getUnresolvedConflicts() async {
    return _conflicts.where((conflict) => !conflict.resolved).toList();
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _dbSubscription?.cancel();
    super.dispose();
  }
}

/// Extension for tracking record versions
extension VersionTracking on Map<String, dynamic> {
  /// Add version to payload for conflict detection
  Map<String, dynamic> withVersion(int version) {
    return {
      ...this,
      '_version': version,
    };
  }

  /// Get version from payload
  int getVersion() => this['_version'] as int? ?? 0;
}
