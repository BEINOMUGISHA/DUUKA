import { query } from "./_generated/server";
import { v } from "convex/values";
import { verifyUserBusinessAccess } from "./auth";

// Business Performance & P&L Report
export const getProfitAndLossReport = query({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    startDate: v.number(),
    endDate: v.number(),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    const sales = await ctx.db
      .query("sales")
      .withIndex("by_business_and_created", (q) => q.eq("businessId", args.businessId))
      .collect();

    const rangeSales = sales.filter((s) => s.status !== "voided" && s.createdAt >= args.startDate && s.createdAt <= args.endDate);

    let grossRevenue = 0;
    let totalTax = 0;
    let totalDiscounts = 0;
    let cashSales = 0;
    let momoSales = 0;
    let airtelSales = 0;
    let bankSales = 0;
    let creditSales = 0;

    for (const sale of rangeSales) {
      grossRevenue += sale.total;
      totalTax += sale.tax;
      totalDiscounts += sale.discount;

      if (sale.paymentMethod === "cash") cashSales += sale.amountPaid;
      else if (sale.paymentMethod === "mtn_momo") momoSales += sale.amountPaid;
      else if (sale.paymentMethod === "airtel_money") airtelSales += sale.amountPaid;
      else if (sale.paymentMethod === "bank") bankSales += sale.amountPaid;
      if (sale.balance > 0) creditSales += sale.balance;
    }

    // Operating expenses (excluding stock purchases)
    const txs = await ctx.db
      .query("transactions")
      .withIndex("by_business_and_date", (q) => q.eq("businessId", args.businessId))
      .collect();

    const rangeExpenses = txs.filter(
      (t) => t.type === "expense" && t.date >= args.startDate && t.date <= args.endDate && t.category !== "stock_purchase"
    );

    let totalOperatingExpenses = 0;
    const expenseBreakdown: Record<string, number> = {};

    for (const exp of rangeExpenses) {
      totalOperatingExpenses += exp.amount;
      expenseBreakdown[exp.category] = (expenseBreakdown[exp.category] ?? 0) + exp.amount;
    }

    // Approximate COGS: 70% of revenue if not tracked per line item
    const costOfGoodsSold = grossRevenue * 0.70;
    const grossProfit = grossRevenue - costOfGoodsSold;
    const netProfit = grossProfit - totalOperatingExpenses;
    const profitMargin = grossRevenue > 0 ? (netProfit / grossRevenue) * 100 : 0;

    return {
      period: {
        startDate: args.startDate,
        endDate: args.endDate,
      },
      summary: {
        grossRevenue,
        costOfGoodsSold,
        grossProfit,
        totalOperatingExpenses,
        netProfit,
        profitMargin: Math.round(profitMargin * 10) / 10,
        totalTaxCollected: totalTax,
        totalDiscounts,
      },
      paymentBreakdown: {
        cash: cashSales,
        mtn_momo: momoSales,
        airtel_money: airtelSales,
        bank: bankSales,
        credit: creditSales,
      },
      expenseBreakdown,
    };
  },
});

// Stock Valuation
export const getStockValuation = query({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    const products = await ctx.db
      .query("products")
      .withIndex("by_business", (q) => q.eq("businessId", args.businessId))
      .collect();

    const active = products.filter((p) => !p.isArchived);

    let totalCostValuation = 0;
    let totalRetailValuation = 0;
    let lowStockCount = 0;

    for (const p of active) {
      totalCostValuation += p.costPrice * p.stockQuantity;
      totalRetailValuation += p.sellingPrice * p.stockQuantity;
      if (p.stockQuantity <= p.lowStockThreshold) lowStockCount++;
    }

    return {
      totalProductsCount: active.length,
      totalCostValuation,
      totalRetailValuation,
      potentialProfit: totalRetailValuation - totalCostValuation,
      lowStockCount,
    };
  },
});
