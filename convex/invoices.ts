import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { verifyUserBusinessAccess } from "./auth";

// Create / Issue Invoice
export const createInvoice = mutation({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    customerId: v.id("customers"),
    saleId: v.optional(v.id("sales")),
    totalAmount: v.number(),
    paidAmount: v.number(),
    dueDate: v.number(),
    notes: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    const now = Date.now();
    const currentYear = new Date().getFullYear();

    // Get count of existing invoices this year for sequential numbering
    const existingInvoices = await ctx.db
      .query("invoices")
      .withIndex("by_business", (q) => q.eq("businessId", args.businessId))
      .collect();

    const count = existingInvoices.length + 1;
    const seq = count.toString().padStart(6, "0");
    const invoiceNumber = `DUKA-${currentYear}-${seq}`;

    const dueAmount = Math.max(0, args.totalAmount - args.paidAmount);
    const status = dueAmount === 0 ? "paid" : args.paidAmount > 0 ? "partial" : "issued";

    const invoiceId = await ctx.db.insert("invoices", {
      businessId: args.businessId,
      invoiceNumber,
      saleId: args.saleId,
      customerId: args.customerId,
      totalAmount: args.totalAmount,
      paidAmount: args.paidAmount,
      dueAmount,
      issueDate: now,
      dueDate: args.dueDate,
      status,
      notes: args.notes,
      createdAt: now,
    });

    return {
      invoiceId,
      invoiceNumber,
      dueAmount,
      status,
    };
  },
});

// List Invoices
export const listInvoices = query({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    status: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    let invoices = await ctx.db
      .query("invoices")
      .withIndex("by_business", (q) => q.eq("businessId", args.businessId))
      .order("desc")
      .take(50);

    if (args.status && args.status !== "all") {
      invoices = invoices.filter((inv) => inv.status === args.status);
    }

    const invoicesWithCustomer = await Promise.all(
      invoices.map(async (inv) => {
        const customer = await ctx.db.get(inv.customerId);
        return {
          ...inv,
          customerName: customer?.name ?? "Customer",
          customerPhone: customer?.phone ?? "",
        };
      })
    );

    return invoicesWithCustomer;
  },
});
