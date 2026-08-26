import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  // 1. Multi-tenant Businesses
  businesses: defineTable({
    name: v.string(),
    legalName: v.optional(v.string()),
    ownerId: v.optional(v.string()),
    phone: v.string(),
    email: v.optional(v.string()),
    address: v.optional(v.string()),
    city: v.optional(v.string()),
    country: v.string(), // Default "Uganda"
    currency: v.string(), // Default "UGX"
    logoUrl: v.optional(v.string()),
    tin: v.optional(v.string()), // Uganda Tax Identification Number for URA EFRIS
    smsCredits: v.number(), // SMS credit balance
    subscriptionTier: v.union(v.literal("free"), v.literal("basic"), v.literal("pro")),
    status: v.union(v.literal("active"), v.literal("trial"), v.literal("suspended"), v.literal("cancelled")),
    efrisDeviceId: v.optional(v.string()),
    efrisKey: v.optional(v.string()),
    isEfrisEnrolled: v.boolean(),
    createdAt: v.number(),
    updatedAt: v.number(),
  }),

  // 2. Users & Staff
  users: defineTable({
    businessId: v.id("businesses"),
    phone: v.string(), // Normalized e.g. "256770000000"
    fullName: v.string(),
    role: v.union(
      v.literal("owner"),
      v.literal("admin"),
      v.literal("manager"),
      v.literal("cashier"),
      v.literal("staff")
    ),
    pinHash: v.string(), // Salted PIN hash
    permissions: v.array(v.string()), // e.g. ["can_void_sale", "can_view_reports", "can_view_cost_price", "can_approve_credit", "can_send_sms", "can_manage_staff"]
    isActive: v.boolean(),
    lastLoginAt: v.optional(v.number()),
    createdAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_phone", ["phone"])
    .index("by_business_and_phone", ["businessId", "phone"]),

  // 3. Product Categories
  categories: defineTable({
    businessId: v.id("businesses"),
    name: v.string(),
    icon: v.optional(v.string()),
    createdAt: v.number(),
  }).index("by_business", ["businessId"]),

  // 4. Products Catalog & Stock
  products: defineTable({
    businessId: v.id("businesses"),
    name: v.string(),
    sku: v.optional(v.string()),
    barcode: v.optional(v.string()),
    categoryId: v.optional(v.id("categories")),
    category: v.string(), // Denormalized category name
    sellingPrice: v.number(), // UGX
    costPrice: v.number(), // UGX
    stockQuantity: v.number(),
    lowStockThreshold: v.number(), // Threshold for low-stock warnings
    unit: v.string(), // "pcs", "kg", "litres", "box", "sachet", "bag", "pkt"
    image: v.optional(v.string()),
    isTaxable: v.boolean(),
    taxRate: v.number(), // Default 0.18 for 18% Uganda VAT
    isArchived: v.boolean(),
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_business_and_category", ["businessId", "category"])
    .index("by_business_and_sku", ["businessId", "sku"])
    .index("by_business_and_barcode", ["businessId", "barcode"]),

  // 5. Stock Movements (Inventory Audit Trail)
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
    referenceId: v.optional(v.string()), // saleId, batchId, or invoiceId
    supplierName: v.optional(v.string()),
    costPerUnit: v.optional(v.number()),
    notes: v.optional(v.string()),
    deviceId: v.string(),
    createdBy: v.id("users"),
    createdAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_product", ["productId"])
    .index("by_business_and_created", ["businessId", "createdAt"]),

  // 6. Customers
  customers: defineTable({
    businessId: v.id("businesses"),
    name: v.string(),
    phone: v.string(), // Normalized "2567XXXXXXXX"
    email: v.optional(v.string()),
    address: v.optional(v.string()),
    notes: v.optional(v.string()),
    creditLimit: v.number(), // UGX
    currentDebt: v.number(), // Total outstanding credit owed
    isArchived: v.optional(v.boolean()),
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_phone", ["phone"])
    .index("by_business_and_phone", ["businessId", "phone"])
    .index("by_business_and_debt", ["businessId", "currentDebt"]),

  // 7. Sales Records
  sales: defineTable({
    businessId: v.id("businesses"),
    saleNumber: v.string(), // e.g. "DUKA-2026-000001"
    customerId: v.optional(v.id("customers")),
    customerName: v.optional(v.string()),
    customerPhone: v.optional(v.string()),
    subtotal: v.number(),
    discount: v.number(),
    tax: v.number(),
    total: v.number(),
    amountPaid: v.number(),
    balance: v.number(), // Outstanding balance if credit sale
    paymentMethod: v.union(
      v.literal("cash"),
      v.literal("mtn_momo"),
      v.literal("airtel_money"),
      v.literal("bank"),
      v.literal("credit")
    ),
    status: v.union(v.literal("completed"), v.literal("voided"), v.literal("pending")),
    momoReference: v.optional(v.string()),
    dueDate: v.optional(v.number()),
    // EFRIS / URA Compliance fields
    efrisFiscalCode: v.optional(v.string()),
    efrisQrCodeData: v.optional(v.string()),
    deviceId: v.string(),
    localTimestamp: v.number(),
    createdBy: v.id("users"),
    createdAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_business_and_created", ["businessId", "createdAt"])
    .index("by_customer", ["customerId"])
    .index("by_business_and_status", ["businessId", "status"]),

  // 8. Sale Items
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
    .index("by_business", ["businessId"])
    .index("by_product", ["productId"]),

  // 9. Debts / Credit Sales Tracking
  debts: defineTable({
    businessId: v.id("businesses"),
    customerId: v.id("customers"),
    saleId: v.optional(v.id("sales")),
    originalAmount: v.number(),
    amountPaid: v.number(),
    balance: v.number(),
    dueDate: v.number(),
    status: v.union(
      v.literal("active"),
      v.literal("partially_paid"),
      v.literal("paid"),
      v.literal("overdue"),
      v.literal("cancelled")
    ),
    notes: v.optional(v.string()),
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_customer", ["customerId"])
    .index("by_business_and_status", ["businessId", "status"])
    .index("by_due_date", ["dueDate"]),

  // 10. Payments Ledger
  payments: defineTable({
    businessId: v.id("businesses"),
    receiptNumber: v.string(), // "RCP-2026-000001"
    entityType: v.union(v.literal("sale"), v.literal("debt"), v.literal("invoice"), v.literal("customer_credit")),
    entityId: v.string(),
    customerId: v.optional(v.id("customers")),
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

  // 11. Mobile Money Transactions (MTN MoMo & Airtel Money)
  mobileMoneyTransactions: defineTable({
    businessId: v.id("businesses"),
    saleId: v.optional(v.id("sales")),
    customerId: v.optional(v.id("customers")),
    provider: v.union(v.literal("mtn_momo"), v.literal("airtel_money")),
    phone: v.string(), // Normalized "2567XXXXXXXX"
    amount: v.number(),
    currency: v.string(), // "UGX"
    externalReference: v.string(), // UUID/Idempotency key
    providerTransactionId: v.optional(v.string()),
    status: v.union(
      v.literal("pending"),
      v.literal("successful"),
      v.literal("failed"),
      v.literal("cancelled"),
      v.literal("expired")
    ),
    failureReason: v.optional(v.string()),
    createdAt: v.number(),
    updatedAt: v.number(),
    completedAt: v.optional(v.number()),
  })
    .index("by_business", ["businessId"])
    .index("by_reference", ["externalReference"])
    .index("by_status", ["status"])
    .index("by_business_and_created", ["businessId", "createdAt"]),

  // 12. SMS Messages
  smsMessages: defineTable({
    businessId: v.id("businesses"),
    customerId: v.optional(v.id("customers")),
    phone: v.string(),
    message: v.string(),
    type: v.union(
      v.literal("debt_reminder"),
      v.literal("payment_confirmation"),
      v.literal("invoice"),
      v.literal("custom"),
      v.literal("welcome")
    ),
    status: v.union(v.literal("pending"), v.literal("sent"), v.literal("delivered"), v.literal("failed")),
    provider: v.string(), // "africas_talking", "twilio", "sandbox_gateway"
    providerMessageId: v.optional(v.string()),
    cost: v.number(), // in SMS credits
    createdAt: v.number(),
    sentAt: v.optional(v.number()),
    error: v.optional(v.string()),
  })
    .index("by_business", ["businessId"])
    .index("by_customer", ["customerId"])
    .index("by_status", ["status"]),

  // 13. SMS Usage Tracking
  smsUsage: defineTable({
    businessId: v.id("businesses"),
    smsId: v.id("smsMessages"),
    creditsUsed: v.number(),
    createdAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_business_and_created", ["businessId", "createdAt"]),

  // 14. Invoices
  invoices: defineTable({
    businessId: v.id("businesses"),
    invoiceNumber: v.string(), // "DUKA-INV-2026-000001"
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

  // 15. In-App Notifications
  notifications: defineTable({
    businessId: v.id("businesses"),
    userId: v.optional(v.id("users")),
    title: v.string(),
    message: v.string(),
    type: v.union(
      v.literal("low_stock"),
      v.literal("payment_received"),
      v.literal("debt_overdue"),
      v.literal("debt_due_soon"),
      v.literal("momo_success"),
      v.literal("momo_failed")
    ),
    isRead: v.boolean(),
    createdAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_business_and_read", ["businessId", "isRead"]),

  // 16. Audit Log & Activity Trail
  auditLogs: defineTable({
    businessId: v.id("businesses"),
    userId: v.id("users"),
    userName: v.string(),
    action: v.string(), // "LOGIN", "SALE_CREATED", "SALE_CANCELLED", "PAYMENT_CREATED", "DEBT_CREATED", "DEBT_PAYMENT", "PRODUCT_CREATED", "STOCK_ADJUSTED", "SMS_SENT", "MOMO_REQUESTED", "MOMO_CONFIRMED"
    entityType: v.string(),
    entityId: v.string(),
    deviceId: v.string(),
    details: v.string(),
    createdAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_business_and_created", ["businessId", "createdAt"]),

  // 17. Income & Expenses Ledger
  transactions: defineTable({
    businessId: v.id("businesses"),
    type: v.union(v.literal("income"), v.literal("expense")),
    category: v.string(),
    amount: v.number(),
    paymentMethod: v.union(v.literal("cash"), v.literal("mtn_momo"), v.literal("airtel_money"), v.literal("bank")),
    reference: v.optional(v.string()),
    notes: v.optional(v.string()),
    isRecurring: v.boolean(),
    date: v.number(),
    deviceId: v.string(),
    createdBy: v.id("users"),
    createdAt: v.number(),
  })
    .index("by_business", ["businessId"])
    .index("by_business_and_date", ["businessId", "date"]),
});
