import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// SYNC QUEUE
// ---------------------------------------------------------------------------
class SyncQueueItem {
  final String id;
  final String entityType;
  final String action;
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

// ---------------------------------------------------------------------------
// PRODUCT (with Wholesale Price & Branch support)
// ---------------------------------------------------------------------------
class LocalProductData {
  final String id;
  final String? serverId;
  final String businessId;
  final String name;
  final String? sku;
  final String category;
  final double costPrice;
  final double sellPrice;
  final double? wholesalePrice;
  final double currentStock;
  final double minStockLevel;
  final String unit;
  final bool isTaxable;
  final double taxRate;
  final bool isArchived;
  final bool isSynced;
  final String? branchId;
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
    this.wholesalePrice,
    required this.currentStock,
    required this.minStockLevel,
    this.unit = 'pcs',
    this.isTaxable = true,
    this.taxRate = 0.18,
    this.isArchived = false,
    this.isSynced = false,
    this.branchId,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'serverId': serverId,
        'businessId': businessId,
        'name': name,
        'sku': sku,
        'category': category,
        'costPrice': costPrice,
        'sellPrice': sellPrice,
        'wholesalePrice': wholesalePrice,
        'currentStock': currentStock,
        'minStockLevel': minStockLevel,
        'unit': unit,
        'isTaxable': isTaxable,
        'taxRate': taxRate,
        'isArchived': isArchived,
        'isSynced': isSynced,
        'branchId': branchId,
        'updatedAt': updatedAt,
      };

  factory LocalProductData.fromJson(Map<String, dynamic> m) => LocalProductData(
        id: m['id'] as String,
        serverId: m['serverId'] as String?,
        businessId: m['businessId'] as String,
        name: m['name'] as String,
        sku: m['sku'] as String?,
        category: m['category'] as String,
        costPrice: (m['costPrice'] as num).toDouble(),
        sellPrice: (m['sellPrice'] as num).toDouble(),
        wholesalePrice: (m['wholesalePrice'] as num?)?.toDouble(),
        currentStock: (m['currentStock'] as num).toDouble(),
        minStockLevel: (m['minStockLevel'] as num).toDouble(),
        unit: m['unit'] as String? ?? 'pcs',
        isTaxable: m['isTaxable'] as bool? ?? true,
        taxRate: (m['taxRate'] as num?)?.toDouble() ?? 0.18,
        isArchived: m['isArchived'] as bool? ?? false,
        isSynced: m['isSynced'] as bool? ?? false,
        branchId: m['branchId'] as String?,
        updatedAt: m['updatedAt'] as int,
      );

  LocalProductData copyWith({
    String? name,
    String? sku,
    String? category,
    double? costPrice,
    double? sellPrice,
    double? wholesalePrice,
    double? currentStock,
    double? minStockLevel,
    String? unit,
    bool? isTaxable,
    double? taxRate,
    bool? isArchived,
    bool? isSynced,
    String? branchId,
    int? updatedAt,
  }) =>
      LocalProductData(
        id: id,
        serverId: serverId,
        businessId: businessId,
        name: name ?? this.name,
        sku: sku ?? this.sku,
        category: category ?? this.category,
        costPrice: costPrice ?? this.costPrice,
        sellPrice: sellPrice ?? this.sellPrice,
        wholesalePrice: wholesalePrice ?? this.wholesalePrice,
        currentStock: currentStock ?? this.currentStock,
        minStockLevel: minStockLevel ?? this.minStockLevel,
        unit: unit ?? this.unit,
        isTaxable: isTaxable ?? this.isTaxable,
        taxRate: taxRate ?? this.taxRate,
        isArchived: isArchived ?? this.isArchived,
        isSynced: isSynced ?? this.isSynced,
        branchId: branchId ?? this.branchId,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ---------------------------------------------------------------------------
// SALE (with Cashier Name & Branch support)
// ---------------------------------------------------------------------------
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
  final String? cashierName;
  final String? branchId;
  final int localTimestamp;
  final bool isSynced;
  final bool isVoided;

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
    this.cashierName,
    this.branchId,
    required this.localTimestamp,
    this.isSynced = false,
    this.isVoided = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'serverId': serverId,
        'businessId': businessId,
        'saleNumber': saleNumber,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'itemsJson': itemsJson,
        'subtotalAmount': subtotalAmount,
        'taxAmount': taxAmount,
        'discountAmount': discountAmount,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'dueAmount': dueAmount,
        'paymentStatus': paymentStatus,
        'paymentMethod': paymentMethod,
        'momoReference': momoReference,
        'isCredit': isCredit,
        'dueDate': dueDate,
        'efrisFiscalCode': efrisFiscalCode,
        'efrisQrCodeData': efrisQrCodeData,
        'deviceId': deviceId,
        'cashierName': cashierName,
        'branchId': branchId,
        'localTimestamp': localTimestamp,
        'isSynced': isSynced,
        'isVoided': isVoided,
      };

  factory LocalSaleData.fromJson(Map<String, dynamic> m) => LocalSaleData(
        id: m['id'] as String,
        serverId: m['serverId'] as String?,
        businessId: m['businessId'] as String,
        saleNumber: m['saleNumber'] as String,
        customerId: m['customerId'] as String?,
        customerName: m['customerName'] as String?,
        customerPhone: m['customerPhone'] as String?,
        itemsJson: m['itemsJson'] as String,
        subtotalAmount: (m['subtotalAmount'] as num).toDouble(),
        taxAmount: (m['taxAmount'] as num).toDouble(),
        discountAmount: (m['discountAmount'] as num).toDouble(),
        totalAmount: (m['totalAmount'] as num).toDouble(),
        paidAmount: (m['paidAmount'] as num).toDouble(),
        dueAmount: (m['dueAmount'] as num).toDouble(),
        paymentStatus: m['paymentStatus'] as String,
        paymentMethod: m['paymentMethod'] as String,
        momoReference: m['momoReference'] as String?,
        isCredit: m['isCredit'] as bool? ?? false,
        dueDate: m['dueDate'] as int?,
        efrisFiscalCode: m['efrisFiscalCode'] as String?,
        efrisQrCodeData: m['efrisQrCodeData'] as String?,
        deviceId: m['deviceId'] as String,
        cashierName: m['cashierName'] as String?,
        branchId: m['branchId'] as String?,
        localTimestamp: m['localTimestamp'] as int,
        isSynced: m['isSynced'] as bool? ?? false,
        isVoided: m['isVoided'] as bool? ?? false,
      );

  LocalSaleData copyWith({
    bool? isVoided,
    bool? isSynced,
    String? serverId,
    String? cashierName,
    String? branchId,
  }) =>
      LocalSaleData(
        id: id,
        serverId: serverId ?? this.serverId,
        businessId: businessId,
        saleNumber: saleNumber,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        itemsJson: itemsJson,
        subtotalAmount: subtotalAmount,
        taxAmount: taxAmount,
        discountAmount: discountAmount,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        dueAmount: dueAmount,
        paymentStatus: paymentStatus,
        paymentMethod: paymentMethod,
        momoReference: momoReference,
        isCredit: isCredit,
        dueDate: dueDate,
        efrisFiscalCode: efrisFiscalCode,
        efrisQrCodeData: efrisQrCodeData,
        deviceId: deviceId,
        cashierName: cashierName ?? this.cashierName,
        branchId: branchId ?? this.branchId,
        localTimestamp: localTimestamp,
        isSynced: isSynced ?? this.isSynced,
        isVoided: isVoided ?? this.isVoided,
      );
}

