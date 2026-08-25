import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

// Record Expense or Custom Income
export const recordTransaction = mutation({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    type: v.union(v.literal("income"), v.literal("expense")),
    category: v.string(), // "transport", "market_rent", "salary", "airtime", "fuel", "stock_purchase", "utilities", "lunch", "other"
    amount: v.number(),
    paymentMethod: v.union(v.literal("cash"), v.literal("mtn_momo"), v.literal("airtel_money"), v.literal("bank")),
    reference: v.optional(v.string()),
    receiptImageStorageId: v.optional(v.id("_storage")),
    notes: v.optional(v.string()),
    isRecurring: v.boolean(),
    recurringFrequency: v.optional(v.union(v.literal("daily"), v.literal("weekly"), v.literal("monthly"))),
    date: v.optional(v.number()),
    deviceId: v.string(),
  },
  handler: async (ctx, args) => {
    const now = args.date ?? Date.now();

    const transactionId = await ctx.db.insert("transactions", {
      businessId: args.businessId,
      type: args.type,
      category: args.category,
      amount: args.amount,
      paymentMethod: args.paymentMethod,
      reference: args.reference,
      receiptImageStorageId: args.receiptImageStorageId,
      notes: args.notes,
      isRecurring: args.isRecurring,
      recurringFrequency: args.recurringFrequency,
      date: now,
      deviceId: args.deviceId,
      createdBy: args.userId,
      createdAt: Date.now(),
    });

    return transactionId;
  },
});

// List Transactions with Date Range & Category Filter
export const listTransactions = query({
  args: {
    businessId: v.id("businesses"),
    type: v.optional(v.union(v.literal("income"), v.literal("expense"))),
    startDate: v.optional(v.number()),
    endDate: v.optional(v.number()),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    let items = await ctx.db
      .query("transactions")
      .withIndex("by_business_and_date", (q) => q.eq("businessId", args.businessId))
      .order("desc")
      .take(args.limit ?? 100);

    if (args.type) {
      items = items.filter((t) => t.type === args.type);
    }
    if (args.startDate) {
      items = items.filter((t) => t.date >= args.startDate!);
    }
    if (args.endDate) {
      items = items.filter((t) => t.date <= args.endDate!);
    }

    return items;
  },
});

// Daily Cashbook Summary
export const getDailyCashbookSummary = query({
  args: {
    businessId: v.id("businesses"),
    dayTimestamp: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const targetDate = args.dayTimestamp ? new Date(args.dayTimestamp) : new Date();
    targetDate.setHours(0, 0, 0, 0);
    const startOfDay = targetDate.getTime();
    const endOfDay = startOfDay + 24 * 60 * 60 * 1000;

    const txs = await ctx.db
      .query("transactions")
      .withIndex("by_business_and_date", (q) => q.eq("businessId", args.businessId))
      .collect();

    const dayTxs = txs.filter((t) => t.date >= startOfDay && t.date < endOfDay);

    let totalIncome = 0;
    let totalExpense = 0;
    let cashBalance = 0;
    let momoBalance = 0;
    let airtelBalance = 0;
    let bankBalance = 0;

    const categoryBreakdown: Record<string, number> = {};

    for (const t of dayTxs) {
      const delta = t.type === "income" ? t.amount : -t.amount;
      if (t.type === "income") {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
        categoryBreakdown[t.category] = (categoryBreakdown[t.category] ?? 0) + t.amount;
      }

      if (t.paymentMethod === "cash") cashBalance += delta;
      else if (t.paymentMethod === "mtn_momo") momoBalance += delta;
      else if (t.paymentMethod === "airtel_money") airtelBalance += delta;
      else if (t.paymentMethod === "bank") bankBalance += delta;
    }

    return {
      date: startOfDay,
      totalIncome,
      totalExpense,
      netCashFlow: totalIncome - totalExpense,
      byPaymentMethod: {
        cash: cashBalance,
        mtn_momo: momoBalance,
        airtel_money: airtelBalance,
        bank: bankBalance,
      },
      categoryBreakdown,
      transactionCount: dayTxs.length,
    };
  },
});
