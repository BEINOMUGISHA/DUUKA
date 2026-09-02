import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

// List all customers with balances
export const listCustomers = query({
  args: {
    businessId: v.id("businesses"),
    onlyDebtors: v.optional(v.boolean()),
  },
  handler: async (ctx, args) => {
    let customers = await ctx.db
      .query("customers")
      .withIndex("by_business", (q) => q.eq("businessId", args.businessId))
      .collect();

    if (args.onlyDebtors) {
      customers = customers.filter((c) => c.currentDebt > 0);
    }

    return customers.sort((a, b) => b.currentDebt - a.currentDebt);
  },
});

// Create Customer
export const createCustomer = mutation({
  args: {
    businessId: v.id("businesses"),
    name: v.string(),
    phone: v.string(),
    email: v.optional(v.string()),
    address: v.optional(v.string()),
    creditLimit: v.number(),
    initialBalance: v.optional(v.number()),
    notes: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const balance = args.initialBalance ?? 0;

    return await ctx.db.insert("customers", {
      businessId: args.businessId,
      name: args.name,
      phone: args.phone,
      email: args.email,
      address: args.address,
      creditLimit: args.creditLimit,
      currentDebt: balance,
      notes: args.notes,
      createdAt: now,
      updatedAt: now,
    });
  },
});

// Record Debtor Payment (Repayment of Credit)
export const recordCustomerPayment = mutation({
  args: {
    businessId: v.id("businesses"),
    customerId: v.id("customers"),
    userId: v.id("users"),
    amount: v.number(),
    paymentMethod: v.union(v.literal("cash"), v.literal("mtn_momo"), v.literal("airtel_money"), v.literal("bank")),
    reference: v.optional(v.string()),
    notes: v.optional(v.string()),
    deviceId: v.string(),
  },
  handler: async (ctx, args) => {
    const customer = await ctx.db.get(args.customerId);
    if (!customer || customer.businessId !== args.businessId) {
      throw new Error("Customer not found");
    }

    const now = Date.now();
    const newBalance = Math.max(0, customer.currentDebt - args.amount);

    // Update customer balance
    await ctx.db.patch(args.customerId, {
      currentDebt: newBalance,
      updatedAt: now,
    });

    const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, "");
    const receiptNumber = `RCP-${dateStr}-${Math.floor(1000 + Math.random() * 9000)}`;

    // Insert payment record
    const paymentId = await ctx.db.insert("payments", {
      businessId: args.businessId,
      receiptNumber,
      entityType: "customer_credit",
      entityId: args.customerId,
      customerId: args.customerId,
      amount: args.amount,
      paymentMethod: args.paymentMethod,
      reference: args.reference,
      notes: args.notes ?? `Credit Repayment by ${customer.name}`,
      receivedBy: args.userId,
      deviceId: args.deviceId,
      createdAt: now,
    });

    // Record in Daily Cashbook as Income
    await ctx.db.insert("transactions", {
      businessId: args.businessId,
      type: "income",
      category: "credit_recovery",
      amount: args.amount,
      paymentMethod: args.paymentMethod,
      reference: args.reference,
      notes: `Credit repayment from ${customer.name} (${receiptNumber})`,
      isRecurring: false,
      date: now,
      deviceId: args.deviceId,
      createdBy: args.userId,
      createdAt: now,
    });

    return {
      paymentId,
      receiptNumber,
      previousBalance: customer.currentDebt,
      newBalance,
    };
  },
});

// Generate Debtor SMS Reminder Template
export const getDebtorSmsReminder = query({
  args: {
    businessId: v.id("businesses"),
    customerId: v.id("customers"),
    language: v.optional(v.union(v.literal("en"), v.literal("lg"), v.literal("rn"))),
  },
  handler: async (ctx, args) => {
    const customer = await ctx.db.get(args.customerId);
    const business = await ctx.db.get(args.businessId);

    if (!customer || !business) {
      throw new Error("Customer or Business not found");
    }

    const lang = args.language ?? "en";
    const amountStr = `UGX ${customer.currentDebt.toLocaleString()}`;
    const businessName = business.name;

    if (lang === "lg") {
      // Luganda
      return {
        phone: customer.phone,
        message: `Nkulamusizza ${customer.name}, eno ye ${businessName}. Tukujjukizaako ebbanja lyo erya ${amountStr}. Osobola okusasula ku MTN MoMo oba Airtel Money. Weebale nnyo!`,
      };
    } else if (lang === "rn") {
      // Runyankole
      return {
        phone: customer.phone,
        message: `Agandi ${customer.name}, oku niyo ${businessName}. Nitukwijutsya omwenda gwaawe gwa ${amountStr}. Noobaasa kushashura na MTN MoMo nari Airtel Money. Webare munonga!`,
      };
    }

    // Default English
    return {
      phone: customer.phone,
      message: `Dear ${customer.name}, warm greetings from ${businessName}. This is a friendly reminder regarding your outstanding balance of ${amountStr}. You can pay via MTN MoMo, Airtel Money, or cash. Thank you for your business!`,
    };
  },
});