// ---------------------------------------------------------------------------
// TRANSACTION
// ---------------------------------------------------------------------------
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'serverId': serverId,
        'businessId': businessId,
        'type': type,
        'category': category,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'reference': reference,
        'notes': notes,
        'isRecurring': isRecurring,
        'date': date,
        'deviceId': deviceId,
        'isSynced': isSynced,
      };

  factory LocalTransactionData.fromJson(Map<String, dynamic> m) =>
      LocalTransactionData(
        id: m['id'] as String,
        serverId: m['serverId'] as String?,
        businessId: m['businessId'] as String,
        type: m['type'] as String,
        category: m['category'] as String,
        amount: (m['amount'] as num).toDouble(),
        paymentMethod: m['paymentMethod'] as String,
        reference: m['reference'] as String?,
        notes: m['notes'] as String?,
        isRecurring: m['isRecurring'] as bool? ?? false,
        date: m['date'] as int,
        deviceId: m['deviceId'] as String,
        isSynced: m['isSynced'] as bool? ?? false,
      );
}

// ---------------------------------------------------------------------------
// EXPENSE
// ---------------------------------------------------------------------------
class LocalExpenseData {
  final String id;
  final String businessId;
  final String categoryName;
  final String icon;
  final double amount;
  final String paymentMethod;
  final String notes;
  final int date;

  LocalExpenseData({
    required this.id,
    required this.businessId,
    required this.categoryName,
    required this.icon,
    required this.amount,
    required this.paymentMethod,
    required this.notes,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'categoryName': categoryName,
        'icon': icon,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'notes': notes,
        'date': date,
      };

  factory LocalExpenseData.fromJson(Map<String, dynamic> m) => LocalExpenseData(
        id: m['id'] as String,
        businessId: m['businessId'] as String,
        categoryName: m['categoryName'] as String,
        icon: m['icon'] as String? ?? '💸',
        amount: (m['amount'] as num).toDouble(),
        paymentMethod: m['paymentMethod'] as String,
        notes: m['notes'] as String? ?? '',
        date: m['date'] as int,
      );
}

// ---------------------------------------------------------------------------
// CUSTOMER (with Tier & Favorite Colors)
// ---------------------------------------------------------------------------
class LocalCustomerData {
  final String id;
  final String? serverId;
  final String businessId;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final double creditLimit;
  final double currentDebt;
  final int tagColor;
  final bool isFavorite;
  final String tier; // 'regular', 'wholesale', 'vip'
  final String? notes;
  final int createdAt;
  final int updatedAt;

