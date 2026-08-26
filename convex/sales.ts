import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { verifyUserBusinessAccess } from "./auth";

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
        costPrice: v.number(),
        discount: v.number(),
        total: v.number(),
      })
    ),
    subtotal: v.number(),
    discount: v.number(),
    tax: v.number(),
    total: v.number(),
    amountPaid: v.number(),
    paymentMethod: v.union(
      v.literal("cash"),
      v.literal("mtn_momo"),
      v.literal("airtel_money"),
      v.literal("bank"),
      v.literal("credit")
    ),
    momoReference: v.optional(v.string()),
    dueDate: v.optional(v.number()),
    deviceId: v.string(),
    localTimestamp: v.number(),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    const now = Date.now();
    const balance = Math.max(0, args.total - args.amountPaid);
    const isCredit = balance > 0;

    // Generate sequential readable sale number
    const currentYear = new Date().getFullYear();
    const existingSales = await ctx.db
      .query("sales")
      .withIndex("by_business", (q) => q.eq("businessId", args.businessId))
      .collect();

    const seq = (existingSales.length + 1).toString().padStart(6, "0");
    const saleNumber = `DUKA-${currentYear}-${seq}`;

    // EFRIS simulated fiscal codes
    const business = await ctx.db.get(args.businessId);
    let efrisFiscalCode: string | undefined;
    let efrisQrCodeData: string | undefined;

    if (business?.isEfrisEnrolled && business.tin) {
      efrisFiscalCode = `FC-${Math.random().toString(36).substring(2, 10).toUpperCase()}`;
      efrisQrCodeData = `https://efris.ura.go.ug/verify?tin=${business.tin}&inv=${saleNumber}&amt=${args.total}&fc=${efrisFiscalCode}`;
    }

    // 1. Insert Sale record
    const saleId = await ctx.db.insert("sales", {
      businessId: args.businessId,
      saleNumber,
      customerId: args.customerId,
      customerName: args.customerName,
      customerPhone: args.customerPhone,
      subtotal: args.subtotal,
      discount: args.discount,
      tax: args.tax,
      total: args.total,
      amountPaid: args.amountPaid,
      balance,
      paymentMethod: args.paymentMethod,
      status: "completed",
      momoReference: args.momoReference,
      dueDate: args.dueDate,
      efrisFiscalCode,
      efrisQrCodeData,
      deviceId: args.deviceId,
      localTimestamp: args.localTimestamp,
      createdBy: args.userId,
      createdAt: now,
    });

    // 2. Insert Sale Items and apply Stock Movement Deltas
    for (const item of args.items) {
      await ctx.db.insert("saleItems", {
        saleId,
        businessId: args.businessId,
        productId: item.productId,
        productName: item.productName,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        costPrice: item.costPrice,
        discount: item.discount,
        total: item.total,
      });

      const product = await ctx.db.get(item.productId);
      if (product) {
        const prev = product.stockQuantity;
        const next = Math.max(0, prev - item.quantity);
        await ctx.db.patch(item.productId, {
          stockQuantity: next,
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
          createdBy: args.userId,
          createdAt: now,
        });

        // Trigger notification if low stock
        if (next <= product.lowStockThreshold) {
          await ctx.db.insert("notifications", {
            businessId: args.businessId,
            userId: args.userId,
            title: "Low Stock Alert",
            message: `${product.name} is down to ${next} ${product.unit}. Restock soon!`,
            type: "low_stock",
            isRead: false,
            createdAt: now,
          });
        }
      }
    }

    // 3. Update or Create Customer Debt if credit/partial sale
    if (isCredit) {
      if (args.customerId) {
        const customer = await ctx.db.get(args.customerId);
        if (customer) {
          await ctx.db.patch(args.customerId, {
            currentDebt: customer.currentDebt + balance,
            updatedAt: now,
          });
        }
      }

      await ctx.db.insert("debts", {
        businessId: args.businessId,
        customerId: args.customerId ?? ("" as any),
        saleId,
        originalAmount: balance,
        amountPaid: 0,
        balance,
        dueDate: args.dueDate ?? now + 14 * 24 * 60 * 60 * 1000,
        status: "active",
        createdAt: now,
        updatedAt: now,
      });
    }

    // 4. Log Payment if amountPaid > 0
    if (args.amountPaid > 0) {
      const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, "");
      await ctx.db.insert("payments", {
        businessId: args.businessId,
        receiptNumber: `RCP-${dateStr}-${Math.floor(1000 + Math.random() * 9000)}`,
        entityType: "sale",
        entityId: saleId,
        customerId: args.customerId,
        amount: args.amountPaid,
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
        amount: args.amountPaid,
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
      action: "SALE_CREATED",
      entityType: "sale",
      entityId: saleId,
      deviceId: args.deviceId,
      details: `Sale ${saleNumber} created for UGX ${args.total.toLocaleString()} (${args.paymentMethod})`,
      createdAt: now,
    });

    return {
      saleId,
      saleNumber,
      efrisFiscalCode,
      efrisQrCodeData,
      balance,
    };
  },
});

// Void / Cancel Sale
export const voidSale = mutation({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    saleId: v.id("sales"),
    pin: v.string(),
  },
  handler: async (ctx, args) => {
    const user = await verifyUserBusinessAccess(ctx, args.userId, args.businessId, "can_void_sale");

    const sale = await ctx.db.get(args.saleId);
    if (!sale || sale.businessId !== args.businessId) {
      throw new Error("Sale not found");
    }

    if (sale.status === "voided") {
      throw new Error("Sale is already voided");
    }

    const now = Date.now();

    // 1. Mark sale as voided
    await ctx.db.patch(args.saleId, {
      status: "voided",
    });

    // 2. Restore inventory stock counts
    const saleItems = await ctx.db
      .query("saleItems")
      .withIndex("by_sale", (q) => q.eq("saleId", args.saleId))
      .collect();

    for (const item of saleItems) {
      const product = await ctx.db.get(item.productId);
      if (product) {
        const next = product.stockQuantity + item.quantity;
        await ctx.db.patch(item.productId, {
          stockQuantity: next,
          updatedAt: now,
        });

        await ctx.db.insert("stockMovements", {
          businessId: args.businessId,
          productId: item.productId,
          deltaQuantity: item.quantity,
          previousStock: product.stockQuantity,
          newStock: next,
          reason: "return",
          referenceId: args.saleId,
          deviceId: "system-void",
          createdBy: args.userId,
          createdAt: now,
        });
      }
    }

    // 3. Revert customer debt if applicable
    if (sale.customerId && sale.balance > 0) {
      const customer = await ctx.db.get(sale.customerId);
      if (customer) {
        await ctx.db.patch(sale.customerId, {
          currentDebt: Math.max(0, customer.currentDebt - sale.balance),
          updatedAt: now,
        });
      }
    }

    // 4. Audit Log
    await ctx.db.insert("auditLogs", {
      businessId: args.businessId,
      userId: args.userId,
      userName: user.fullName,
      action: "SALE_CANCELLED",
      entityType: "sale",
      entityId: args.saleId,
      deviceId: "system",
      details: `Voided sale ${sale.saleNumber} (UGX ${sale.total.toLocaleString()}) and restored inventory`,
      createdAt: now,
    });

    return { success: true };
  },
});

// List Sales with Filters
export const listSales = query({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    return await ctx.db
      .query("sales")
      .withIndex("by_business_and_created", (q) => q.eq("businessId", args.businessId))
      .order("desc")
      .take(args.limit ?? 50);
  },
});
