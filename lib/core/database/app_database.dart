import 'dart:async';

/// Models for Local Offline Database & Sync Queue
class SyncQueueItem {
  final String id;
  final String entityType; // "sale", "transaction", "stock_movement", "customer_payment", "product"
  final String action; // "create", "update"
  final int localTimestamp;
  final String payloadJson;
  final int attempts;
  final String? lastError;
  final int createdAt;

  SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.action,
    required this.localTimestamp,
    required this.payloadJson,
    this.attempts = 0,
    this.lastError,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'entityType': entityType,
    'action': action,
    'localTimestamp': localTimestamp,
    'payloadJson': payloadJson,
    'attempts': attempts,
    'lastError': lastError,
    'createdAt': createdAt,
  };

  factory SyncQueueItem.fromJson(Map<String, dynamic> map) => SyncQueueItem(
    id: map['id'] as String,
    entityType: map['entityType'] as String,
    action: map['action'] as String,
    localTimestamp: map['localTimestamp'] as int,
    payloadJson: map['payloadJson'] as String,
    attempts: (map['attempts'] as int?) ?? 0,
    lastError: map['lastError'] as String?,
    createdAt: map['createdAt'] as int,
  );
}

class LocalProductData {
  final String id;
  final String? serverId;
  final String businessId;
  final String name;
  final String? sku;
  final String category;
  final double costPrice;
  final double sellPrice;
  final double currentStock;
  final double minStockLevel;
  final String unit;
  final bool isTaxable;
  final double taxRate;
  final bool isArchived;
  final bool isSynced;
  final int updatedAt;

  LocalProductData({
    required this.id,
    this.serverId,
    required this.businessId,
    required this.name,
    this.sku,
    required this.category,
    required this.costPrice,
    required this.sellPrice,
    required this.currentStock,
    required this.minStockLevel,
    this.unit = 'pcs',
    this.isTaxable = true,
    this.taxRate = 0.18,
    this.isArchived = false,
    this.isSynced = false,
    required this.updatedAt,
  });
}

class LocalSaleData {
  final String id;
  final String? serverId;
  final String businessId;
  final String saleNumber;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String itemsJson;
  final double subtotalAmount;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final String paymentStatus;
  final String paymentMethod;
  final String? momoReference;
  final bool isCredit;
  final int? dueDate;
  final String? efrisFiscalCode;
  final String? efrisQrCodeData;
  final String deviceId;
  final int localTimestamp;
  final bool isSynced;

  LocalSaleData({
    required this.id,
    this.serverId,
    required this.businessId,
    required this.saleNumber,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.itemsJson,
    required this.subtotalAmount,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    this.momoReference,
    this.isCredit = false,
    this.dueDate,
    this.efrisFiscalCode,
    this.efrisQrCodeData,
    required this.deviceId,
    required this.localTimestamp,
    this.isSynced = false,
  });
}

class LocalTransactionData {
  final String id;
  final String? serverId;
  final String businessId;
  final String type;
  final String category;
  final double amount;
  final String paymentMethod;
  final String? reference;
  final String? notes;
  final bool isRecurring;
  final int date;
  final String deviceId;
  final bool isSynced;

  LocalTransactionData({
    required this.id,
    this.serverId,
    required this.businessId,
    required this.type,
    required this.category,
    required this.amount,
    required this.paymentMethod,
    this.reference,
    this.notes,
    this.isRecurring = false,
    required this.date,
    required this.deviceId,
    this.isSynced = false,
  });
}

/// Cross-Platform Database for DUKA (Web, Desktop, Android, iOS)
class AppDatabase {
  final List<SyncQueueItem> _queue = [];
  final Map<String, LocalProductData> _products = {};
  final Map<String, LocalSaleData> _sales = {};
  final Map<String, LocalTransactionData> _transactions = {};

  final _changeStreamController = StreamController<void>.broadcast();
  Stream<void> get onChange => _changeStreamController.stream;

  AppDatabase() {
    _initDefaultProducts();
  }

