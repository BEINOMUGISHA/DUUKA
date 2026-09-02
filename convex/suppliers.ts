import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { Id } from "./_generated/dataModel";
import { verifyUserBusinessAccess } from "./auth";

// ─── List Suppliers ──────────────────────────────────────────────────────────
export const listSuppliers = query({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    includeInactive: v.optional(v.boolean()),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    const suppliers = await ctx.db
      .query("suppliers")
      .withIndex("by_business", (q) => q.eq("businessId", args.businessId))
      .collect();

    return args.includeInactive
      ? suppliers
      : suppliers.filter((s) => s.isActive);
  },
});

// ─── Upsert Supplier (Create or Update) ─────────────────────────────────────
export const upsertSupplier = mutation({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    supplierId: v.optional(v.id("suppliers")), // omit for create
    name: v.string(),
    contactName: v.optional(v.string()),
    phone: v.optional(v.string()),
    email: v.optional(v.string()),
    address: v.optional(v.string()),
    tin: v.optional(v.string()),
    notes: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    const now = Date.now();
    const user = await ctx.db.get(args.userId);

    if (args.supplierId) {
      // Update
      const existing = await ctx.db.get(args.supplierId);
      if (!existing || existing.businessId !== args.businessId) {
        throw new Error("Supplier not found");
      }
      await ctx.db.patch(args.supplierId, {
        name: args.name,
        contactName: args.contactName,
        phone: args.phone,
        email: args.email,
        address: args.address,
        tin: args.tin,
        notes: args.notes,
        updatedAt: now,
      });
      await ctx.db.insert("auditLogs", {
        businessId: args.businessId,
        userId: args.userId,
        userName: user?.fullName ?? "Staff",
        action: "SUPPLIER_UPDATED",
        entityType: "supplier",
        entityId: args.supplierId,
        deviceId: "app",
        details: `Updated supplier: ${args.name}`,
        createdAt: now,
      });
      return { supplierId: args.supplierId, action: "updated" };
    } else {
      // Create
      const supplierId = await ctx.db.insert("suppliers", {
        businessId: args.businessId,
        name: args.name,
        contactName: args.contactName,
        phone: args.phone,
        email: args.email,
        address: args.address,
        tin: args.tin,
        notes: args.notes,
        totalPurchased: 0,
        outstandingPayable: 0,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      });
      await ctx.db.insert("auditLogs", {
        businessId: args.businessId,
        userId: args.userId,
        userName: user?.fullName ?? "Staff",
        action: "SUPPLIER_CREATED",
        entityType: "supplier",
        entityId: supplierId,
        deviceId: "app",
        details: `Created supplier: ${args.name}`,
        createdAt: now,
      });
      return { supplierId, action: "created" };
    }
  },
});

// ─── Create Purchase Order ───────────────────────────────────────────────────
export const createPurchaseOrder = mutation({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    supplierId: v.id("suppliers"),
    items: v.array(v.object({
      productId: v.string(),
      productName: v.string(),
      quantityOrdered: v.number(),
      costPerUnit: v.number(),
    })),
    notes: v.optional(v.string()),
    paymentMethod: v.optional(v.union(
      v.literal("cash"),
      v.literal("mtn_momo"),
      v.literal("airtel_money"),
      v.literal("bank")
    )),
    deviceId: v.string(),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    const supplier = await ctx.db.get(args.supplierId);
    if (!supplier || supplier.businessId !== args.businessId) {
      throw new Error("Supplier not found");
    }

    const now = Date.now();
    const year = new Date().getFullYear();
    const poCount = await ctx.db
      .query("purchaseOrders")
      .withIndex("by_business", (q) => q.eq("businessId", args.businessId))
      .collect()
      .then((r) => r.length + 1);
    const poNumber = `PO-${year}-${String(poCount).padStart(4, "0")}`;

    // Compute totals
    const orderItems = args.items.map((it) => ({
      ...it,
      quantityReceived: 0,
      total: it.quantityOrdered * it.costPerUnit,
    }));
    const subtotal = orderItems.reduce((sum, it) => sum + it.total, 0);
    const taxAmount = 0; // Supplier tax can vary — set at receive time
    const totalAmount = subtotal + taxAmount;

    const poId = await ctx.db.insert("purchaseOrders", {
      businessId: args.businessId,
      supplierId: args.supplierId,
      supplierName: supplier.name,
      poNumber,
      status: "ordered",
      items: orderItems,
      subtotal,
      taxAmount,
      totalAmount,
      amountPaid: 0,
      balance: totalAmount,
      paymentMethod: args.paymentMethod,
      notes: args.notes,
      orderedAt: now,
      deviceId: args.deviceId,
      createdBy: args.userId,
      createdAt: now,
      updatedAt: now,
    });

    // Update supplier outstanding payable
    await ctx.db.patch(args.supplierId, {
      outstandingPayable: supplier.outstandingPayable + totalAmount,
      updatedAt: now,
    });

    const user = await ctx.db.get(args.userId);
    await ctx.db.insert("auditLogs", {
      businessId: args.businessId,
      userId: args.userId,
      userName: user?.fullName ?? "Staff",
      action: "PURCHASE_ORDER_CREATED",
      entityType: "purchase_order",
      entityId: poId,
      deviceId: args.deviceId,
      details: `Created PO ${poNumber} for ${supplier.name} — UGX ${totalAmount.toLocaleString()}`,
      createdAt: now,
    });

    return { poId, poNumber, totalAmount };
  },
});

