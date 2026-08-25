import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

// List all active products for a business
export const listProducts = query({
  args: {
    businessId: v.id("businesses"),
    category: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    let productsQuery = ctx.db
      .query("products")
      .withIndex("by_business", (q) => q.eq("businessId", args.businessId));

    const products = await productsQuery.collect();
    return products.filter((p) => !p.isArchived && (!args.category || p.category === args.category));
  },
});

// Get low stock alert products
export const getLowStockAlerts = query({
  args: {
    businessId: v.id("businesses"),
  },
  handler: async (ctx, args) => {
    const products = await ctx.db
      .query("products")
      .withIndex("by_business", (q) => q.eq("businessId", args.businessId))
      .collect();

    return products.filter((p) => !p.isArchived && p.currentStock <= p.minStockLevel);
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
    sellPrice: v.number(),
    initialStock: v.number(),
    minStockLevel: v.number(),
    unit: v.string(),
    isTaxable: v.boolean(),
    taxRate: v.optional(v.number()),
    imageUrl: v.optional(v.string()),
    deviceId: v.string(),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const productId = await ctx.db.insert("products", {
      businessId: args.businessId,
      name: args.name,
      sku: args.sku,
      barcode: args.barcode,
      category: args.category,
      costPrice: args.costPrice,
      sellPrice: args.sellPrice,
      currentStock: args.initialStock,
      minStockLevel: args.minStockLevel,
      unit: args.unit,
      isTaxable: args.isTaxable,
      taxRate: args.taxRate ?? 0.18,
      imageUrl: args.imageUrl,
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
        localTimestamp: now,
        createdBy: args.userId,
        createdAt: now,
      });
    }

    return productId;
  },
});

// Update Product
export const updateProduct = mutation({
  args: {
    businessId: v.id("businesses"),
    productId: v.id("products"),
    name: v.string(),
    sku: v.optional(v.string()),
    category: v.string(),
    costPrice: v.number(),
    sellPrice: v.number(),
    minStockLevel: v.number(),
    unit: v.string(),
    isTaxable: v.boolean(),
    taxRate: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const product = await ctx.db.get(args.productId);
    if (!product || product.businessId !== args.businessId) {
      throw new Error("Product not found");
    }

    await ctx.db.patch(args.productId, {
      name: args.name,
      sku: args.sku,
      category: args.category,
      costPrice: args.costPrice,
      sellPrice: args.sellPrice,
      minStockLevel: args.minStockLevel,
      unit: args.unit,
      isTaxable: args.isTaxable,
      taxRate: args.taxRate ?? 0.18,
      updatedAt: Date.now(),
    });
  },
});

// Apply Delta Stock Movement (Safe for concurrent offline changes)
export const applyStockMovement = mutation({
  args: {
    businessId: v.id("businesses"),
    productId: v.id("products"),
    deltaQuantity: v.number(), // Positive (restock/return) or Negative (sale/damage/loss)
    reason: v.union(
      v.literal("sale"),
      v.literal("purchase"),
      v.literal("restock"),
      v.literal("damage"),
      v.literal("loss"),
      v.literal("adjustment"),
      v.literal("return")
    ),
    referenceId: v.optional(v.string()),
    batchNumber: v.optional(v.string()),
    expiryDate: v.optional(v.number()),
    deviceId: v.string(),
    localTimestamp: v.number(),
    createdBy: v.id("users"),
  },
  handler: async (ctx, args) => {
    const product = await ctx.db.get(args.productId);
    if (!product || product.businessId !== args.businessId) {
      throw new Error("Product not found");
    }

    const previousStock = product.currentStock;
    const newStock = Math.max(0, previousStock + args.deltaQuantity);

    await ctx.db.patch(args.productId, {
      currentStock: newStock,
      updatedAt: Date.now(),
    });

    const movementId = await ctx.db.insert("stockMovements", {
      businessId: args.businessId,
      productId: args.productId,
      deltaQuantity: args.deltaQuantity,
      previousStock,
      newStock,
      reason: args.reason,
      referenceId: args.referenceId,
      batchNumber: args.batchNumber,
      expiryDate: args.expiryDate,
      deviceId: args.deviceId,
      localTimestamp: args.localTimestamp,
      createdBy: args.createdBy,
      createdAt: Date.now(),
    });

    return { movementId, newStock };
  },
});

// List Stock Movements for Product
export const listStockMovements = query({
  args: {
    businessId: v.id("businesses"),
    productId: v.optional(v.id("products")),
  },
  handler: async (ctx, args) => {
    if (args.productId) {
      return await ctx.db
        .query("stockMovements")
        .withIndex("by_product", (q) => q.eq("productId", args.productId!))
        .order("desc")
        .take(50);
    }

    return await ctx.db
      .query("stockMovements")
      .withIndex("by_business", (q) => q.eq("businessId", args.businessId))
      .order("desc")
      .take(100);
  },
});
