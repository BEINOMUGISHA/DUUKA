import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  // Multi-tenant Businesses
  businesses: defineTable({
    name: v.string(),
    legalName: v.optional(v.string()),
    tin: v.optional(v.string()), // Uganda Tax Identification Number for URA EFRIS
    currency: v.string(), // Default "UGX"
    phone: v.string(),
    address: v.optional(v.string()),
    logoUrl: v.optional(v.string()),
    subscriptionTier: v.union(v.literal("free"), v.literal("basic"), v.literal("pro")),
    subscriptionStatus: v.union(v.literal("trial"), v.literal("active"), v.literal("past_due"), v.literal("cancelled")),
    efrisDeviceId: v.optional(v.string()),
    efrisKey: v.optional(v.string()),
    isEfrisEnrolled: v.boolean(),
    createdAt: v.number(),
    updatedAt: v.number(),
  }),

  // Users & Staff
  users: defineTable({
    businessId: v.id("businesses"),
    phone: v.string(), // e.g. "+256770000000"
    fullName: v.string(),
    role: v.union(v.literal("owner"), v.literal("manager"), v.literal("staff")),
    pinHash: v.string(), // Salted PIN hash
    permissions: v.array(v.string()), // e.g. ["can_void_sale", "can_view_reports", "can_view_cost_price", "can_approve_credit"]
    isActive: v.boolean(),
    lastLoginAt: v.optional(v.number()),
    createdAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_phone", ["phone"]),

  // Products & Services Catalog
  products: defineTable({
    businessId: v.id("businesses"),
    name: v.string(),
    sku: v.optional(v.string()),
    barcode: v.optional(v.string()),
    category: v.string(),
    costPrice: v.number(), // UGX
    sellPrice: v.number(), // UGX
    currentStock: v.number(),
    minStockLevel: v.number(), // Threshold for low-stock alerts
    unit: v.string(), // "pcs", "kg", "litres", "box", "sachet"
    isTaxable: v.boolean(),
    taxRate: v.number(), // Default 0.18 for 18% Uganda VAT
    imageUrl: v.optional(v.string()),
    isArchived: v.boolean(),
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_business_and_category", ["businessId", "category"])
    .index("by_business_and_sku", ["businessId", "sku"]),

  // Stock Movements (Deltas for offline concurrency safety)
  stockMovements: defineTable({
    businessId: v.id("businesses"),
    productId: v.id("products"),
    deltaQuantity: v.number(), // Positive for restock/return, negative for sale/loss
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
    referenceId: v.optional(v.string()), // saleId or purchaseId or batchId
    batchNumber: v.optional(v.string()),
    expiryDate: v.optional(v.number()),
    deviceId: v.string(),
    localTimestamp: v.number(),
    createdBy: v.id("users"),
    createdAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_product", ["productId"])
    .index("by_business_and_created", ["businessId", "createdAt"]),

  // Customers & Debtors (Ababanja)
  customers: defineTable({
    businessId: v.id("businesses"),
    name: v.string(),
    phone: v.string(),
    email: v.optional(v.string()),
    address: v.optional(v.string()),
    creditLimit: v.number(), // UGX
    outstandingBalance: v.number(), // Total credit owed
    isDebtor: v.boolean(),
    notes: v.optional(v.string()),
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_business_and_phone", ["businessId", "phone"])
    .index("by_business_and_debtor", ["businessId", "isDebtor"]),

  // Suppliers & Accounts Payable
  suppliers: defineTable({
    businessId: v.id("businesses"),
    name: v.string(),
    phone: v.string(),
    email: v.optional(v.string()),
    address: v.optional(v.string()),
    balanceOwed: v.number(), // UGX we owe supplier
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_business", ["businessId"]),

  // Sales / POS Transactions
  sales: defineTable({
    businessId: v.id("businesses"),
    saleNumber: v.string(), // e.g. "SL-2026-0001"
    customerId: v.optional(v.id("customers")),
    customerName: v.optional(v.string()),
    customerPhone: v.optional(v.string()),
    items: v.array(
      v.object({
        productId: v.id("products"),
        productName: v.string(),
        quantity: v.number(),
        unitPrice: v.number(),
        subtotal: v.number(),
        costPrice: v.number(),
        taxAmount: v.number(),
      })
    ),
    subtotalAmount: v.number(),
    taxAmount: v.number(),
    discountAmount: v.number(),
    totalAmount: v.number(),
    paidAmount: v.number(),
    dueAmount: v.number(), // Outstanding balance if credit sale
    paymentStatus: v.union(v.literal("paid"), v.literal("partial"), v.literal("unpaid")),
    paymentMethod: v.union(
      v.literal("cash"),
      v.literal("mtn_momo"),
      v.literal("airtel_money"),
      v.literal("bank"),
      v.literal("credit"),
      v.literal("split")
    ),
    momoReference: v.optional(v.string()), // MoMo transaction ID / USSD ref
    isCredit: v.boolean(),
    dueDate: v.optional(v.number()),
    // EFRIS / URA Compliance fields
    efrisInvoiceNo: v.optional(v.string()),
    efrisFiscalCode: v.optional(v.string()),
    efrisVerificationCode: v.optional(v.string()),
    efrisQrCodeData: v.optional(v.string()),
    // Offline Tracking
    offlineId: v.optional(v.string()),
    deviceId: v.string(),
    localTimestamp: v.number(),
    createdBy: v.id("users"),
    createdAt: v.number(),
    syncedAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_business_and_created", ["businessId", "createdAt"])
    .index("by_business_and_status", ["businessId", "paymentStatus"])
    .index("by_customer", ["customerId"])
    .index("by_offline_id", ["offlineId"]),

  // Invoices
  invoices: defineTable({
    businessId: v.id("businesses"),
    invoiceNumber: v.string(), // "INV-2026-0001"
    saleId: v.optional(v.id("sales")),
    customerId: v.id("customers"),
    totalAmount: v.number(),
    paidAmount: v.number(),
    dueAmount: v.number(),
    issueDate: v.number(),
    dueDate: v.number(),
    status: v.union(v.literal("draft"), v.literal("issued"), v.literal("partial"), v.literal("paid"), v.literal("overdue")),
    notes: v.optional(v.string()),
    createdAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_customer", ["customerId"])
    .index("by_business_and_status", ["businessId", "status"]),

  // Payments / Receipts
  payments: defineTable({
    businessId: v.id("businesses"),
    receiptNumber: v.string(),
    entityType: v.union(v.literal("sale"), v.literal("invoice"), v.literal("customer_credit"), v.literal("supplier_payable")),
    entityId: v.string(),
    customerId: v.optional(v.id("customers")),
    supplierId: v.optional(v.id("suppliers")),
    amount: v.number(),
    paymentMethod: v.union(v.literal("cash"), v.literal("mtn_momo"), v.literal("airtel_money"), v.literal("bank")),
    reference: v.optional(v.string()),
    notes: v.optional(v.string()),
    receivedBy: v.id("users"),
    deviceId: v.string(),
    createdAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_customer", ["customerId"])
    .index("by_business_and_created", ["businessId", "createdAt"]),

  // Income & Expenses (Daily Cashbook)
  transactions: defineTable({
    businessId: v.id("businesses"),
    type: v.union(v.literal("income"), v.literal("expense")),
    category: v.string(), // "transport", "market_rent", "salary", "airtime", "fuel", "stock_purchase", "utilities", "lunch", "other"
    amount: v.number(),
    paymentMethod: v.union(v.literal("cash"), v.literal("mtn_momo"), v.literal("airtel_money"), v.literal("bank")),
    reference: v.optional(v.string()),
    receiptImageStorageId: v.optional(v.id("_storage")),
    notes: v.optional(v.string()),
    isRecurring: v.boolean(),
    recurringFrequency: v.optional(v.union(v.literal("daily"), v.literal("weekly"), v.literal("monthly"))),
    date: v.number(),
    deviceId: v.string(),
    createdBy: v.id("users"),
    createdAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_business_type_date", ["businessId", "type", "date"])
    .index("by_business_and_date", ["businessId", "date"]),

  // Audit Log & Activity Trail
  auditLogs: defineTable({
    businessId: v.id("businesses"),
    userId: v.id("users"),
    userName: v.string(),
    action: v.string(), // "CREATE_SALE", "VOID_SALE", "RESTOCK_PRODUCT", "ADD_EXPENSE", "APPROVE_CREDIT"
    entityType: v.string(),
    entityId: v.string(),
    deviceId: v.string(),
    details: v.string(),
    createdAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_business_and_created", ["businessId", "createdAt"]),
});