// ─── Receive Purchase Order (GRN) ────────────────────────────────────────────
// Triggers stock restock movements for received quantities
export const receivePurchaseOrder = mutation({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    poId: v.id("purchaseOrders"),
    // Per-item actual quantities received (may differ from ordered)
    receivedItems: v.array(v.object({
      productId: v.string(),
      quantityReceived: v.number(),
      costPerUnit: v.number(), // may differ from ordered price (price variance)
    })),
    amountPaid: v.optional(v.number()),
    paymentMethod: v.optional(v.union(
      v.literal("cash"),
      v.literal("mtn_momo"),
      v.literal("airtel_money"),
      v.literal("bank")
    )),
    notes: v.optional(v.string()),
    deviceId: v.string(),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    const po = await ctx.db.get(args.poId);
    if (!po || po.businessId !== args.businessId) {
      throw new Error("Purchase order not found");
    }
    if (po.status === "cancelled") {
      throw new Error("Cannot receive a cancelled purchase order");
    }

    const now = Date.now();
    const user = await ctx.db.get(args.userId);

    // Update PO items with received quantities
    const updatedItems = po.items.map((poItem) => {
      const received = args.receivedItems.find((r) => r.productId === poItem.productId);
      return {
        ...poItem,
        quantityReceived: received
          ? poItem.quantityReceived + received.quantityReceived
          : poItem.quantityReceived,
        costPerUnit: received?.costPerUnit ?? poItem.costPerUnit,
        total: (received?.quantityReceived ?? poItem.quantityReceived) * (received?.costPerUnit ?? poItem.costPerUnit),
      };
    });

    const totalReceived = updatedItems.reduce((s, i) => s + i.quantityReceived, 0);
    const totalOrdered = updatedItems.reduce((s, i) => s + i.quantityOrdered, 0);
    const newStatus = totalReceived >= totalOrdered ? "received" : "partially_received";

    const amountPaid = args.amountPaid ?? 0;
    const newAmountPaid = po.amountPaid + amountPaid;
    const newBalance = Math.max(0, po.totalAmount - newAmountPaid);

    await ctx.db.patch(args.poId, {
      items: updatedItems,
      status: newStatus,
      amountPaid: newAmountPaid,
      balance: newBalance,
      paymentMethod: args.paymentMethod ?? po.paymentMethod,
      notes: args.notes ?? po.notes,
      receivedAt: now,
      updatedAt: now,
    });

    // Process stock restock movements for each received product
    for (const recv of args.receivedItems) {
      if (recv.quantityReceived <= 0) continue;

      const productId = recv.productId as Id<"products">;
      const prod = await ctx.db.get(productId);
      if (!prod) continue;

      const newStock = prod.stockQuantity + recv.quantityReceived;
      await ctx.db.patch(productId, {
        stockQuantity: newStock,
        costPrice: recv.costPerUnit, // update cost price to latest GRN cost
        updatedAt: now,
      });

      await ctx.db.insert("stockMovements", {
        businessId: args.businessId,
        productId,
        deltaQuantity: recv.quantityReceived,
        previousStock: prod.stockQuantity,
        newStock,
        reason: "purchase",
        referenceId: args.poId,
        supplierName: po.supplierName,
        costPerUnit: recv.costPerUnit,
        notes: `GRN — ${po.poNumber}`,
        deviceId: args.deviceId,
        createdBy: args.userId,
        createdAt: now,
      });
    }

    // Update supplier accounts payable
    const supplier = await ctx.db.get(po.supplierId);
    if (supplier) {
      await ctx.db.patch(po.supplierId, {
        totalPurchased: supplier.totalPurchased + amountPaid,
        outstandingPayable: Math.max(0, supplier.outstandingPayable - amountPaid),
        updatedAt: now,
      });
    }

    // Record payment in ledger if amount paid
    if (amountPaid > 0 && args.paymentMethod) {
      await ctx.db.insert("transactions", {
        businessId: args.businessId,
        type: "expense",
        category: "purchases",
        amount: amountPaid,
        paymentMethod: args.paymentMethod,
        reference: po.poNumber,
        notes: `Payment to ${po.supplierName} for ${po.poNumber}`,
        isRecurring: false,
        date: now,
        deviceId: args.deviceId,
        createdBy: args.userId,
        createdAt: now,
      });
    }

    await ctx.db.insert("auditLogs", {
      businessId: args.businessId,
      userId: args.userId,
      userName: user?.fullName ?? "Staff",
      action: "PURCHASE_ORDER_RECEIVED",
      entityType: "purchase_order",
      entityId: args.poId,
      deviceId: args.deviceId,
      details: `GRN for ${po.poNumber} (${po.supplierName}): ${newStatus}. Paid UGX ${amountPaid.toLocaleString()}`,
      createdAt: now,
    });

    return { poId: args.poId, newStatus, newBalance };
  },
});

// ─── Purchase Order Summary ───────────────────────────────────────────────────
export const listPurchaseOrders = query({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    supplierId: v.optional(v.id("suppliers")),
    status: v.optional(v.string()),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    let orders = await ctx.db
      .query("purchaseOrders")
      .withIndex("by_business_and_created", (q) => q.eq("businessId", args.businessId))
      .order("desc")
      .take(args.limit ?? 100);

    if (args.supplierId) {
      orders = orders.filter((o) => o.supplierId === args.supplierId);
    }
    if (args.status && args.status !== "all") {
      orders = orders.filter((o) => o.status === args.status);
    }

    return orders;
  },
});
