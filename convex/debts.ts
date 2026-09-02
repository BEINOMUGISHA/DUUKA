import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { verifyUserBusinessAccess } from "./auth";

// Debt dashboard summary
export const getDebtSummary = query({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    const now = Date.now();
    const todayEnd = new Date().setHours(23, 59, 59, 999);
    const weekEnd = now + 7 * 24 * 60 * 60 * 1000;
    const monthStart = new Date(new Date().getFullYear(), new Date().getMonth(), 1).getTime();

    const debts = await ctx.db
      .query("debts")
      .withIndex("by_business", (q) => q.eq("businessId", args.businessId))
      .collect();

    const activeDebts = debts.filter((d) => d.status === "active" || d.status === "partially_paid" || d.status === "overdue");

    let totalDebt = 0;
    let dueToday = 0;
    let dueThisWeek = 0;
    let overdue = 0;

    for (const d of activeDebts) {
      totalDebt += d.balance;
      if (d.dueDate < now) {
        overdue += d.balance;
      } else if (d.dueDate <= todayEnd) {
        dueToday += d.balance;
      } else if (d.dueDate <= weekEnd) {
        dueThisWeek += d.balance;
      }
    }

    // Paid this month
    const payments = await ctx.db
      .query("payments")
      .withIndex("by_business_and_created", (q) => q.eq("businessId", args.businessId))
      .collect();

    const paidThisMonth = payments
      .filter((p) => (p.entityType === "debt" || p.entityType === "customer_credit") && p.createdAt >= monthStart)
      .reduce((sum, p) => sum + p.amount, 0);

    return {
      totalDebt,
      dueToday,
      dueThisWeek,
      overdue,
      paidThisMonth,
      activeDebtorsCount: activeDebts.length,
    };
  },
});

// List debts
export const listDebts = query({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    status: v.optional(v.string()),
    customerId: v.optional(v.id("customers")),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    let debtsQuery = ctx.db
      .query("debts")
      .withIndex("by_business", (q) => q.eq("businessId", args.businessId));

    let debts = await debtsQuery.collect();

    if (args.customerId) {
      debts = debts.filter((d) => d.customerId === args.customerId);
    }

    if (args.status && args.status !== "all") {
      debts = debts.filter((d) => d.status === args.status);
    }

    // Attach customer names
    const debtsWithCustomer = await Promise.all(
      debts.map(async (d) => {
        const customer = await ctx.db.get(d.customerId);
        return {
          ...d,
          customerName: customer?.name ?? "Unknown Customer",
          customerPhone: customer?.phone ?? "",
        };
      })
    );

    return debtsWithCustomer.sort((a, b) => b.balance - a.balance);
  },
});

// Record Debt Repayment
export const recordDebtPayment = mutation({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    debtId: v.id("debts"),
    amount: v.number(),
    paymentMethod: v.union(v.literal("cash"), v.literal("mtn_momo"), v.literal("airtel_money"), v.literal("bank")),
    reference: v.optional(v.string()),
    notes: v.optional(v.string()),
    deviceId: v.string(),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    const debt = await ctx.db.get(args.debtId);
    if (!debt || debt.businessId !== args.businessId) {
      throw new Error("Debt record not found");
    }

    if (args.amount <= 0) {
      throw new Error("Payment amount must be greater than 0");
    }

    const customer = await ctx.db.get(debt.customerId);
    if (!customer) {
      throw new Error("Customer not found");
    }

    const now = Date.now();
    const newPaid = debt.amountPaid + args.amount;
    const newBalance = Math.max(0, debt.originalAmount - newPaid);
    const newStatus = newBalance === 0 ? "paid" : "partially_paid";

    // 1. Update debt record
    await ctx.db.patch(args.debtId, {
      amountPaid: newPaid,
      balance: newBalance,
      status: newStatus,
      updatedAt: now,
    });

    // 2. Update customer overall currentDebt
    const newCustomerDebt = Math.max(0, customer.currentDebt - args.amount);
    await ctx.db.patch(debt.customerId, {
      currentDebt: newCustomerDebt,
      updatedAt: now,
    });

    // 3. Update associated sale if present
    if (debt.saleId) {
      const sale = await ctx.db.get(debt.saleId);
      if (sale) {
        const salePaid = sale.amountPaid + args.amount;
        const saleBalance = Math.max(0, sale.total - salePaid);
        await ctx.db.patch(debt.saleId, {
          amountPaid: salePaid,
          balance: saleBalance,
        });
      }
    }

    // 4. Generate Receipt
    const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, "");
    const receiptNumber = `RCP-${dateStr}-${Math.floor(1000 + Math.random() * 9000)}`;

    const paymentId = await ctx.db.insert("payments", {
      businessId: args.businessId,
      receiptNumber,
      entityType: "debt",
      entityId: args.debtId,
      customerId: debt.customerId,
      amount: args.amount,
      paymentMethod: args.paymentMethod,
      reference: args.reference,
      notes: args.notes ?? `Debt repayment by ${customer.name}`,
      receivedBy: args.userId,
      deviceId: args.deviceId,
      createdAt: now,
    });

    // 5. Record in Daily Cashbook
    await ctx.db.insert("transactions", {
      businessId: args.businessId,
      type: "income",
      category: "debt_collection",
      amount: args.amount,
      paymentMethod: args.paymentMethod,
      reference: args.reference,
      notes: `Debt repayment from ${customer.name} (${receiptNumber})`,
      isRecurring: false,
      date: now,
      deviceId: args.deviceId,
      createdBy: args.userId,
      createdAt: now,
    });

    // 6. Audit Log
    const user = await ctx.db.get(args.userId);
    await ctx.db.insert("auditLogs", {
      businessId: args.businessId,
      userId: args.userId,
      userName: user?.fullName ?? "Staff",
      action: "DEBT_PAYMENT",
      entityType: "debt",
      entityId: args.debtId,
      deviceId: args.deviceId,
      details: `Recorded UGX ${args.amount} repayment from ${customer.name}. Remaining debt: UGX ${newBalance}`,
      createdAt: now,
    });

    return {
      paymentId,
      receiptNumber,
      previousBalance: debt.balance,
      newBalance,
      isFullyPaid: newBalance === 0,
    };
  },
});
