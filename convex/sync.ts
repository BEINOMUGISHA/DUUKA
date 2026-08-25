import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

// Batch sync mutation for offline writes from mobile Drift DB
export const processBatchOfflineSync = mutation({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    deviceId: v.string(),
    payloads: v.array(
      v.object({
        queueId: v.string(),
        entityType: v.string(), // "sale", "stock_movement", "transaction", "customer_payment", "product"
        action: v.string(), // "create", "update"
        localTimestamp: v.number(),
        data: v.string(), // JSON stringified payload
      })
    ),
  },
  handler: async (ctx, args) => {
    const results: Array<{ queueId: string; status: "success" | "conflict" | "error"; serverId?: string; error?: string }> = [];

    for (const item of args.payloads) {
      try {
        const parsed = JSON.parse(item.data);

        if (item.entityType === "sale") {
          // Check if already synced by offlineId to prevent duplicate sales
          const existing = await ctx.db
            .query("sales")
            .withIndex("by_offline_id", (q) => q.eq("offlineId", item.queueId))
            .first();

          if (existing) {
            results.push({ queueId: item.queueId, status: "success", serverId: existing._id });
            continue;
          }

          const dateStr = new Date(item.localTimestamp).toISOString().slice(0, 10).replace(/-/g, "");
          const randomSuffix = Math.floor(1000 + Math.random() * 9000);
          const saleNumber = `SL-${dateStr}-${randomSuffix}`;
          const dueAmount = Math.max(0, parsed.totalAmount - (parsed.paidAmount ?? 0));

          const saleId = await ctx.db.insert("sales", {
            businessId: args.businessId,
            saleNumber,
            customerId: parsed.customerId,
            customerName: parsed.customerName,
            customerPhone: parsed.customerPhone,
            items: parsed.items,
            subtotalAmount: parsed.subtotalAmount,
            taxAmount: parsed.taxAmount ?? 0,
            discountAmount: parsed.discountAmount ?? 0,
            totalAmount: parsed.totalAmount,
            paidAmount: parsed.paidAmount ?? 0,
            dueAmount,
            paymentStatus: dueAmount === 0 ? "paid" : (parsed.paidAmount ?? 0) > 0 ? "partial" : "unpaid",
            paymentMethod: parsed.paymentMethod ?? "cash",
            momoReference: parsed.momoReference,
            isCredit: dueAmount > 0,
            dueDate: parsed.dueDate,
            offlineId: item.queueId,
            deviceId: args.deviceId,
            localTimestamp: item.localTimestamp,
            createdBy: args.userId,
            createdAt: item.localTimestamp,
            syncedAt: Date.now(),
          });

          // Stock delta deduction
          for (const it of parsed.items) {
            const prod = await ctx.db.get(it.productId);
            if (prod) {
              const newStock = Math.max(0, prod.currentStock - it.quantity);
              await ctx.db.patch(it.productId, { currentStock: newStock, updatedAt: Date.now() });
              await ctx.db.insert("stockMovements", {
                businessId: args.businessId,
                productId: it.productId,
                deltaQuantity: -it.quantity,
                previousStock: prod.currentStock,
                newStock,
                reason: "sale",
                referenceId: saleId,
                deviceId: args.deviceId,
                localTimestamp: item.localTimestamp,
                createdBy: args.userId,
                createdAt: Date.now(),
              });
            }
          }

          results.push({ queueId: item.queueId, status: "success", serverId: saleId });
        } else if (item.entityType === "transaction") {
          const txId = await ctx.db.insert("transactions", {
            businessId: args.businessId,
            type: parsed.type,
            category: parsed.category,
            amount: parsed.amount,
            paymentMethod: parsed.paymentMethod,
            reference: parsed.reference,
            notes: parsed.notes,
            isRecurring: !!parsed.isRecurring,
            date: item.localTimestamp,
            deviceId: args.deviceId,
            createdBy: args.userId,
            createdAt: Date.now(),
          });

          results.push({ queueId: item.queueId, status: "success", serverId: txId });
        } else if (item.entityType === "customer_payment") {
          const customer = await ctx.db.get(parsed.customerId);
          if (customer) {
            const newBal = Math.max(0, customer.outstandingBalance - parsed.amount);
            await ctx.db.patch(customer._id, { outstandingBalance: newBal, isDebtor: newBal > 0, updatedAt: Date.now() });
          }
          const payId = await ctx.db.insert("payments", {
            businessId: args.businessId,
            receiptNumber: `RCP-SYNC-${Date.now().toString().slice(-6)}`,
            entityType: "customer_credit",
            entityId: parsed.customerId,
            customerId: parsed.customerId,
            amount: parsed.amount,
            paymentMethod: parsed.paymentMethod,
            reference: parsed.reference,
            notes: parsed.notes,
            receivedBy: args.userId,
            deviceId: args.deviceId,
            createdAt: Date.now(),
          });
          results.push({ queueId: item.queueId, status: "success", serverId: payId });
        } else {
          results.push({ queueId: item.queueId, status: "success" });
        }
      } catch (err: any) {
        results.push({ queueId: item.queueId, status: "error", error: err?.message ?? "Unknown error" });
      }
    }

    return results;
  },
});
