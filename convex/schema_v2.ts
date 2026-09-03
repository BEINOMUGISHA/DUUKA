import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

/**
 * ENHANCED SCHEMA v2
 * 
 * New fields for conflict resolution:
 * - `version`: Optimistic locking version number
 * - `offlineId`: For idempotency & deduplication
 * - New tables: syncBatches, syncConflicts
 */

export default defineSchema({
  // ============================================================================
  // CORE BUSINESS ENTITIES (with version tracking for conflict resolution)
  // ============================================================================

  businesses: defineTable({
    name: v.string(),
    businessVertical: v.optional(v.string()),
    legalName: v.optional(v.string()),
    ownerId: v.optional(v.string()),
    phone: v.string(),
    email: v.optional(v.string()),
    address: v.optional(v.string()),
    city: v.optional(v.string()),
    country: v.string(),
    currency: v.string(),
    logoUrl: v.optional(v.string()),
    tin: v.optional(v.string()),
    smsCredits: v.number(),
    subscriptionTier: v.union(v.literal("free"), v.literal("basic"), v.literal("pro")),
    status: v.union(v.literal("active"), v.literal("trial"), v.literal("suspended"), v.literal("cancelled")),
    efrisDeviceId: v.optional(v.string()),
    efrisKey: v.optional(v.string()),
    isEfrisEnrolled: v.boolean(),
    version: v.number(), // For optimistic locking
    createdAt: v.number(),
    updatedAt: v.number(),
  }),

  users: defineTable({
    businessId: v.id("businesses"),
    phone: v.string(),
    fullName: v.string(),
    role: v.union(
      v.literal("owner"),
      v.literal("admin"),
      v.literal("manager"),
      v.literal("cashier"),
      v.literal("staff")
    ),
    pinHash: v.string(),
    permissions: v.array(v.string()),
    isActive: v.boolean(),
    lastLoginAt: v.optional(v.number()),
    version: v.number(),
    createdAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_phone", ["phone"])
    .index("by_business_and_phone", ["businessId", "phone"]),

  categories: defineTable({
    businessId: v.id("businesses"),
    name: v.string(),
    icon: v.optional(v.string()),
    version: v.number(),
    createdAt: v.number(),
  }).index("by_business", ["businessId"]),

  // PRODUCTS with delta-based stock tracking
  products: defineTable({
    businessId: v.id("businesses"),
    offlineId: v.optional(v.string()), // For deduplication on sync
    name: v.string(),
    sku: v.optional(v.string()),
    barcode: v.optional(v.string()),
    categoryId: v.optional(v.id("categories")),
    category: v.string(),
    sellingPrice: v.number(),
    costPrice: v.number(),
    stockQuantity: v.number(), // Updated via delta operations
    lowStockThreshold: v.number(),
    unit: v.string(),
    image: v.optional(v.string()),
    isTaxable: v.boolean(),
    taxRate: v.number(),
    isArchived: v.boolean(),
    version: v.number(), // Version for conflict detection
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_business_and_category", ["businessId", "category"])
    .index("by_business_and_sku", ["businessId", "sku"])
    .index("by_business_and_barcode", ["businessId", "barcode"])
    .index("by_offline_id", ["offlineId"]),

  // STOCK MOVEMENTS - Audit trail of all stock deltas
  stockMovements: defineTable({
    businessId: v.id("businesses"),
    productId: v.id("products"),
    deltaQuantity: v.number(), // Positive or negative - NEVER read-modify-write!
    previousStock: v.number(),
    newStock: v.number(),
    reason: v.union(
      v.literal("sale"),
      v.literal("purchase"),
      v.literal("restock"),
      v.literal("damage"),
      v.literal("loss"),
      v.literal("adjustment"),
      v.literal("return")
    ),
    referenceId: v.optional(v.string()),
    supplierName: v.optional(v.string()),
    costPerUnit: v.optional(v.number()),
    notes: v.optional(v.string()),
    offlineId: v.optional(v.string()), // For deduplication
    deviceId: v.string(),
    createdBy: v.id("users"),
    createdAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_product", ["productId"])
    .index("by_business_and_created", ["businessId", "createdAt"])
    .index("by_offline_id", ["offlineId"]),

  // CUSTOMERS with debt tracking
  customers: defineTable({
    businessId: v.id("businesses"),
    offlineId: v.optional(v.string()),
    name: v.string(),
    phone: v.string(),
    email: v.optional(v.string()),
    address: v.optional(v.string()),
    notes: v.optional(v.string()),
    creditLimit: v.number(),
    currentDebt: v.number(), // Updated via atomic increments
    isArchived: v.optional(v.boolean()),
    version: v.number(),
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_phone", ["phone"])
    .index("by_business_and_phone", ["businessId", "phone"])
    .index("by_business_and_debt", ["businessId", "currentDebt"])
    .index("by_offline_id", ["offlineId"]),

  // SALES with offline tracking
  sales: defineTable({
    businessId: v.id("businesses"),
    offlineId: v.optional(v.string()), // CRITICAL: For idempotency
    saleNumber: v.string(),
    customerId: v.optional(v.id("customers")),
    customerName: v.optional(v.string()),
    customerPhone: v.optional(v.string()),
    subtotal: v.number(),
    discount: v.number(),
    tax: v.number(),
    total: v.number(),
    amountPaid: v.number(),
    balance: v.number(),
    status: v.union(v.literal("pending"), v.literal("completed"), v.literal("voided")),
    paymentMethod: v.union(
      v.literal("cash"),
      v.literal("mtn_momo"),
      v.literal("airtel_money"),
      v.literal("bank_transfer"),
      v.literal("credit")
    ),
    momoReference: v.optional(v.string()),
    dueDate: v.optional(v.number()),
    deviceId: v.string(), // For multi-device tracking
    localTimestamp: v.number(), // Original offline timestamp
    createdBy: v.id("users"),
    version: v.number(),
    createdAt: v.number(),
    updatedAt: v.optional(v.number()),
  })
    .index("by_business", ["businessId"])
    .index("by_customer", ["customerId"])
    .index("by_status", ["status"])
    .index("by_created", ["createdAt"])
    .index("by_offline_id", ["offlineId"]), // CRITICAL: Query before insert

  // SALE ITEMS - Individual line items
  saleItems: defineTable({
    saleId: v.id("sales"),
    businessId: v.id("businesses"),
    productId: v.id("products"),
    productName: v.string(),
    quantity: v.number(),
    unitPrice: v.number(),
    costPrice: v.number(),
    discount: v.number(),
    total: v.number(),
  })
    .index("by_sale", ["saleId"])
    .index("by_business", ["businessId"]),

  // DEBTS - Credit sale ledger
  debts: defineTable({
    businessId: v.id("businesses"),
    customerId: v.id("customers"),
    saleId: v.id("sales"),
    originalAmount: v.number(),
    amountPaid: v.number(),
    balance: v.number(),
    dueDate: v.number(),
    status: v.union(v.literal("active"), v.literal("paid"), v.literal("overdue")),
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_customer", ["customerId"])
    .index("by_status", ["status"])
    .index("by_business", ["businessId"]),

  // PAYMENTS - Payment history
  payments: defineTable({
    businessId: v.id("businesses"),
    offlineId: v.optional(v.string()), // For deduplication
    receiptNumber: v.string(),
    entityType: v.string(),
    entityId: v.optional(v.string()),
    customerId: v.optional(v.id("customers")),
    amount: v.number(),
    paymentMethod: v.string(),
    reference: v.optional(v.string()),
    notes: v.optional(v.string()),
    receivedBy: v.id("users"),
    deviceId: v.string(),
    version: v.number(),
    createdAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_customer", ["customerId"])
    .index("by_offline_id", ["offlineId"]),

  // TRANSACTIONS - Income/expense log
  transactions: defineTable({
    businessId: v.id("businesses"),
    offlineId: v.optional(v.string()), // For deduplication
    type: v.union(v.literal("income"), v.literal("expense")),
    category: v.string(),
    amount: v.number(),
    paymentMethod: v.string(),
    reference: v.optional(v.string()),
    notes: v.optional(v.string()),
    isRecurring: v.boolean(),
    date: v.number(),
    deviceId: v.string(),
    createdBy: v.id("users"),
    version: v.number(),
    createdAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_type", ["type"])
    .index("by_date", ["date"])
    .index("by_offline_id", ["offlineId"]),

  // ============================================================================
  // SYNC INFRASTRUCTURE TABLES (NEW)
  // ============================================================================

  /**
   * SYNC BATCHES - Idempotency & audit trail
   * Ensures that if a device syncs the same batch twice (network retry),
   * the server returns cached results instead of processing again.
   */
  syncBatches: defineTable({
    businessId: v.id("businesses"),
    deviceId: v.string(),
    syncBatchId: v.string(), // Unique ID generated by client
    results: v.array(
      v.object({
        queueId: v.string(),
        status: v.string(), // "success", "conflict", "error"
        serverId: v.optional(v.string()),
        error: v.optional(v.string()),
        conflictType: v.optional(v.string()),
      })
    ),
    processedAt: v.number(),
  })
    .index("by_unique_batch", ["businessId", "deviceId", "syncBatchId"])
    .index("by_device", ["businessId", "deviceId", "processedAt"]),

  /**
   * SYNC CONFLICTS - Tracks version mismatches & conflicts
   * Used to notify UI and allow manual resolution
   */
  syncConflicts: defineTable({
    businessId: v.id("businesses"),
    queueId: v.string(),
    entityType: v.string(),
    conflictType: v.string(), // "version_mismatch", "duplicate", "validation_error"
    error: v.string(),
    clientData: v.optional(v.string()), // JSON
    serverData: v.optional(v.string()), // JSON
    resolutionStrategy: v.optional(v.string()), // "server" or "client"
    resolvedAt: v.optional(v.number()),
    detectedAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_resolved", ["resolvedAt"])
    .index("by_entity", ["queueId"]),

  /**
   * MOBILE MONEY TRANSACTIONS - Payment provider integrations
   * Links sales to MoMo/Airtel transactions
   */
  mobileMoneyTransactions: defineTable({
    businessId: v.id("businesses"),
    saleId: v.optional(v.id("sales")),
    offlineSaleId: v.optional(v.string()), // Before sale is synced
    provider: v.union(v.literal("mtn_momo"), v.literal("airtel_money")),
    amount: v.number(),
    reference: v.string(),
    status: v.union(v.literal("pending"), v.literal("completed"), v.literal("failed")),
    deviceId: v.string(),
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_sale", ["saleId"])
    .index("by_offline_sale_id", ["offlineSaleId"]),

  /**
   * SYNC QUEUE - Local queue representation on server
   * Useful for debugging and manual sync operations
   */
  syncQueue: defineTable({
    businessId: v.id("businesses"),
    deviceId: v.string(),
    queueId: v.string(),
    entityType: v.string(),
    action: v.string(),
    payload: v.string(),
    status: v.union(v.literal("pending"), v.literal("synced"), v.literal("failed")),
    localTimestamp: v.number(),
    syncedAt: v.optional(v.number()),
    retryCount: v.number(),
    lastError: v.optional(v.string()),
    createdAt: v.number(),
  })
    .index("by_business_device", ["businessId", "deviceId"])
    .index("by_status", ["status"]),

  /**
   * AUDIT LOG - Comprehensive change tracking
   * Tracks all mutations for compliance and debugging
   */
  auditLog: defineTable({
    businessId: v.id("businesses"),
    userId: v.id("users"),
    entityType: v.string(),
    entityId: v.optional(v.string()),
    action: v.string(),
    changes: v.optional(v.string()), // JSON with before/after values
    deviceId: v.string(),
    ipAddress: v.optional(v.string()),
    timestamp: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_user", ["userId"])
    .index("by_timestamp", ["timestamp"]),

  // ============================================================================
  // REPORTING & ANALYTICS
  // ============================================================================

  reports: defineTable({
    businessId: v.id("businesses"),
    reportType: v.string(), // "sales", "inventory", "profit_loss", "cash_flow"
    period: v.string(), // "daily", "weekly", "monthly"
    startDate: v.number(),
    endDate: v.number(),
    data: v.string(), // JSON with report metrics
    generatedBy: v.id("users"),
    generatedAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_type", ["reportType"]),
});