  void _initDefaultProducts() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final defaults = [
      LocalProductData(id: 'p1', businessId: 'biz_default', name: 'NPK 17:17:17 Fertilizer 50kg', category: 'Agro', costPrice: 150000, sellPrice: 185000, currentStock: 24, minStockLevel: 10, unit: 'bag', updatedAt: now),
      LocalProductData(id: 'p2', businessId: 'biz_default', name: 'DAP Fertilizer 50kg', category: 'Agro', costPrice: 170000, sellPrice: 210000, currentStock: 18, minStockLevel: 10, unit: 'bag', updatedAt: now),
      LocalProductData(id: 'p3', businessId: 'biz_default', name: 'Longe 5 Maize Seeds 2kg', category: 'Seeds', costPrice: 12000, sellPrice: 16000, currentStock: 4, minStockLevel: 15, unit: 'pkt', updatedAt: now),
      LocalProductData(id: 'p4', businessId: 'biz_default', name: 'Bazooka Maize Seeds 2kg', category: 'Seeds', costPrice: 14000, sellPrice: 18500, currentStock: 30, minStockLevel: 10, unit: 'pkt', updatedAt: now),
      LocalProductData(id: 'p5', businessId: 'biz_default', name: 'Roundup Weedkiller 1L', category: 'Chemicals', costPrice: 22000, sellPrice: 28000, currentStock: 3, minStockLevel: 10, unit: 'bottle', updatedAt: now),
      LocalProductData(id: 'p6', businessId: 'biz_default', name: 'Dudu Acelamectin Pesticide 500ml', category: 'Chemicals', costPrice: 18000, sellPrice: 24000, currentStock: 15, minStockLevel: 5, unit: 'bottle', updatedAt: now),
      LocalProductData(id: 'p7', businessId: 'biz_default', name: 'Tororo Cement 32.5R 50kg', category: 'Hardware', costPrice: 32000, sellPrice: 36000, currentStock: 80, minStockLevel: 20, unit: 'bag', updatedAt: now),
      LocalProductData(id: 'p8', businessId: 'biz_default', name: 'Iron Sheets 28 Gauge 3m', category: 'Hardware', costPrice: 42000, sellPrice: 48500, currentStock: 60, minStockLevel: 15, unit: 'pc', updatedAt: now),
      LocalProductData(id: 'p9', businessId: 'biz_default', name: 'Water Pump Knapsack 16L', category: 'Equipment', costPrice: 65000, sellPrice: 85000, currentStock: 8, minStockLevel: 5, unit: 'pc', updatedAt: now),
    ];
    for (final p in defaults) {
      _products[p.id] = p;
    }
  }

  // --- Queue Operations ---
  Future<void> insertQueueItem(SyncQueueItem item) async {
    _queue.removeWhere((q) => q.id == item.id);
    _queue.add(item);
    _changeStreamController.add(null);
  }

  Future<List<SyncQueueItem>> getPendingQueue() async {
    return List.unmodifiable(_queue);
  }

  Future<int> getPendingQueueCount() async {
    return _queue.length;
  }

  Future<void> removeQueueItem(String id) async {
    _queue.removeWhere((q) => q.id == id);
    _changeStreamController.add(null);
  }

  // --- Sales Operations ---
  Future<void> insertSale(LocalSaleData sale) async {
    _sales[sale.id] = sale;
    _changeStreamController.add(null);
  }

  Future<void> markSaleSynced(String offlineId, {String? serverId}) async {
    final existing = _sales[offlineId];
    if (existing != null) {
      _sales[offlineId] = LocalSaleData(
        id: existing.id,
        serverId: serverId ?? existing.serverId,
        businessId: existing.businessId,
        saleNumber: existing.saleNumber,
        customerId: existing.customerId,
        customerName: existing.customerName,
        customerPhone: existing.customerPhone,
        itemsJson: existing.itemsJson,
        subtotalAmount: existing.subtotalAmount,
        taxAmount: existing.taxAmount,
        discountAmount: existing.discountAmount,
        totalAmount: existing.totalAmount,
        paidAmount: existing.paidAmount,
        dueAmount: existing.dueAmount,
        paymentStatus: existing.paymentStatus,
        paymentMethod: existing.paymentMethod,
        momoReference: existing.momoReference,
        isCredit: existing.isCredit,
        dueDate: existing.dueDate,
        efrisFiscalCode: existing.efrisFiscalCode,
        efrisQrCodeData: existing.efrisQrCodeData,
        deviceId: existing.deviceId,
        localTimestamp: existing.localTimestamp,
        isSynced: true,
      );
      _changeStreamController.add(null);
    }
  }

  // --- Transactions Operations ---
  Future<void> insertTransaction(LocalTransactionData tx) async {
    _transactions[tx.id] = tx;
    _changeStreamController.add(null);
  }

  Future<void> markTransactionSynced(String id, {String? serverId}) async {
    final existing = _transactions[id];
    if (existing != null) {
      _transactions[id] = LocalTransactionData(
        id: existing.id,
        serverId: serverId ?? existing.serverId,
        businessId: existing.businessId,
        type: existing.type,
        category: existing.category,
        amount: existing.amount,
        paymentMethod: existing.paymentMethod,
        reference: existing.reference,
        notes: existing.notes,
        isRecurring: existing.isRecurring,
        date: existing.date,
        deviceId: existing.deviceId,
        isSynced: true,
      );
      _changeStreamController.add(null);
    }
  }

  // --- Products Operations ---
  Future<List<LocalProductData>> getProducts() async {
    return _products.values.where((p) => !p.isArchived).toList();
  }

  Future<void> updateProductStock(String productId, double delta) async {
    final existing = _products[productId];
    if (existing != null) {
      _products[productId] = LocalProductData(
        id: existing.id,
        serverId: existing.serverId,
        businessId: existing.businessId,
        name: existing.name,
        sku: existing.sku,
        category: existing.category,
        costPrice: existing.costPrice,
        sellPrice: existing.sellPrice,
        currentStock: (existing.currentStock + delta).clamp(0, 9999999),
        minStockLevel: existing.minStockLevel,
        unit: existing.unit,
        isTaxable: existing.isTaxable,
        taxRate: existing.taxRate,
        isArchived: existing.isArchived,
        isSynced: false,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      _changeStreamController.add(null);
    }
  }

  void close() {
    _changeStreamController.close();
  }
}