  LocalCustomerData({
    required this.id,
    this.serverId,
    required this.businessId,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.creditLimit = 300000,
    this.currentDebt = 0,
    this.tagColor = 0xFF0B4F37,
    this.isFavorite = false,
    this.tier = 'regular',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'serverId': serverId,
        'businessId': businessId,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'creditLimit': creditLimit,
        'currentDebt': currentDebt,
        'tagColor': tagColor,
        'isFavorite': isFavorite,
        'tier': tier,
        'notes': notes,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory LocalCustomerData.fromJson(Map<String, dynamic> m) => LocalCustomerData(
        id: m['id'] as String,
        serverId: m['serverId'] as String?,
        businessId: m['businessId'] as String,
        name: m['name'] as String,
        phone: m['phone'] as String,
        email: m['email'] as String?,
        address: m['address'] as String?,
        creditLimit: (m['creditLimit'] as num?)?.toDouble() ?? 300000,
        currentDebt: (m['currentDebt'] as num?)?.toDouble() ?? 0,
        tagColor: (m['tagColor'] as num?)?.toInt() ?? 0xFF0B4F37,
        isFavorite: m['isFavorite'] as bool? ?? false,
        tier: m['tier'] as String? ?? 'regular',
        notes: m['notes'] as String?,
        createdAt: (m['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt: (m['updatedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      );

  LocalCustomerData copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    double? creditLimit,
    double? currentDebt,
    int? tagColor,
    bool? isFavorite,
    String? tier,
    String? notes,
    int? updatedAt,
  }) =>
      LocalCustomerData(
        id: id,
        serverId: serverId,
        businessId: businessId,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
        creditLimit: creditLimit ?? this.creditLimit,
        currentDebt: currentDebt ?? this.currentDebt,
        tagColor: tagColor ?? this.tagColor,
        isFavorite: isFavorite ?? this.isFavorite,
        tier: tier ?? this.tier,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ---------------------------------------------------------------------------
// SMS MESSAGE
// ---------------------------------------------------------------------------
class LocalSmsData {
  final String id;
  final String businessId;
  final String? customerId;
  final String phone;
  final String message;
  final String type;
  final String status;
  final int createdAt;

  LocalSmsData({
    required this.id,
    required this.businessId,
    this.customerId,
    required this.phone,
    required this.message,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'customerId': customerId,
        'phone': phone,
        'message': message,
        'type': type,
        'status': status,
        'createdAt': createdAt,
      };

  factory LocalSmsData.fromJson(Map<String, dynamic> m) => LocalSmsData(
        id: m['id'] as String,
        businessId: m['businessId'] as String,
        customerId: m['customerId'] as String?,
        phone: m['phone'] as String,
        message: m['message'] as String,
        type: m['type'] as String? ?? 'custom',
        status: m['status'] as String? ?? 'sent',
        createdAt: (m['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      );
}

// ---------------------------------------------------------------------------
// DEBTOR
// ---------------------------------------------------------------------------
class LocalDebtorData {
  final String id;
  final String businessId;
  final String name;
  final String phone;
  final double balanceOwed;
  final double creditLimit;
  final int lastSaleDate;
  final List<Map<String, dynamic>> paymentHistory;

  LocalDebtorData({
    required this.id,
    required this.businessId,
    required this.name,
    required this.phone,
    required this.balanceOwed,
    required this.creditLimit,
    required this.lastSaleDate,
    this.paymentHistory = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'name': name,
        'phone': phone,
        'balanceOwed': balanceOwed,
        'creditLimit': creditLimit,
        'lastSaleDate': lastSaleDate,
        'paymentHistory': paymentHistory,
      };

  factory LocalDebtorData.fromJson(Map<String, dynamic> m) => LocalDebtorData(
        id: m['id'] as String,
        businessId: m['businessId'] as String,
        name: m['name'] as String,
        phone: m['phone'] as String,
        balanceOwed: (m['balanceOwed'] as num).toDouble(),
        creditLimit: (m['creditLimit'] as num).toDouble(),
        lastSaleDate: m['lastSaleDate'] as int,
        paymentHistory: (m['paymentHistory'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
      );

  LocalDebtorData copyWith({
    double? balanceOwed,
    double? creditLimit,
    int? lastSaleDate,
    List<Map<String, dynamic>>? paymentHistory,
  }) =>
      LocalDebtorData(
        id: id,
        businessId: businessId,
        name: name,
        phone: phone,
        balanceOwed: balanceOwed ?? this.balanceOwed,
        creditLimit: creditLimit ?? this.creditLimit,
        lastSaleDate: lastSaleDate ?? this.lastSaleDate,
        paymentHistory: paymentHistory ?? this.paymentHistory,
      );
}

// ---------------------------------------------------------------------------
// RESTOCK
// ---------------------------------------------------------------------------
class LocalRestockData {
  final String id;
  final String productId;
  final String businessId;
  final double qtyReceived;
  final double costPerUnit;
  final String? supplierName;
  final String? notes;
  final int date;

  LocalRestockData({
    required this.id,
    required this.productId,
    required this.businessId,
    required this.qtyReceived,
    required this.costPerUnit,
    this.supplierName,
    this.notes,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'businessId': businessId,
        'qtyReceived': qtyReceived,
        'costPerUnit': costPerUnit,
        'supplierName': supplierName,
        'notes': notes,
        'date': date,
      };

  factory LocalRestockData.fromJson(Map<String, dynamic> m) => LocalRestockData(
        id: m['id'] as String,
        productId: m['productId'] as String,
        businessId: m['businessId'] as String,
        qtyReceived: (m['qtyReceived'] as num).toDouble(),
        costPerUnit: (m['costPerUnit'] as num).toDouble(),
        supplierName: m['supplierName'] as String?,
        notes: m['notes'] as String?,
        date: m['date'] as int,
      );
}

// ---------------------------------------------------------------------------
// RAW MATERIAL (for Production Module)
// ---------------------------------------------------------------------------
class LocalRawMaterialData {
  final String id;
  final String businessId;
  final String name;
  final String unit; // 'kg', 'ltr', 'bags', 'g', 'pcs'
  final double currentStock;
  final double minStockLevel;
  final double unitCost;
  final int updatedAt;

  LocalRawMaterialData({
    required this.id,
    required this.businessId,
    required this.name,
    this.unit = 'kg',
    required this.currentStock,
    required this.minStockLevel,
    required this.unitCost,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'name': name,
        'unit': unit,
        'currentStock': currentStock,
        'minStockLevel': minStockLevel,
        'unitCost': unitCost,
        'updatedAt': updatedAt,
      };

  factory LocalRawMaterialData.fromJson(Map<String, dynamic> m) =>
      LocalRawMaterialData(
        id: m['id'] as String,
        businessId: m['businessId'] as String,
        name: m['name'] as String,
        unit: m['unit'] as String? ?? 'kg',
        currentStock: (m['currentStock'] as num).toDouble(),
        minStockLevel: (m['minStockLevel'] as num).toDouble(),
        unitCost: (m['unitCost'] as num).toDouble(),
        updatedAt: m['updatedAt'] as int,
      );

  LocalRawMaterialData copyWith({
    String? name,
    String? unit,
    double? currentStock,
    double? minStockLevel,
    double? unitCost,
    int? updatedAt,
  }) =>
      LocalRawMaterialData(
        id: id,
        businessId: businessId,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        currentStock: currentStock ?? this.currentStock,
        minStockLevel: minStockLevel ?? this.minStockLevel,
        unitCost: unitCost ?? this.unitCost,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ---------------------------------------------------------------------------
// PRODUCTION RECIPE / FORMULA (for Production Module)
// ---------------------------------------------------------------------------
class LocalRecipeData {
  final String id;
  final String businessId;
  final String name;
  final String outputProductId;
  final String outputProductName;
  final double outputQuantity;
  final String ingredientsJson; // List of {rawMaterialId, rawMaterialName, quantity, unit}
  final double laborCost;
  final String? notes;
  final int createdAt;

  LocalRecipeData({
    required this.id,
    required this.businessId,
    required this.name,
    required this.outputProductId,
    required this.outputProductName,
    required this.outputQuantity,
    required this.ingredientsJson,
    this.laborCost = 0,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'name': name,
        'outputProductId': outputProductId,
        'outputProductName': outputProductName,
        'outputQuantity': outputQuantity,
        'ingredientsJson': ingredientsJson,
        'laborCost': laborCost,
        'notes': notes,
        'createdAt': createdAt,
      };

  factory LocalRecipeData.fromJson(Map<String, dynamic> m) => LocalRecipeData(
        id: m['id'] as String,
        businessId: m['businessId'] as String,
        name: m['name'] as String,
        outputProductId: m['outputProductId'] as String,
        outputProductName: m['outputProductName'] as String? ?? '',
        outputQuantity: (m['outputQuantity'] as num).toDouble(),
        ingredientsJson: m['ingredientsJson'] as String,
        laborCost: (m['laborCost'] as num?)?.toDouble() ?? 0,
        notes: m['notes'] as String?,
        createdAt: (m['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      );
}

// ---------------------------------------------------------------------------
// PRODUCTION BATCH (for Production Module Log)
// ---------------------------------------------------------------------------
class LocalProductionBatchData {
  final String id;
  final String businessId;
  final String recipeId;
  final String recipeName;
  final String outputProductId;
  final String outputProductName;
  final double quantityProduced;
  final double totalCost;
  final double unitCost;
  final int batchDate;
  final String? notes;

  LocalProductionBatchData({
    required this.id,
    required this.businessId,
    required this.recipeId,
    required this.recipeName,
    required this.outputProductId,
    required this.outputProductName,
    required this.quantityProduced,
    required this.totalCost,
    required this.unitCost,
    required this.batchDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'recipeId': recipeId,
        'recipeName': recipeName,
        'outputProductId': outputProductId,
        'outputProductName': outputProductName,
        'quantityProduced': quantityProduced,
        'totalCost': totalCost,
        'unitCost': unitCost,
        'batchDate': batchDate,
        'notes': notes,
      };

  factory LocalProductionBatchData.fromJson(Map<String, dynamic> m) =>
      LocalProductionBatchData(
        id: m['id'] as String,
        businessId: m['businessId'] as String,
        recipeId: m['recipeId'] as String,
        recipeName: m['recipeName'] as String,
        outputProductId: m['outputProductId'] as String,
        outputProductName: m['outputProductName'] as String,
        quantityProduced: (m['quantityProduced'] as num).toDouble(),
        totalCost: (m['totalCost'] as num).toDouble(),
        unitCost: (m['unitCost'] as num).toDouble(),
        batchDate: m['batchDate'] as int,
        notes: m['notes'] as String?,
      );
}

// ---------------------------------------------------------------------------
// BRANCH (for Multi-Branch Support)
// ---------------------------------------------------------------------------
class LocalBranchData {
  final String id;
  final String businessId;
  final String name;
  final String location;
  final String managerName;
  final String phone;
  final bool isHeadquarters;
  final int createdAt;

  LocalBranchData({
    required this.id,
    required this.businessId,
    required this.name,
    required this.location,
    required this.managerName,
    required this.phone,
    this.isHeadquarters = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'name': name,
        'location': location,
        'managerName': managerName,
        'phone': phone,
        'isHeadquarters': isHeadquarters,
        'createdAt': createdAt,
      };

  factory LocalBranchData.fromJson(Map<String, dynamic> m) => LocalBranchData(
        id: m['id'] as String,
        businessId: m['businessId'] as String,
        name: m['name'] as String,
        location: m['location'] as String,
        managerName: m['managerName'] as String,
        phone: m['phone'] as String,
        isHeadquarters: m['isHeadquarters'] as bool? ?? false,
        createdAt: (m['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      );
}

// ---------------------------------------------------------------------------
// STOCK TRANSFER (Inter-Branch Transfer)
// ---------------------------------------------------------------------------
class LocalStockTransferData {
  final String id;
  final String businessId;
  final String fromBranchId;
  final String fromBranchName;
  final String toBranchId;
  final String toBranchName;
  final String productId;
  final String productName;
  final double quantity;
  final String status; // 'pending', 'completed', 'cancelled'
  final String? notes;
  final int transferDate;

  LocalStockTransferData({
    required this.id,
    required this.businessId,
    required this.fromBranchId,
    required this.fromBranchName,
    required this.toBranchId,
    required this.toBranchName,
    required this.productId,
    required this.productName,
    required this.quantity,
    this.status = 'completed',
    this.notes,
    required this.transferDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'fromBranchId': fromBranchId,
        'fromBranchName': fromBranchName,
        'toBranchId': toBranchId,
        'toBranchName': toBranchName,
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'status': status,
        'notes': notes,
        'transferDate': transferDate,
      };

  factory LocalStockTransferData.fromJson(Map<String, dynamic> m) =>
      LocalStockTransferData(
        id: m['id'] as String,
        businessId: m['businessId'] as String,
        fromBranchId: m['fromBranchId'] as String,
        fromBranchName: m['fromBranchName'] as String,
        toBranchId: m['toBranchId'] as String,
        toBranchName: m['toBranchName'] as String,
        productId: m['productId'] as String,
        productName: m['productName'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        status: m['status'] as String? ?? 'completed',
        notes: m['notes'] as String?,
        transferDate: m['transferDate'] as int,
      );
}

// ---------------------------------------------------------------------------
// MOBILE MONEY TRANSACTION
// ---------------------------------------------------------------------------
class LocalMobileMoneyTxData {
  final String id;
  final String businessId;
  final String provider; // 'mtn', 'airtel'
  final String phone;
  final double amount;
  final String reference;
  final String status; // 'completed', 'pending', 'failed'
  final String type; // 'collection', 'payout'
  final int createdAt;

  LocalMobileMoneyTxData({
    required this.id,
    required this.businessId,
    required this.provider,
    required this.phone,
    required this.amount,
    required this.reference,
    required this.status,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'provider': provider,
        'phone': phone,
        'amount': amount,
        'reference': reference,
        'status': status,
        'type': type,
        'createdAt': createdAt,
      };

  factory LocalMobileMoneyTxData.fromJson(Map<String, dynamic> m) =>
      LocalMobileMoneyTxData(
        id: m['id'] as String,
        businessId: m['businessId'] as String,
        provider: m['provider'] as String,
        phone: m['phone'] as String,
        amount: (m['amount'] as num).toDouble(),
        reference: m['reference'] as String,
        status: m['status'] as String? ?? 'completed',
        type: m['type'] as String? ?? 'collection',
        createdAt: (m['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      );
}

// ---------------------------------------------------------------------------
// NOTIFICATION
// ---------------------------------------------------------------------------
class LocalNotificationData {
  final String id;
  final String businessId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final int createdAt;

  LocalNotificationData({
    required this.id,
    required this.businessId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'title': title,
        'body': body,
        'type': type,
        'isRead': isRead,
        'createdAt': createdAt,
      };

  factory LocalNotificationData.fromJson(Map<String, dynamic> m) =>
      LocalNotificationData(
        id: m['id'] as String,
        businessId: m['businessId'] as String,
        title: m['title'] as String,
        body: m['body'] as String,
        type: m['type'] as String? ?? 'info',
        isRead: m['isRead'] as bool? ?? false,
        createdAt: (m['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      );
}

// ---------------------------------------------------------------------------
// APP DATABASE
// ---------------------------------------------------------------------------
class AppDatabase {
  static const _kProducts = 'duka_products_v2';
  static const _kSales = 'duka_sales_v2';
  static const _kTransactions = 'duka_txn_v2';
  static const _kExpenses = 'duka_expenses_v2';
  static const _kDebtors = 'duka_debtors_v2';
  static const _kRestocks = 'duka_restocks_v2';
  static const _kCustomers = 'duka_customers_v2';
  static const _kSms = 'duka_sms_v2';
  static const _kRawMaterials = 'duka_raw_materials_v2';
  static const _kRecipes = 'duka_recipes_v2';
  static const _kBatches = 'duka_batches_v2';
  static const _kBranches = 'duka_branches_v2';
  static const _kTransfers = 'duka_transfers_v2';
  static const _kMomo = 'duka_momo_v2';
  static const _kNotifications = 'duka_notifs_v2';
  static const _kQueue = 'duka_queue_v2';

  SharedPreferences? _prefs;
  bool _initialized = false;

  final Map<String, LocalProductData> _products = {};
  final Map<String, LocalSaleData> _sales = {};
  final Map<String, LocalTransactionData> _transactions = {};
  final Map<String, LocalExpenseData> _expenses = {};
  final Map<String, LocalDebtorData> _debtors = {};
  final Map<String, LocalRestockData> _restocks = {};
  final Map<String, LocalCustomerData> _customers = {};
  final Map<String, LocalSmsData> _sms = {};
  final Map<String, LocalRawMaterialData> _rawMaterials = {};
  final Map<String, LocalRecipeData> _recipes = {};
  final Map<String, LocalProductionBatchData> _batches = {};
  final Map<String, LocalBranchData> _branches = {};
  final Map<String, LocalStockTransferData> _transfers = {};
  final Map<String, LocalMobileMoneyTxData> _momo = {};
  final Map<String, LocalNotificationData> _notifications = {};
  final List<SyncQueueItem> _queue = [];

  final _changeController = StreamController<void>.broadcast();
  Stream<void> get onChange => _changeController.stream;

  AppDatabase();

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _loadAll();
    if (_products.isEmpty) _seedDefaultProducts();
    if (_debtors.isEmpty) _seedDefaultDebtors();
    if (_customers.isEmpty) _seedDefaultCustomers();
    if (_rawMaterials.isEmpty) _seedDefaultRawMaterials();
    if (_recipes.isEmpty) _seedDefaultRecipes();
    if (_branches.isEmpty) _seedDefaultBranches();
    _initialized = true;
  }

  void _loadAll() {
    _loadMap<LocalProductData>(_kProducts, _products, LocalProductData.fromJson);
    _loadMap<LocalSaleData>(_kSales, _sales, LocalSaleData.fromJson);
    _loadMap<LocalTransactionData>(_kTransactions, _transactions, LocalTransactionData.fromJson);
    _loadMap<LocalExpenseData>(_kExpenses, _expenses, LocalExpenseData.fromJson);
    _loadMap<LocalDebtorData>(_kDebtors, _debtors, LocalDebtorData.fromJson);
    _loadMap<LocalRestockData>(_kRestocks, _restocks, LocalRestockData.fromJson);
    _loadMap<LocalCustomerData>(_kCustomers, _customers, LocalCustomerData.fromJson);
    _loadMap<LocalSmsData>(_kSms, _sms, LocalSmsData.fromJson);
    _loadMap<LocalRawMaterialData>(_kRawMaterials, _rawMaterials, LocalRawMaterialData.fromJson);
    _loadMap<LocalRecipeData>(_kRecipes, _recipes, LocalRecipeData.fromJson);
    _loadMap<LocalProductionBatchData>(_kBatches, _batches, LocalProductionBatchData.fromJson);
    _loadMap<LocalBranchData>(_kBranches, _branches, LocalBranchData.fromJson);
    _loadMap<LocalStockTransferData>(_kTransfers, _transfers, LocalStockTransferData.fromJson);
    _loadMap<LocalMobileMoneyTxData>(_kMomo, _momo, LocalMobileMoneyTxData.fromJson);
    _loadMap<LocalNotificationData>(_kNotifications, _notifications, LocalNotificationData.fromJson);

    final raw = _prefs?.getString(_kQueue);
    if (raw != null) {
      try {
        for (final item in jsonDecode(raw) as List<dynamic>) {
          _queue.add(SyncQueueItem.fromJson(Map<String, dynamic>.from(item as Map)));
        }
      } catch (_) {}
    }
  }

  void _loadMap<T>(String key, Map<String, T> target, T Function(Map<String, dynamic>) fromJson) {
    final raw = _prefs?.getString(key);
    if (raw == null) return;
    try {
      for (final item in jsonDecode(raw) as List<dynamic>) {
        final map = Map<String, dynamic>.from(item as Map);
        target[map['id'] as String] = fromJson(map);
      }
    } catch (_) {}
  }

  Future<void> _persist<T>(String key, Map<String, T> map, Map<String, dynamic> Function(T) toJson) async {
    await _prefs?.setString(key, jsonEncode(map.values.map(toJson).toList()));
  }

  void _notify() => _changeController.add(null);

  void _seedDefaultProducts() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final seed = [
      LocalProductData(id: 'p1', businessId: 'biz_default', name: 'NPK 17:17:17 Fertilizer 50kg', category: 'Agro', costPrice: 150000, sellPrice: 185000, wholesalePrice: 172000, currentStock: 24, minStockLevel: 10, unit: 'bag', updatedAt: now),
      LocalProductData(id: 'p2', businessId: 'biz_default', name: 'DAP Fertilizer 50kg', category: 'Agro', costPrice: 170000, sellPrice: 210000, wholesalePrice: 195000, currentStock: 18, minStockLevel: 10, unit: 'bag', updatedAt: now),
      LocalProductData(id: 'p3', businessId: 'biz_default', name: 'Longe 5 Maize Seeds 2kg', category: 'Seeds', costPrice: 12000, sellPrice: 16000, wholesalePrice: 14500, currentStock: 4, minStockLevel: 15, unit: 'pkt', updatedAt: now),
      LocalProductData(id: 'p4', businessId: 'biz_default', name: 'Bazooka Maize Seeds 2kg', category: 'Seeds', costPrice: 14000, sellPrice: 18500, wholesalePrice: 16500, currentStock: 30, minStockLevel: 10, unit: 'pkt', updatedAt: now),
      LocalProductData(id: 'p5', businessId: 'biz_default', name: 'Roundup Weedkiller 1L', category: 'Chemicals', costPrice: 22000, sellPrice: 28000, wholesalePrice: 25000, currentStock: 3, minStockLevel: 10, unit: 'bottle', updatedAt: now),
      LocalProductData(id: 'p6', businessId: 'biz_default', name: 'Dudu Acelamectin 500ml', category: 'Chemicals', costPrice: 18000, sellPrice: 24000, wholesalePrice: 21500, currentStock: 15, minStockLevel: 5, unit: 'bottle', updatedAt: now),
      LocalProductData(id: 'p7', businessId: 'biz_default', name: 'Tororo Cement 32.5R 50kg', category: 'Hardware', costPrice: 32000, sellPrice: 36000, wholesalePrice: 34000, currentStock: 80, minStockLevel: 20, unit: 'bag', updatedAt: now),
      LocalProductData(id: 'p8', businessId: 'biz_default', name: 'Iron Sheets 28 Gauge 3m', category: 'Hardware', costPrice: 42000, sellPrice: 48500, wholesalePrice: 45000, currentStock: 60, minStockLevel: 15, unit: 'pc', updatedAt: now),
      LocalProductData(id: 'p9', businessId: 'biz_default', name: 'Water Pump Knapsack 16L', category: 'Equipment', costPrice: 65000, sellPrice: 85000, wholesalePrice: 75000, currentStock: 8, minStockLevel: 5, unit: 'pc', updatedAt: now),
    ];
    for (final p in seed) {
      _products[p.id] = p;
    }
    _persist(_kProducts, _products, (p) => p.toJson());
  }

  void _seedDefaultDebtors() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final seed = [
      LocalDebtorData(id: 'd1', businessId: 'biz_default', name: 'Mugisha Patrick (Farm)', phone: '0772889900', balanceOwed: 250000, creditLimit: 500000, lastSaleDate: now - 518400000),
      LocalDebtorData(id: 'd2', businessId: 'biz_default', name: 'Mama Sarah General Store', phone: '0754112233', balanceOwed: 180000, creditLimit: 300000, lastSaleDate: now - 345600000),
      LocalDebtorData(id: 'd3', businessId: 'biz_default', name: 'Kato Denis (Builder)', phone: '0701998877', balanceOwed: 140000, creditLimit: 200000, lastSaleDate: now - 950400000),
      LocalDebtorData(id: 'd4', businessId: 'biz_default', name: 'Namubiru Grace', phone: '0788334455', balanceOwed: 70000, creditLimit: 100000, lastSaleDate: now - 172800000),
    ];
    for (final d in seed) {
      _debtors[d.id] = d;
    }
    _persist(_kDebtors, _debtors, (d) => d.toJson());
  }

  void _seedDefaultCustomers() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final seed = [
      LocalCustomerData(
        id: 'c1',
        businessId: 'biz_default',
        name: 'Mugisha Patrick (Farm)',
        phone: '256772889900',
        address: 'Gayaza Road, Block 4',
        creditLimit: 500000,
        currentDebt: 250000,
        tagColor: 0xFFF59E0B, // VIP Gold
        isFavorite: true,
        tier: 'wholesale',
        notes: 'Top wholesale farmer buyer',
        createdAt: now - 518400000,
        updatedAt: now,
      ),
      LocalCustomerData(
        id: 'c2',
        businessId: 'biz_default',
        name: 'Mama Sarah General Store',
        phone: '256754112233',
        address: 'Kalerwe Market, Stall 12',
        creditLimit: 300000,
        currentDebt: 180000,
        tagColor: 0xFF10B981, // Loyal Emerald
        isFavorite: true,
        tier: 'wholesale',
        notes: 'Regular retail re-stocker',
        createdAt: now - 345600000,
        updatedAt: now,
      ),
      LocalCustomerData(
        id: 'c3',
        businessId: 'biz_default',
        name: 'Kato Denis (Builder)',
        phone: '256701998877',
        address: 'Bwaise Hardware Zone',
        creditLimit: 200000,
        currentDebt: 140000,
        tagColor: 0xFF7C3AED, // Royal Purple
        isFavorite: false,
        tier: 'regular',
        notes: 'Contractor client',
        createdAt: now - 950400000,
        updatedAt: now,
      ),
      LocalCustomerData(
        id: 'c4',
        businessId: 'biz_default',
        name: 'Namubiru Grace',
        phone: '256788334455',
        address: 'Ntinda Complex',
        creditLimit: 100000,
        currentDebt: 70000,
        tagColor: 0xFF0284C7, // Ocean Blue
        isFavorite: false,
        tier: 'vip',
        notes: 'Prompt payer',
        createdAt: now - 172800000,
        updatedAt: now,
      ),
    ];
    for (final c in seed) {
      _customers[c.id] = c;
    }
    _persist(_kCustomers, _customers, (c) => c.toJson());
  }

  void _seedDefaultRawMaterials() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final seed = [
      LocalRawMaterialData(id: 'rm1', businessId: 'biz_default', name: 'Raw Maize Grain Grade A', unit: 'kg', currentStock: 850, minStockLevel: 200, unitCost: 1100, updatedAt: now),
      LocalRawMaterialData(id: 'rm2', businessId: 'biz_default', name: 'Nitrogen Premix Powder', unit: 'kg', currentStock: 120, minStockLevel: 30, unitCost: 4500, updatedAt: now),
      LocalRawMaterialData(id: 'rm3', businessId: 'biz_default', name: 'Packaging Bags 50kg Heavy', unit: 'pcs', currentStock: 450, minStockLevel: 100, unitCost: 1200, updatedAt: now),
      LocalRawMaterialData(id: 'rm4', businessId: 'biz_default', name: 'Chemical Surfactant Liquid', unit: 'ltr', currentStock: 45, minStockLevel: 15, unitCost: 8500, updatedAt: now),
      LocalRawMaterialData(id: 'rm5', businessId: 'biz_default', name: 'Plastic Bottles 1L With Caps', unit: 'pcs', currentStock: 300, minStockLevel: 80, unitCost: 650, updatedAt: now),
    ];
    for (final rm in seed) {
      _rawMaterials[rm.id] = rm;
    }
    _persist(_kRawMaterials, _rawMaterials, (rm) => rm.toJson());
  }

  void _seedDefaultRecipes() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final seed = [
      LocalRecipeData(
        id: 'rec1',
        businessId: 'biz_default',
        name: 'Custom NPK 17:17:17 Blend 50kg',
        outputProductId: 'p1',
        outputProductName: 'NPK 17:17:17 Fertilizer 50kg',
        outputQuantity: 1,
        ingredientsJson: jsonEncode([
          {'rawMaterialId': 'rm2', 'rawMaterialName': 'Nitrogen Premix Powder', 'quantity': 15.0, 'unit': 'kg'},
          {'rawMaterialId': 'rm3', 'rawMaterialName': 'Packaging Bags 50kg Heavy', 'quantity': 1.0, 'unit': 'pcs'},
        ]),
        laborCost: 15000,
        notes: 'Blend in machine for 20 mins before sealing',
        createdAt: now,
      ),
      LocalRecipeData(
        id: 'rec2',
        businessId: 'biz_default',
        name: 'Weedkiller 1L Re-bottling',
        outputProductId: 'p5',
        outputProductName: 'Roundup Weedkiller 1L',
        outputQuantity: 1,
        ingredientsJson: jsonEncode([
          {'rawMaterialId': 'rm4', 'rawMaterialName': 'Chemical Surfactant Liquid', 'quantity': 1.0, 'unit': 'ltr'},
          {'rawMaterialId': 'rm5', 'rawMaterialName': 'Plastic Bottles 1L With Caps', 'quantity': 1.0, 'unit': 'pcs'},
        ]),
        laborCost: 2000,
        notes: 'Wear protective gloves during bottling',
        createdAt: now,
      ),
    ];
    for (final r in seed) {
      _recipes[r.id] = r;
    }
    _persist(_kRecipes, _recipes, (r) => r.toJson());
  }

  void _seedDefaultBranches() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final seed = [
      LocalBranchData(
        id: 'br_main',
        businessId: 'biz_default',
        name: 'Kampala Main Branch',
        location: 'Plot 14 Luwum Street, Kampala',
        managerName: 'Beinomugisha Innocent',
        phone: '256772123456',
        isHeadquarters: true,
        createdAt: now,
      ),
      LocalBranchData(
        id: 'br_kalerwe',
        businessId: 'biz_default',
        name: 'Kalerwe Market Branch',
        location: 'Kalerwe Agro Hub, Block C',
        managerName: 'Patrick Mugisha',
        phone: '256754987654',
        isHeadquarters: false,
        createdAt: now,
      ),
      LocalBranchData(
        id: 'br_mbarara',
        businessId: 'biz_default',
        name: 'Mbarara Western Depot',
        location: 'High Street, Mbarara City',
        managerName: 'Kato Denis',
        phone: '256701889900',
        isHeadquarters: false,
        createdAt: now,
      ),
    ];
    for (final b in seed) {
      _branches[b.id] = b;
    }
    _persist(_kBranches, _branches, (b) => b.toJson());
  }

  // ---- Queue ----------------------------------------------------------------
  Future<void> insertQueueItem(SyncQueueItem item) async {
    _queue.removeWhere((q) => q.id == item.id);
    _queue.add(item);
    await _prefs?.setString(_kQueue, jsonEncode(_queue.map((q) => q.toJson()).toList()));
    _notify();
  }

  Future<List<SyncQueueItem>> getPendingQueue() async => List.unmodifiable(_queue);
  Future<int> getPendingQueueCount() async => _queue.length;
  Future<void> removeQueueItem(String id) async {
    _queue.removeWhere((q) => q.id == id);
    await _prefs?.setString(_kQueue, jsonEncode(_queue.map((q) => q.toJson()).toList()));
    _notify();
  }

  // ---- Products -------------------------------------------------------------
  Future<List<LocalProductData>> getProducts() async =>
      (_products.values.where((p) => !p.isArchived).toList()..sort((a, b) => a.name.compareTo(b.name)));

  Future<void> insertProduct(LocalProductData product) async {
    _products[product.id] = product;
    await _persist(_kProducts, _products, (p) => p.toJson());
    _notify();
  }

  Future<void> updateProduct(LocalProductData product) async {
    _products[product.id] = product.copyWith(isSynced: false, updatedAt: DateTime.now().millisecondsSinceEpoch);
    await _persist(_kProducts, _products, (p) => p.toJson());
    _notify();
  }

  Future<void> archiveProduct(String productId) async {
    final e = _products[productId];
    if (e != null) {
      _products[productId] = e.copyWith(isArchived: true, updatedAt: DateTime.now().millisecondsSinceEpoch);
      await _persist(_kProducts, _products, (p) => p.toJson());
      _notify();
    }
  }

  Future<void> updateProductStock(String productId, double delta) async {
    final e = _products[productId];
    if (e != null) {
      _products[productId] = e.copyWith(
        currentStock: (e.currentStock + delta).clamp(0.0, 9999999.0),
        isSynced: false,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _persist(_kProducts, _products, (p) => p.toJson());
      _notify();
    }
  }

  List<LocalProductData> getLowStockProducts() =>
      _products.values.where((p) => !p.isArchived && p.currentStock <= p.minStockLevel).toList();

  // ---- Sales ----------------------------------------------------------------
  Future<void> insertSale(LocalSaleData sale) async {
    _sales[sale.id] = sale;
    await _persist(_kSales, _sales, (s) => s.toJson());
    _notify();
  }

  Future<List<LocalSaleData>> getSales() async =>
      (_sales.values.where((s) => !s.isVoided).toList()..sort((a, b) => b.localTimestamp.compareTo(a.localTimestamp)));

  Future<List<LocalSaleData>> getAllSales() async =>
      (_sales.values.toList()..sort((a, b) => b.localTimestamp.compareTo(a.localTimestamp)));

  Future<void> voidSale(String saleId) async {
    final e = _sales[saleId];
    if (e == null) return;
    _sales[saleId] = e.copyWith(isVoided: true);
    try {
      for (final item in jsonDecode(e.itemsJson) as List<dynamic>) {
        final pid = item['productId'] as String?;
        final qty = (item['quantity'] as num?)?.toDouble() ?? 0;
        if (pid != null && qty > 0) await updateProductStock(pid, qty);
      }
    } catch (_) {}
    await _persist(_kSales, _sales, (s) => s.toJson());
    _notify();
  }

  Future<void> markSaleSynced(String id, {String? serverId}) async {
    final e = _sales[id];
    if (e != null) {
      _sales[id] = e.copyWith(isSynced: true, serverId: serverId);
      await _persist(_kSales, _sales, (s) => s.toJson());
      _notify();
    }
  }

  // ---- Transactions ---------------------------------------------------------
  Future<void> insertTransaction(LocalTransactionData tx) async {
    _transactions[tx.id] = tx;
    await _persist(_kTransactions, _transactions, (t) => t.toJson());
    _notify();
  }

  Future<void> markTransactionSynced(String id, {String? serverId}) async {
    final e = _transactions[id];
    if (e != null) {
      _transactions[id] = LocalTransactionData(
        id: e.id,
        serverId: serverId ?? e.serverId,
        businessId: e.businessId,
        type: e.type,
        category: e.category,
        amount: e.amount,
        paymentMethod: e.paymentMethod,
        reference: e.reference,
        notes: e.notes,
        isRecurring: e.isRecurring,
        date: e.date,
        deviceId: e.deviceId,
        isSynced: true,
      );
      await _persist(_kTransactions, _transactions, (t) => t.toJson());
      _notify();
    }
  }

  // ---- Expenses -------------------------------------------------------------
  Future<void> insertExpense(LocalExpenseData expense) async {
    _expenses[expense.id] = expense;
    await _persist(_kExpenses, _expenses, (e) => e.toJson());
    _notify();
  }

  Future<List<LocalExpenseData>> getExpenses() async =>
      (_expenses.values.toList()..sort((a, b) => b.date.compareTo(a.date)));

  Future<void> deleteExpense(String id) async {
    _expenses.remove(id);
    await _persist(_kExpenses, _expenses, (e) => e.toJson());
    _notify();
  }

  // ---- Debtors --------------------------------------------------------------
  Future<void> insertDebtor(LocalDebtorData debtor) async {
    _debtors[debtor.id] = debtor;
    await _persist(_kDebtors, _debtors, (d) => d.toJson());
    _notify();
  }

  Future<List<LocalDebtorData>> getDebtors() async =>
      (_debtors.values.toList()..sort((a, b) => b.balanceOwed.compareTo(a.balanceOwed)));

  Future<void> recordDebtorPayment(String debtorId, double amount, String method, String? ref) async {
    final e = _debtors[debtorId];
    if (e == null) return;
    final newBal = (e.balanceOwed - amount).clamp(0.0, double.infinity);
    final payment = {'date': DateTime.now().millisecondsSinceEpoch, 'amount': amount, 'method': method, 'ref': ref ?? ''};
    _debtors[debtorId] = e.copyWith(balanceOwed: newBal, paymentHistory: [...e.paymentHistory, payment]);
    await _persist(_kDebtors, _debtors, (d) => d.toJson());
    _notify();
  }

  // ---- Restocks -------------------------------------------------------------
  Future<void> insertRestock(LocalRestockData restock) async {
    _restocks[restock.id] = restock;
    await _persist(_kRestocks, _restocks, (r) => r.toJson());
    await updateProductStock(restock.productId, restock.qtyReceived);
    _notify();
  }

  // ---- Customers ------------------------------------------------------------
  Future<List<LocalCustomerData>> getCustomers() async =>
      (_customers.values.toList()..sort((a, b) => a.name.compareTo(b.name)));

  Future<void> insertCustomer(LocalCustomerData customer) async {
    _customers[customer.id] = customer;
    await _persist(_kCustomers, _customers, (c) => c.toJson());
    _notify();
  }

  Future<void> updateCustomer(LocalCustomerData customer) async {
    _customers[customer.id] = customer.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch);
    await _persist(_kCustomers, _customers, (c) => c.toJson());
    _notify();
  }

  Future<void> deleteCustomer(String id) async {
    _customers.remove(id);
    await _persist(_kCustomers, _customers, (c) => c.toJson());
    _notify();
  }

  // ---- SMS Messages ---------------------------------------------------------
  Future<List<LocalSmsData>> getSms() async =>
      (_sms.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Future<List<LocalSmsData>> getSmsList() async => getSms();

  Future<void> insertSms(LocalSmsData sms) async {
    _sms[sms.id] = sms;
    await _persist(_kSms, _sms, (s) => s.toJson());
    _notify();
  }

  // ---- RAW MATERIALS (Production) -------------------------------------------
  Future<List<LocalRawMaterialData>> getRawMaterials() async =>
      (_rawMaterials.values.toList()..sort((a, b) => a.name.compareTo(b.name)));

  Future<void> insertRawMaterial(LocalRawMaterialData rm) async {
    _rawMaterials[rm.id] = rm;
    await _persist(_kRawMaterials, _rawMaterials, (m) => m.toJson());
    _notify();
  }

  Future<void> updateRawMaterial(LocalRawMaterialData rm) async {
    _rawMaterials[rm.id] = rm.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch);
    await _persist(_kRawMaterials, _rawMaterials, (m) => m.toJson());
    _notify();
  }

  Future<void> updateRawMaterialStock(String id, double delta) async {
    final rm = _rawMaterials[id];
    if (rm != null) {
      _rawMaterials[id] = rm.copyWith(
        currentStock: (rm.currentStock + delta).clamp(0.0, 9999999.0),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _persist(_kRawMaterials, _rawMaterials, (m) => m.toJson());
      _notify();
    }
  }

  Future<void> deleteRawMaterial(String id) async {
    _rawMaterials.remove(id);
    await _persist(_kRawMaterials, _rawMaterials, (m) => m.toJson());
    _notify();
  }

  // ---- RECIPES (Production) -------------------------------------------------
  Future<List<LocalRecipeData>> getRecipes() async =>
      (_recipes.values.toList()..sort((a, b) => a.name.compareTo(b.name)));

  Future<void> insertRecipe(LocalRecipeData recipe) async {
    _recipes[recipe.id] = recipe;
    await _persist(_kRecipes, _recipes, (r) => r.toJson());
    _notify();
  }

  Future<void> deleteRecipe(String id) async {
    _recipes.remove(id);
    await _persist(_kRecipes, _recipes, (r) => r.toJson());
    _notify();
  }

  // ---- PRODUCTION BATCHES ---------------------------------------------------
  Future<List<LocalProductionBatchData>> getProductionBatches() async =>
      (_batches.values.toList()..sort((a, b) => b.batchDate.compareTo(a.batchDate)));

  Future<void> recordProductionBatch({
    required String recipeId,
    required double batchesCount,
    String? notes,
  }) async {
    final recipe = _recipes[recipeId];
    if (recipe == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    double rawMaterialsCost = 0.0;

    // Deduct raw materials based on formula
    try {
      final ingredients = jsonDecode(recipe.ingredientsJson) as List<dynamic>;
      for (final ing in ingredients) {
        final rmId = ing['rawMaterialId'] as String;
        final qtyPerBatch = (ing['quantity'] as num).toDouble();
        final totalQtyToDeduct = qtyPerBatch * batchesCount;
        final rm = _rawMaterials[rmId];
        if (rm != null) {
          rawMaterialsCost += (rm.unitCost * totalQtyToDeduct);
          await updateRawMaterialStock(rmId, -totalQtyToDeduct);
        }
      }
    } catch (_) {}

    final totalBatchLabor = recipe.laborCost * batchesCount;
    final totalCost = rawMaterialsCost + totalBatchLabor;
    final totalFinishedUnits = recipe.outputQuantity * batchesCount;
    final unitCost = totalFinishedUnits > 0 ? (totalCost / totalFinishedUnits) : 0.0;

    // Increase stock of finished product in main inventory!
    await updateProductStock(recipe.outputProductId, totalFinishedUnits);

    final batch = LocalProductionBatchData(
      id: 'batch_$now',
      businessId: recipe.businessId,
      recipeId: recipe.id,
      recipeName: recipe.name,
      outputProductId: recipe.outputProductId,
      outputProductName: recipe.outputProductName,
      quantityProduced: totalFinishedUnits,
      totalCost: totalCost,
      unitCost: unitCost,
      batchDate: now,
      notes: notes,
    );

    _batches[batch.id] = batch;
    await _persist(_kBatches, _batches, (b) => b.toJson());
    _notify();
  }

  // ---- BRANCHES (Multi-Branch) ----------------------------------------------
  Future<List<LocalBranchData>> getBranches() async =>
      (_branches.values.toList()..sort((a, b) => (b.isHeadquarters ? 1 : 0).compareTo(a.isHeadquarters ? 1 : 0)));

  Future<void> insertBranch(LocalBranchData branch) async {
    _branches[branch.id] = branch;
    await _persist(_kBranches, _branches, (b) => b.toJson());
    _notify();
  }

  // ---- STOCK TRANSFERS (Inter-Branch) ----------------------------------------
  Future<List<LocalStockTransferData>> getStockTransfers() async =>
      (_transfers.values.toList()..sort((a, b) => b.transferDate.compareTo(a.transferDate)));

  Future<void> executeStockTransfer({
    required String fromBranchId,
    required String fromBranchName,
    required String toBranchId,
    required String toBranchName,
    required String productId,
    required String productName,
    required double quantity,
    String? notes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final transfer = LocalStockTransferData(
      id: 'trf_$now',
      businessId: 'biz_default',
      fromBranchId: fromBranchId,
      fromBranchName: fromBranchName,
      toBranchId: toBranchId,
      toBranchName: toBranchName,
      productId: productId,
      productName: productName,
      quantity: quantity,
      status: 'completed',
      notes: notes,
      transferDate: now,
    );

    _transfers[transfer.id] = transfer;
    await _persist(_kTransfers, _transfers, (t) => t.toJson());
    _notify();
  }

  // ---- MOBILE MONEY ---------------------------------------------------------
  Future<List<LocalMobileMoneyTxData>> getMomoTransactions() async =>
      (_momo.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Future<void> insertMomoTx(LocalMobileMoneyTxData tx) async {
    _momo[tx.id] = tx;
    await _persist(_kMomo, _momo, (m) => m.toJson());
    _notify();
  }

  // ---- NOTIFICATIONS --------------------------------------------------------
  Future<List<LocalNotificationData>> getNotifications() async =>
      (_notifications.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Future<void> insertNotification(LocalNotificationData n) async {
    _notifications[n.id] = n;
    await _persist(_kNotifications, _notifications, (notif) => notif.toJson());
    _notify();
  }

  // ---- ANALYTICS & UGA-POS REPORTING HELPERS --------------------------------
  double revenueInRange(DateTime from, DateTime to, {String? branchId}) {
    final f = from.millisecondsSinceEpoch, t = to.millisecondsSinceEpoch;
    return _sales.values
        .where((s) => !s.isVoided && s.localTimestamp >= f && s.localTimestamp <= t && (branchId == null || s.branchId == branchId))
        .fold(0.0, (sum, s) => sum + s.totalAmount);
  }

  double expensesInRange(DateTime from, DateTime to) {
    final f = from.millisecondsSinceEpoch, t = to.millisecondsSinceEpoch;
    return _expenses.values
        .where((e) => e.date >= f && e.date <= t)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double taxInRange(DateTime from, DateTime to) {
    final f = from.millisecondsSinceEpoch, t = to.millisecondsSinceEpoch;
    return _sales.values
        .where((s) => !s.isVoided && s.localTimestamp >= f && s.localTimestamp <= t)
        .fold(0.0, (sum, s) => sum + s.taxAmount);
  }

  double costOfGoodsInRange(DateTime from, DateTime to) {
    final f = from.millisecondsSinceEpoch, t = to.millisecondsSinceEpoch;
    double cogs = 0;
    for (final s in _sales.values.where((s) => !s.isVoided && s.localTimestamp >= f && s.localTimestamp <= t)) {
      try {
        for (final item in jsonDecode(s.itemsJson) as List<dynamic>) {
          cogs += ((item['quantity'] as num?)?.toDouble() ?? 0) *
              ((item['costPrice'] as num?)?.toDouble() ?? 0);
        }
      } catch (_) {}
    }
    return cogs;
  }

  List<double> dailyRevenueLastDays(int days) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final day = DateTime(now.year, now.month, now.day - (days - 1 - i));
      return revenueInRange(day, day.add(const Duration(days: 1)));
    });
  }

  Map<String, double> expensesByCategory(DateTime from, DateTime to) {
    final f = from.millisecondsSinceEpoch, t = to.millisecondsSinceEpoch;
    final result = <String, double>{};
    for (final e in _expenses.values.where((e) => e.date >= f && e.date <= t)) {
      result[e.categoryName] = (result[e.categoryName] ?? 0) + e.amount;
    }
    return result;
  }

  // Staff Performance (Cashier Sales Breakdown)
  Map<String, Map<String, dynamic>> salesByCashierInRange(DateTime from, DateTime to) {
    final f = from.millisecondsSinceEpoch, t = to.millisecondsSinceEpoch;
    final result = <String, Map<String, dynamic>>{};

    for (final s in _sales.values.where((s) => !s.isVoided && s.localTimestamp >= f && s.localTimestamp <= t)) {
      final cashier = (s.cashierName != null && s.cashierName!.isNotEmpty) ? s.cashierName! : 'Main Cashier';
      final current = result[cashier] ?? {'name': cashier, 'totalSales': 0.0, 'count': 0, 'voids': 0};
      current['totalSales'] = (current['totalSales'] as double) + s.totalAmount;
      current['count'] = (current['count'] as int) + 1;
      result[cashier] = current;
    }
    return result;
  }

  // Top Selling Products (Units & Revenue)
  List<Map<String, dynamic>> getTopSellingProducts({int limit = 5}) {
    final productMap = <String, Map<String, dynamic>>{};

    for (final s in _sales.values.where((s) => !s.isVoided)) {
      try {
        final items = jsonDecode(s.itemsJson) as List<dynamic>;
        for (final it in items) {
          final name = it['name'] as String? ?? 'Item';
          final qty = (it['quantity'] as num?)?.toDouble() ?? 1.0;
          final price = (it['price'] as num?)?.toDouble() ?? 0.0;
          final total = (it['subtotal'] as num?)?.toDouble() ?? (qty * price);

          final existing = productMap[name] ?? {'name': name, 'quantity': 0.0, 'revenue': 0.0};
          existing['quantity'] = (existing['quantity'] as double) + qty;
          existing['revenue'] = (existing['revenue'] as double) + total;
          productMap[name] = existing;
        }
      } catch (_) {}
    }

    final list = productMap.values.toList()
      ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
    return list.take(limit).toList();
  }

  void close() => _changeController.close();
}
