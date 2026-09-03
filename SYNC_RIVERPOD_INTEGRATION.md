# Sync Engine Integration with Riverpod

## 📍 Integration Points in Your App

### 1. Update Core Providers
```dart
// lib/core/providers/app_providers.dart (additions)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../sync/sync_engine.dart';
import '../database/app_database.dart';
import '../network/convex_client.dart';

// Existing providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState?>((ref) {
  // ...
});

final businessIdProvider = Provider<String>((ref) {
  return ref.watch(authProvider)?.businessId ?? '';
});

final userIdProvider = Provider<String>((ref) {
  return ref.watch(authProvider)?.userId ?? '';
});

// ============================================================================
// NEW: Sync Engine Provider
// ============================================================================

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final convexClient = ref.watch(convexClientProvider);
  final businessId = ref.watch(businessIdProvider);
  final userId = ref.watch(userIdProvider);
  const deviceId = 'device_id'; // Get from device info

  return SyncEngine(
    db: db,
    convexClient: convexClient,
    businessId: businessId,
    userId: userId,
    deviceId: deviceId,
  );
});

// NEW: Sync state notifier for reactive UI
final syncStateProvider = StreamProvider<SyncState>((ref) {
  final syncEngine = ref.watch(syncEngineProvider);
  
  return Stream.periodic(
    const Duration(seconds: 1),
    (_) => syncEngine.state,
  );
});

// NEW: Pending sync count
final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return await db.getPendingQueueCount();
});

// NEW: Sync conflicts provider
final syncConflictsProvider = FutureProvider<List<SyncConflictData>>((ref) async {
  final syncEngine = ref.watch(syncEngineProvider);
  return await syncEngine.getUnresolvedConflicts();
});

// NEW: Trigger sync manually
final triggerSyncProvider = FutureProvider<void>((ref) async {
  final syncEngine = ref.watch(syncEngineProvider);
  await syncEngine.syncNow();
});
```

---

## 📱 Integration with Sales Creation

```dart
// lib/features/sales/presentation/pos_quick_sale_screen.dart (updated)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/database/app_database.dart';

class POSQuickSaleScreen extends ConsumerStatefulWidget {
  const POSQuickSaleScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<POSQuickSaleScreen> createState() => _POSQuickSaleScreenState();
}

class _POSQuickSaleScreenState extends ConsumerState<POSQuickSaleScreen> {
  final List<CartItem> _cartItems = [];
  double _discount = 0;
  
  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS - Quick Sale'),
        actions: [
          // Show sync indicator
          syncState.when(
            data: (state) => Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: state.isSyncing
                    ? Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text('${state.pendingCount} pending'),
                        ],
                      )
                    : Text(
                        '✓ ${state.pendingCount} pending',
                        style: const TextStyle(fontSize: 12),
                      ),
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Sync error', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Cart items
          Expanded(
            child: ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return CartItemTile(
                  item: item,
                  onQuantityChanged: (qty) {
                    setState(() => item.quantity = qty);
                  },
                  onRemove: () {
                    setState(() => _cartItems.removeAt(index));
                  },
                );
              },
            ),
          ),
          // Checkout button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => _completeCheckout(ref),
              child: const Text('Checkout'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeCheckout(WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);
    final syncEngine = ref.read(syncEngineProvider);
    final customerId = ref.read(authProvider)?.businessId;

    try {
      // Calculate totals
      final subtotal =
          _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
      final tax = subtotal * 0.18; // 18% Uganda VAT
      final total = subtotal + tax;

      // Create sale payload
      final salePayload = {
        'id': const Uuid().v4(), // offline ID
        'customerName': 'Walk-in Customer',
        'subtotalAmount': subtotal,
        'taxAmount': tax,
        'totalAmount': total,
        'paidAmount': total, // Assuming full payment
        'discountAmount': _discount,
        'paymentMethod': 'cash',
        'items': _cartItems
            .map((item) => {
                  'productId': item.productId,
                  'productName': item.name,
                  'quantity': item.quantity,
                  'unitPrice': item.price,
                  'costPrice': item.costPrice,
                  'subtotal': item.totalPrice,
                })
            .toList(),
      };

      // Enqueue sale for sync with version tracking
      final queueId = await syncEngine.enqueueMutation(
        entityType: 'sale',
        action: 'create',
        payload: salePayload,
        clientVersion: 1, // Initial version
      );

      // For each item, update stock (delta operation)
      for (final item in _cartItems) {
        await syncEngine.enqueueMutation(
          entityType: 'stock_adjustment',
          action: 'create',
          payload: {
            'id': const Uuid().v4(),
            'productId': item.productId,
            'deltaQuantity': -item.quantity, // Negative for sale
            'reason': 'sale',
          },
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale recorded. Syncing...')),
      );

      // Trigger immediate sync
      await syncEngine.syncNow();

      // Show confirmation
      if (mounted) {
        _showReceiptDialog(salePayload);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showReceiptDialog(Map<String, dynamic> saleData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sale Complete'),
        content: Text(
          'Sale recorded with total: UGX ${saleData['totalAmount']}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _cartItems.clear());
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

---

## 💳 Integration with Customer Payments

```dart
// lib/features/payments/presentation/customer_payment_screen.dart (updated)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';

class CustomerPaymentScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerPaymentScreen({
    required this.customerId,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<CustomerPaymentScreen> createState() =>
      _CustomerPaymentScreenState();
}

class _CustomerPaymentScreenState extends ConsumerState<CustomerPaymentScreen> {
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(getCustomerProvider(widget.customerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: customer.when(
        data: (cust) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: ${cust.name}'),
              const SizedBox(height: 8),
              Text(
                'Outstanding Debt: UGX ${cust.currentDebt.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount',
                  prefixText: 'UGX ',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _recordPayment(cust),
                child: const Text('Record Payment'),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _recordPayment(CustomerData customer) async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid amount')),
      );
      return;
    }

    final syncEngine = ref.read(syncEngineProvider);

    try {
      // Create payment mutation with version tracking
      await syncEngine.enqueueMutation(
        entityType: 'customer_payment',
        action: 'create',
        payload: {
          'id': const Uuid().v4(),
          'customerId': widget.customerId,
          'amount': amount,
          'paymentMethod': 'cash',
          'reference': 'Walk-in payment',
        },
        clientVersion: customer.version, // Include customer version
      );

      // Sync immediately
      await syncEngine.syncNow();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment of UGX $amount recorded')),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
```

---

## 🔍 Conflict Resolution UI

```dart
// lib/features/settings/presentation/sync_status_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';

class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);
    final conflicts = ref.watch(syncConflictsProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sync Status')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(syncConflictsProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sync Status Card
            syncState.when(
              data: (state) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sync Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Status:'),
                          Text(
                            state.isSyncing ? 'Syncing...' : 'Idle',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: state.isSyncing ? Colors.blue : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pending Items:'),
                          Text(
                            '${state.pendingCount}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Last Sync:'),
                          Text(
                            state.lastSyncTime != null
                                ? state.lastSyncTime!.toString().split('.')[0]
                                : 'Never',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      if (state.lastError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Error: ${state.lastError}',
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error loading sync state: $err'),
            ),
            const SizedBox(height: 24),
            // Conflicts Section
            Text(
              'Conflicts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            conflicts.when(
              data: (conflictList) {
                if (conflictList.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text('✓ No conflicts'),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: conflictList.length,
                  itemBuilder: (context, index) {
                    final conflict = conflictList[index];
                    return ConflictTile(
                      conflict: conflict,
                      onResolve: (strategy) =>
                          _resolveConflict(ref, conflict, strategy),
                    );
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resolveConflict(
    WidgetRef ref,
    SyncConflictData conflict,
    String strategy,
  ) async {
    final syncEngine = ref.read(syncEngineProvider);

    try {
      await syncEngine.resolveConflict(
        conflictQueueId: conflict.queueId,
        strategy: strategy,
      );

      // Refresh conflicts list
      ref.refresh(syncConflictsProvider);
    } catch (e) {
      // Show error
    }
  }
}

class ConflictTile extends StatelessWidget {
  final SyncConflictData conflict;
  final Function(String) onResolve;

  const ConflictTile({
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
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  conflict.conflictType.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${conflict.entityType}: ${conflict.error}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => onResolve('server'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text('Use Server'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => onResolve('client'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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

## 🧪 Testing Integration

```dart
// test/sync_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:duka/core/sync/sync_engine.dart';
import 'package:duka/core/database/app_database.dart';

void main() {
  group('Sync Engine Integration Tests', () {
    late SyncEngine syncEngine;
    late AppDatabase db;

    setUp(() async {
      // Initialize in-memory database
      db = AppDatabase();
      // Initialize sync engine...
    });

    test('Enqueue and sync sale creates correct stock movement', () async {
      final queueId = await syncEngine.enqueueMutation(
        entityType: 'sale',
        action: 'create',
        payload: {
          'id': 'sale_1',
          'items': [
            {'productId': 'prod_1', 'quantity': 5, 'price': 1000}
          ],
          'total': 5000,
        },
      );

      expect(queueId, isNotEmpty);
      expect(syncEngine.pendingCount, equals(1));
    });

    test('Concurrent sales from different devices sync correctly', () async {
      // Device A sells 10
      await syncEngine.enqueueMutation(
        entityType: 'sale',
        action: 'create',
        payload: {
          'id': 'sale_a',
          'items': [{'productId': 'prod_1', 'quantity': 10}],
        },
      );

      // Device B sells 5
      await syncEngine.enqueueMutation(
        entityType: 'sale',
        action: 'create',
        payload: {
          'id': 'sale_b',
          'items': [{'productId': 'prod_1', 'quantity': 5}],
        },
      );

      expect(syncEngine.pendingCount, equals(2));
      
      // Both sync
      await syncEngine.syncNow();

      // Stock should be decremented by both
      // (Verify via mock server response)
    });

    test('Version conflict detection works', () async {
      // Fetch product with version 1
      final version = await db.getEntityVersion('prod_1', 'product');

      // Try to update with older version
      await syncEngine.enqueueMutation(
        entityType: 'product',
        action: 'update',
        payload: {'id': 'prod_1', 'name': 'Updated'},
        clientVersion: version - 1, // Stale version
      );

      await syncEngine.syncNow();

      // Check for conflict
      final conflicts = await syncEngine.getUnresolvedConflicts();
      expect(
        conflicts.any((c) => c.conflictType == 'version_mismatch'),
        isTrue,
      );
    });
  });
}
```

---

## 🔌 Quick Integration Checklist

- [ ] Add new providers to `app_providers.dart`
- [ ] Import `sync_engine_v2.dart` (or renamed `sync_engine.dart`)
- [ ] Update all sale/payment screens to use `syncEngine.enqueueMutation()`
- [ ] Add sync status indicator to main navigation
- [ ] Create conflict resolution screen
- [ ] Add sync conflicts provider to relevant screens
- [ ] Test with 2+ devices simultaneously
- [ ] Monitor `syncConflicts` table
- [ ] Set up alerts for high conflict rates
