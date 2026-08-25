import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

// POS Checkout / Create Sale Mutation
export const createSale = mutation({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
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
    paymentMethod: v.union(
      v.literal("cash"),
      v.literal("mtn_momo"),
      v.literal("airtel_money"),
      v.literal("bank"),
      v.literal("credit"),
      v.literal("split")
    ),
    momoReference: v.optional(v.string()),
    dueDate: v.optional(v.number()),
    offlineId: v.optional(v.string()),
    deviceId: v.string(),
    localTimestamp: v.number(),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const dueAmount = Math.max(0, args.totalAmount - args.paidAmount);
    const isCredit = dueAmount > 0;
    const paymentStatus = dueAmount === 0 ? "paid" : args.paidAmount > 0 ? "partial" : "unpaid";

    // Generate readable sale number: SL-YYYYMMDD-XXXX
    const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, "");
    const randomSuffix = Math.floor(1000 + Math.random() * 9000);
    const saleNumber = `SL-${dateStr}-${randomSuffix}`;

    // Generate simulated EFRIS / URA fiscal receipt fields
    const business = await ctx.db.get(args.businessId);
    let efrisInvoiceNo: string | undefined;
    let efrisFiscalCode: string | undefined;
    let efrisVerificationCode: string | undefined;
    let efrisQrCodeData: string | undefined;

    if (business?.isEfrisEnrolled && business.tin) {
      efrisInvoiceNo = `URA-${business.tin}-${dateStr}-${randomSuffix}`;
      efrisFiscalCode = `FC-${Math.random().toString(36).substring(2, 10).toUpperCase()}`;
      efrisVerificationCode = Math.random().toString(36).substring(2, 8).toUpperCase();
      efrisQrCodeData = `https://efris.ura.go.ug/verify?tin=${business.tin}&inv=${efrisInvoiceNo}&amt=${args.totalAmount}&fc=${efrisFiscalCode}`;
    }

    // 1. Insert Sale record
    const saleId = await ctx.db.insert("sales", {
      businessId: args.businessId,
      saleNumber,
      customerId: args.customerId,
      customerName: args.customerName,
      customerPhone: args.customerPhone,
      items: args.items,
      subtotalAmount: args.subtotalAmount,
      taxAmount: args.taxAmount,
      discountAmount: args.discountAmount,
      totalAmount: args.totalAmount,
      paidAmount: args.paidAmount,
      dueAmount,
      paymentStatus,
      paymentMethod: args.paymentMethod,
      momoReference: args.momoReference,
      isCredit,
      dueDate: args.dueDate,
      efrisInvoiceNo,
      efrisFiscalCode,
      efrisVerificationCode,
      efrisQrCodeData,
      offlineId: args.offlineId,
      deviceId: args.deviceId,
      localTimestamp: args.localTimestamp,
      createdBy: args.userId,
      createdAt: now,
      syncedAt: now,
    });

    // 2. Apply Stock Movement Deltas for each item
    for (const item of args.items) {
      const product = await ctx.db.get(item.productId);
      if (product) {
        const prev = product.currentStock;
        const next = Math.max(0, prev - item.quantity);
        await ctx.db.patch(item.productId, {
          currentStock: next,
          updatedAt: now,
        });

        await ctx.db.insert("stockMovements", {
          businessId: args.businessId,
          productId: item.productId,
          deltaQuantity: -item.quantity,
          previousStock: prev,
          newStock: next,
          reason: "sale",
          referenceId: saleId,
          deviceId: args.deviceId,
          localTimestamp: args.localTimestamp,
          createdBy: args.userId,
          createdAt: now,
        });
      }
    }

    // 3. Update Customer Debtor balance if credit sale
    if (args.customerId && isCredit) {
      const customer = await ctx.db.get(args.customerId);
      if (customer) {
        const newBalance = customer.outstandingBalance + dueAmount;
        await ctx.db.patch(args.customerId, {
          outstandingBalance: newBalance,
          isDebtor: newBalance > 0,
          updatedAt: now,
        });
      }
    }

    // 4. Log Payment if paidAmount > 0
    if (args.paidAmount > 0) {
      await ctx.db.insert("payments", {
        businessId: args.businessId,
        receiptNumber: `REC-${dateStr}-${randomSuffix}`,
        entityType: "sale",
        entityId: saleId,
        customerId: args.customerId,
        amount: args.paidAmount,
        paymentMethod: args.paymentMethod === "credit" ? "cash" : (args.paymentMethod as any),
        reference: args.momoReference,
        notes: `Payment for ${saleNumber}`,
        receivedBy: args.userId,
        deviceId: args.deviceId,
        createdAt: now,
      });

      // Record in Daily Cashbook
      await ctx.db.insert("transactions", {
        businessId: args.businessId,
        type: "income",
        category: "sale_revenue",
        amount: args.paidAmount,
        paymentMethod: args.paymentMethod === "credit" ? "cash" : (args.paymentMethod as any),
        reference: args.momoReference,
        notes: `Sale ${saleNumber}`,
        isRecurring: false,
        date: now,
        deviceId: args.deviceId,
        createdBy: args.userId,
        createdAt: now,
      });
    }

    // 5. Audit Log
    const user = await ctx.db.get(args.userId);
    await ctx.db.insert("auditLogs", {
      businessId: args.businessId,
      userId: args.userId,
      userName: user?.fullName ?? "Staff",
      action: "CREATE_SALE",
      entityType: "sale",
      entityId: saleId,
      deviceId: args.deviceId,
      details: `Sale ${saleNumber} created for UGX ${args.totalAmount} (${args.paymentMethod})`,
      createdAt: now,
    });

    return {
      saleId,
      saleNumber,
      efrisFiscalCode,
      efrisQrCodeData,
      paymentStatus,
      dueAmount,
    };
  },
});

// List Sales
export const listSales = query({
  args: {
    businessId: v.id("businesses"),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("sales")
      .withIndex("by_business_and_created", (q) => q.eq("businessId", args.businessId))
      .order("desc")
      .take(args.limit ?? 50);
  },
});

// Get Sale Details
export const getSaleDetails = query({
  args: {
    saleId: v.id("sales"),
  },
  handler: async (ctx, args) => {
    return await ctx.db.get(args.saleId);
  },
});
