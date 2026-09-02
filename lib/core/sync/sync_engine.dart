import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../network/convex_client.dart';
import '../database/app_database.dart';

class SyncState {
  final bool isSyncing;
  final int pendingCount;
  final DateTime? lastSyncTime;
  final String? lastError;

  const SyncState({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.lastSyncTime,
    this.lastError,
  });

  SyncState copyWith({
    bool? isSyncing,
    int? pendingCount,
    DateTime? lastSyncTime,
    String? lastError,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError,
    );
  }
}

class SyncEngine extends ChangeNotifier {
  final AppDatabase db;
  final ConvexClient convexClient;
  final String businessId;
  final String userId;
  final String deviceId;

  SyncState _state = const SyncState();
  SyncState get state => _state;
  bool get isSyncing => _state.isSyncing;
  int get pendingCount => _state.pendingCount;

  Timer? _autoSyncTimer;
  StreamSubscription<void>? _dbSubscription;
  static const _uuid = Uuid();

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
    // Attempt sync every 30 seconds if items are queued
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      syncNow();
    });
  }

  Future<void> refreshPendingCount() async {
    try {
      final count = await db.getPendingQueueCount();
      _state = _state.copyWith(pendingCount: count);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error counting queue: $e');
    }
  }

  /// Enqueue an offline mutation to Local SyncQueue
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

    // Trigger immediate background sync attempt
    syncNow();
    return queueId;
  }

  /// Process pending queue items in a single batch to Convex
  Future<void> syncNow() async {
    if (_state.isSyncing) return;

    final items = await db.getPendingQueue();
    if (items.isEmpty) {
      _state = _state.copyWith(pendingCount: 0);
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isSyncing: true, lastError: null);
    notifyListeners();

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

      final result =
          await convexClient.mutation('sync:processBatchOfflineSync', {
        'businessId': businessId,
        'userId': userId,
        'deviceId': deviceId,
        'payloads': payloads,
      });

      if (result is List) {
        for (final res in result) {
          final queueId = res['queueId'] as String?;
          final status = res['status'] as String?;
          final serverId = res['serverId'] as String?;

          if (queueId != null && status == 'success') {
            final queuedItem = items.cast<SyncQueueItem?>().firstWhere(
                  (item) => item?.id == queueId,
                  orElse: () => null,
                );
            Map<String, dynamic> localPayload = {};
            if (queuedItem != null) {
              try {
                localPayload =
                    jsonDecode(queuedItem.payloadJson) as Map<String, dynamic>;
              } catch (_) {}
            }
            final localRecordId = localPayload['id'] as String? ?? queueId;

            // Remove from local queue
            await db.removeQueueItem(queueId);

            // Update matching local sale or transaction table
            await db.markSaleSynced(localRecordId, serverId: serverId);
            await db.markTransactionSynced(localRecordId, serverId: serverId);
          }
        }
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
    }
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _dbSubscription?.cancel();
    super.dispose();
  }
}
