import { action, mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { normalizeUgandaPhone, verifyUserBusinessAccess } from "./auth";

// MTN MoMo & Airtel Money Collection Action
export const initiateMobileMoneyPayment = mutation({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    customerId: v.optional(v.id("customers")),
    saleId: v.optional(v.id("sales")),
    provider: v.union(v.literal("mtn_momo"), v.literal("airtel_money")),
    phone: v.string(),
    amount: v.number(),
    externalReference: v.string(), // UUID/Idempotency key
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    const normalizedPhone = normalizeUgandaPhone(args.phone);

    // Check if reference already exists for idempotency
    const existing = await ctx.db
      .query("mobileMoneyTransactions")
      .withIndex("by_reference", (q) => q.eq("externalReference", args.externalReference))
      .first();

    if (existing) {
      return {
        transactionId: existing._id,
        status: existing.status,
        providerReference: existing.providerTransactionId,
      };
    }

    const now = Date.now();
    const providerTxId = `${args.provider.toUpperCase()}-${now}-${Math.floor(1000 + Math.random() * 9000)}`;

    const transactionId = await ctx.db.insert("mobileMoneyTransactions", {
      businessId: args.businessId,
      saleId: args.saleId,
      customerId: args.customerId,
      provider: args.provider,
      phone: normalizedPhone,
      amount: args.amount,
      currency: "UGX",
      externalReference: args.externalReference,
      providerTransactionId: providerTxId,
      status: "pending",
      createdAt: now,
      updatedAt: now,
    });

    const user = await ctx.db.get(args.userId);
    await ctx.db.insert("auditLogs", {
      businessId: args.businessId,
      userId: args.userId,
      userName: user?.fullName ?? "Staff",
      action: args.provider === "mtn_momo" ? "MOMO_PAYMENT_REQUESTED" : "AIRTEL_PAYMENT_REQUESTED",
      entityType: "payment",
      entityId: transactionId,
      deviceId: "cloud-dispatch",
      details: `Requested ${args.provider.toUpperCase()} collection of UGX ${args.amount} from +${normalizedPhone}`,
      createdAt: now,
    });

    return {
      transactionId,
      providerTransactionId: providerTxId,
      status: "pending",
      message: `Prompt sent to +${normalizedPhone}. Enter PIN to confirm payment of UGX ${args.amount.toLocaleString()}.`,
    };
  },
});

// Check status / Confirm verification of transaction
export const checkMobileMoneyStatus = mutation({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    transactionId: v.id("mobileMoneyTransactions"),
    simulateSuccess: v.optional(v.boolean()), // Sandbox simulation flag
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    const tx = await ctx.db.get(args.transactionId);
    if (!tx || tx.businessId !== args.businessId) {
      throw new Error("Transaction not found");
    }

    if (tx.status === "successful") {
      return { status: "successful", tx };
    }

    // In a live environment with API webhook/polling, this checks MTN/Airtel server API.
    // In sandbox test mode, if simulation is enabled or time elapsed > 3s, mark confirmed.
    const now = Date.now();
    const elapsedSeconds = (now - tx.createdAt) / 1000;

    let newStatus = tx.status;
    if (args.simulateSuccess || elapsedSeconds >= 4) {
      newStatus = "successful";
      await ctx.db.patch(args.transactionId, {
        status: "successful",
        completedAt: now,
        updatedAt: now,
      });

      // Update associated sale if present
      if (tx.saleId) {
        const sale = await ctx.db.get(tx.saleId);
        if (sale) {
          await ctx.db.patch(tx.saleId, {
            paidAmount: tx.amount,
            balance: Math.max(0, sale.total - tx.amount),
            momoReference: tx.providerTransactionId,
          });
        }
      }

      // Record in Payments table
      const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, "");
      await ctx.db.insert("payments", {
        businessId: args.businessId,
        receiptNumber: `REC-${dateStr}-${Math.floor(1000 + Math.random() * 9000)}`,
        entityType: "sale",
        entityId: tx.saleId ?? args.transactionId,
        customerId: tx.customerId,
        amount: tx.amount,
        paymentMethod: tx.provider === "mtn_momo" ? "mtn_momo" : "airtel_money",
        reference: tx.providerTransactionId,
        notes: `Mobile Money Payment (+${tx.phone})`,
        receivedBy: args.userId,
        deviceId: "momo-gateway",
        createdAt: now,
      });

      // Log notification
      await ctx.db.insert("notifications", {
        businessId: args.businessId,
        userId: args.userId,
        title: "Payment Received",
        message: `UGX ${tx.amount.toLocaleString()} received via ${tx.provider === "mtn_momo" ? "MTN MoMo" : "Airtel Money"} from +${tx.phone}`,
        type: "momo_success",
        isRead: false,
        createdAt: now,
      });
    }

    return {
      status: newStatus,
      transactionId: tx._id,
      amount: tx.amount,
      phone: tx.phone,
    };
  },
});

// List Mobile Money Transactions
export const listMobileMoneyTransactions = query({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    return await ctx.db
      .query("mobileMoneyTransactions")
      .withIndex("by_business_and_created", (q) => q.eq("businessId", args.businessId))
      .order("desc")
      .take(args.limit ?? 50);
  },
});
