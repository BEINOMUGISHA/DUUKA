import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { normalizeUgandaPhone, verifyUserBusinessAccess } from "./auth";

// List all customers for a business
export const listCustomers = query({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    search: v.optional(v.string()),
    onlyDebtors: v.optional(v.boolean()),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    let customers = await ctx.db
      .query("customers")
      .withIndex("by_business", (q) => q.eq("businessId", args.businessId))
      .collect();

    customers = customers.filter((c) => !c.isArchived);

    if (args.onlyDebtors) {
      customers = customers.filter((c) => c.currentDebt > 0);
    }

    if (args.search && args.search.trim().length > 0) {
      const q = args.search.toLowerCase().trim();
      customers = customers.filter(
        (c) =>
          c.name.toLowerCase().includes(q) ||
          c.phone.includes(q) ||
          (c.address && c.address.toLowerCase().includes(q))
      );
    }

    return customers.sort((a, b) => b.currentDebt - a.currentDebt);
  },
});

// Get comprehensive customer details
export const getCustomerDetails = query({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    customerId: v.id("customers"),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    const customer = await ctx.db.get(args.customerId);
    if (!customer || customer.businessId !== args.businessId) {
      throw new Error("Customer not found");
    }

    // Customer sales history
    const sales = await ctx.db
      .query("sales")
      .withIndex("by_customer", (q) => q.eq("customerId", args.customerId))
      .order("desc")
      .take(20);

    // Customer payment history
    const payments = await ctx.db
      .query("payments")
      .withIndex("by_customer", (q) => q.eq("customerId", args.customerId))
      .order("desc")
      .take(20);

    // Customer SMS history
    const sms = await ctx.db
      .query("smsMessages")
      .withIndex("by_customer", (q) => q.eq("customerId", args.customerId))
      .order("desc")
      .take(20);

    // Active debts
    const debts = await ctx.db
      .query("debts")
      .withIndex("by_customer", (q) => q.eq("customerId", args.customerId))
      .order("desc")
      .take(20);

    return {
      customer,
      sales,
      payments,
      sms,
      debts,
    };
  },
});

// Create Customer
export const createCustomer = mutation({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    name: v.string(),
    phone: v.string(),
    email: v.optional(v.string()),
    address: v.optional(v.string()),
    creditLimit: v.number(),
    initialDebt: v.optional(v.number()),
    notes: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    const now = Date.now();
    const normalizedPhone = normalizeUgandaPhone(args.phone);
    const initialDebt = args.initialDebt ?? 0;

    const customerId = await ctx.db.insert("customers", {
      businessId: args.businessId,
      name: args.name.trim(),
      phone: normalizedPhone,
      email: args.email?.trim(),
      address: args.address?.trim(),
      creditLimit: args.creditLimit,
      currentDebt: initialDebt,
      notes: args.notes?.trim(),
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    });

    if (initialDebt > 0) {
      await ctx.db.insert("debts", {
        businessId: args.businessId,
        customerId,
        originalAmount: initialDebt,
        amountPaid: 0,
        balance: initialDebt,
        dueDate: now + 14 * 24 * 60 * 60 * 1000, // 14 days default
        status: "active",
        notes: "Initial balance brought forward",
        createdAt: now,
        updatedAt: now,
      });
    }

    return customerId;
  },
});

// Update Customer
export const updateCustomer = mutation({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    customerId: v.id("customers"),
    name: v.string(),
    phone: v.string(),
    email: v.optional(v.string()),
    address: v.optional(v.string()),
    creditLimit: v.number(),
    notes: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    const customer = await ctx.db.get(args.customerId);
    if (!customer || customer.businessId !== args.businessId) {
      throw new Error("Customer not found");
    }

    const normalizedPhone = normalizeUgandaPhone(args.phone);

    await ctx.db.patch(args.customerId, {
      name: args.name.trim(),
      phone: normalizedPhone,
      email: args.email?.trim(),
      address: args.address?.trim(),
      creditLimit: args.creditLimit,
      notes: args.notes?.trim(),
      updatedAt: Date.now(),
    });
  },
});

// Archive Customer
export const archiveCustomer = mutation({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    customerId: v.id("customers"),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    const customer = await ctx.db.get(args.customerId);
    if (!customer || customer.businessId !== args.businessId) {
      throw new Error("Customer not found");
    }

    await ctx.db.patch(args.customerId, {
      isArchived: true,
      updatedAt: Date.now(),
    });
  },
});
