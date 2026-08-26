import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { verifyUserBusinessAccess } from "./auth";

// List all active products
export const listProducts = query({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    category: v.optional(v.string()),
    search: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    let products = await ctx.db
      .query("products")
      .withIndex("by_business", (q) => q.eq("businessId", args.businessId))
      .collect();

    products = products.filter((p) => !p.isArchived);

    if (args.category && args.category !== "All") {
      products = products.filter((p) => p.category === args.category);
    }

    if (args.search && args.search.trim().length > 0) {
      const q = args.search.toLowerCase().trim();
      products = products.filter(
        (p) =>
          p.name.toLowerCase().includes(q) ||
          (p.sku && p.sku.toLowerCase().includes(q)) ||
          (p.barcode && p.barcode.includes(q))
      );
    }

    return products.sort((a, b) => a.name.localeCompare(b.name));
  },
});

// Create product
export const createProduct = mutation({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    name: v.string(),
    sku: v.optional(v.string()),
    barcode: v.optional(v.string()),
    category: v.string(),
    costPrice: v.number(),
    sellingPrice: v.number(),
    initialStock: v.number(),
    lowStockThreshold: v.number(),
    unit: v.string(),
    isTaxable: v.optional(v.boolean()),
    taxRate: v.optional(v.number()),
    deviceId: v.string(),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    const now = Date.now();
    const productId = await ctx.db.insert("products", {
      businessId: args.businessId,
      name: args.name.trim(),
      sku: args.sku?.trim(),
      barcode: args.barcode?.trim(),
      category: args.category.trim(),
      costPrice: args.costPrice,
      sellingPrice: args.sellingPrice,
      stockQuantity: args.initialStock,
      lowStockThreshold: args.lowStockThreshold,
      unit: args.unit.trim(),
      isTaxable: args.isTaxable ?? true,
      taxRate: args.taxRate ?? 0.18,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    });

    if (args.initialStock > 0) {
      await ctx.db.insert("stockMovements", {
        businessId: args.businessId,
        productId,
        deltaQuantity: args.initialStock,
        previousStock: 0,
        newStock: args.initialStock,
        reason: "restock",
        deviceId: args.deviceId,
        createdBy: args.userId,
        createdAt: now,
      });
    }

    const user = await ctx.db.get(args.userId);
    await ctx.db.insert("auditLogs", {
      businessId: args.businessId,
      userId: args.userId,
      userName: user?.fullName ?? "Staff",
      action: "PRODUCT_CREATED",
      entityType: "product",
      entityId: productId,
      deviceId: args.deviceId,
      details: `Created product "${args.name}" (Stock: ${args.initialStock} ${args.unit})`,
      createdAt: now,
    });

    return productId;
  },
});

// Update product
export const updateProduct = mutation({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    productId: v.id("products"),
    name: v.string(),
    sku: v.optional(v.string()),
    barcode: v.optional(v.string()),
    category: v.string(),
    costPrice: v.number(),
    sellingPrice: v.number(),
    lowStockThreshold: v.number(),
    unit: v.string(),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    const product = await ctx.db.get(args.productId);
    if (!product || product.businessId !== args.businessId) {
      throw new Error("Product not found");
    }

    await ctx.db.patch(args.productId, {
      name: args.name.trim(),
      sku: args.sku?.trim(),
      barcode: args.barcode?.trim(),
      category: args.category.trim(),
      costPrice: args.costPrice,
      sellingPrice: args.sellingPrice,
      lowStockThreshold: args.lowStockThreshold,
      unit: args.unit.trim(),
      updatedAt: Date.now(),
    });
  },
});

// Restock product (GRN / Goods Received Note)
export const restockProduct = mutation({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    productId: v.id("products"),
    quantityReceived: v.number(),
    costPerUnit: v.number(),
    supplierName: v.optional(v.string()),
    notes: v.optional(v.string()),
    deviceId: v.string(),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    const product = await ctx.db.get(args.productId);
    if (!product || product.businessId !== args.businessId) {
      throw new Error("Product not found");
    }

    const prev = product.stockQuantity;
    const next = prev + args.quantityReceived;
    const now = Date.now();

    await ctx.db.patch(args.productId, {
      stockQuantity: next,
      costPrice: args.costPerUnit,
      updatedAt: now,
    });

    const movementId = await ctx.db.insert("stockMovements", {
      businessId: args.businessId,
      productId: args.productId,
      deltaQuantity: args.quantityReceived,
      previousStock: prev,
      newStock: next,
      reason: "restock",
      supplierName: args.supplierName,
      costPerUnit: args.costPerUnit,
      notes: args.notes,
      deviceId: args.deviceId,
      createdBy: args.userId,
      createdAt: now,
    });

    // Record stock purchase expense in cashbook
    const totalCost = args.quantityReceived * args.costPerUnit;
    await ctx.db.insert("transactions", {
      businessId: args.businessId,
      type: "expense",
      category: "stock_purchase",
      amount: totalCost,
      paymentMethod: "cash",
      notes: `Restocked ${args.quantityReceived} ${product.unit} of ${product.name} (Supplier: ${args.supplierName ?? "General"})`,
      isRecurring: false,
      date: now,
      deviceId: args.deviceId,
      createdBy: args.userId,
      createdAt: now,
    });

    return { movementId, newStock: next };
  },
});

// Archive Product
export const archiveProduct = mutation({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    productId: v.id("products"),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    const product = await ctx.db.get(args.productId);
    if (!product || product.businessId !== args.businessId) {
      throw new Error("Product not found");
    }

    await ctx.db.patch(args.productId, {
      isArchived: true,
      updatedAt: Date.now(),
    });
  },
});
