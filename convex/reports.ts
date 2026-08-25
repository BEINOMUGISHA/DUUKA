import { query } from "./_generated/server";
import { v } from "convex/values";

// Business Performance & P&L Report
export const getProfitAndLossReport = query({
  args: {
    businessId: v.id("businesses"),
    startDate: v.number(),
    endDate: v.number(),
  },
  handler: async (ctx, args) => {
    // 1. Fetch sales in date range
    const sales = await ctx.db
      .query("sales")
      .withIndex("by_business_and_created", (q) => q.eq("businessId", args.businessId))
      .collect();

    const rangeSales = sales.filter((s) => s.createdAt >= args.startDate && s.createdAt <= args.endDate);

    let grossRevenue = 0;
    let costOfGoodsSold = 0;
    let totalTaxCollected = 0;
    let totalDiscounts = 0;
    let cashSales = 0;
    let momoSales = 0;
    let airtelSales = 0;
    let bankSales = 0;
    let creditSales = 0;

    const productPerformance: Record<string, { name: string; qty: number; revenue: number; profit: number }> = {};

    for (const sale of rangeSales) {
      grossRevenue += sale.totalAmount;
      totalTaxCollected += sale.taxAmount;
      totalDiscounts += sale.discountAmount;

      if (sale.paymentMethod === "cash") cashSales += sale.paidAmount;
      else if (sale.paymentMethod === "mtn_momo") momoSales += sale.paidAmount;
      else if (sale.paymentMethod === "airtel_money") airtelSales += sale.paidAmount;
      else if (sale.paymentMethod === "bank") bankSales += sale.paidAmount;
      if (sale.isCredit) creditSales += sale.dueAmount;

      for (const item of sale.items) {
        const itemCogs = (item.costPrice ?? 0) * item.quantity;
        costOfGoodsSold += itemCogs;
        const itemProfit = item.subtotal - itemCogs;

        if (!productPerformance[item.productId]) {
          productPerformance[item.productId] = {
            name: item.productName,
            qty: 0,
            revenue: 0,
            profit: 0,
          };
        }
        productPerformance[item.productId].qty += item.quantity;
        productPerformance[item.productId].revenue += item.subtotal;
        productPerformance[item.productId].profit += itemProfit;
      }
    }

    const grossProfit = grossRevenue - costOfGoodsSold;

    // 2. Fetch Operating Expenses
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

    const netProfit = grossProfit - totalOperatingExpenses;
    const profitMargin = grossRevenue > 0 ? (netProfit / grossRevenue) * 100 : 0;

    // Top selling products sorted by revenue
    const topProducts = Object.values(productPerformance)
      .sort((a, b) => b.revenue - a.revenue)
      .slice(0, 10);

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
        totalTaxCollected,
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
      topProducts,
    };
  },
});

// Stock Valuation & Inventory Health Report
export const getStockValuationReport = query({
  args: {
    businessId: v.id("businesses"),
  },
  handler: async (ctx, args) => {
    const products = await ctx.db
      .query("products")
      .withIndex("by_business", (q) => q.eq("businessId", args.businessId))
      .collect();

    const activeProducts = products.filter((p) => !p.isArchived);

    let totalCostValuation = 0;
    let totalRetailValuation = 0;
    let lowStockCount = 0;
    let outOfStockCount = 0;

    for (const p of activeProducts) {
      totalCostValuation += p.costPrice * p.currentStock;
      totalRetailValuation += p.sellPrice * p.currentStock;
      if (p.currentStock === 0) outOfStockCount++;
      else if (p.currentStock <= p.minStockLevel) lowStockCount++;
    }

    return {
      totalProductsCount: activeProducts.length,
      totalCostValuation,
      totalRetailValuation,
      potentialProfit: totalRetailValuation - totalCostValuation,
      lowStockCount,
      outOfStockCount,
    };
  },
});
