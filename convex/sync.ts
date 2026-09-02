import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { Id } from "./_generated/dataModel";

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

        if (item.entityType === "product") {
          const existing = await ctx.db
            .query("products")
            .withIndex("by_offline_id", (q) => q.eq("offlineId", parsed.id))
            .first();
          if (existing) {
            if (item.action === "update") {
              await ctx.db.patch(existing._id, {
                name: parsed.name,
                sku: parsed.sku,
                category: parsed.category,
                costPrice: parsed.costPrice,
                sellingPrice: parsed.sellPrice,
                lowStockThreshold: parsed.minStockLevel,
                unit: parsed.unit,
                updatedAt: Date.now(),
              });
            }
            results.push({ queueId: item.queueId, status: "success", serverId: existing._id });
            continue;
          }
          const productId = await ctx.db.insert("products", {
            businessId: args.businessId,
            offlineId: parsed.id,
            name: parsed.name,
            sku: parsed.sku,
            category: parsed.category ?? "General",
            costPrice: parsed.costPrice ?? 0,
            sellingPrice: parsed.sellPrice ?? 0,
            stockQuantity: parsed.currentStock ?? 0,
            lowStockThreshold: parsed.minStockLevel ?? 0,
            unit: parsed.unit ?? "pcs",
            isTaxable: parsed.isTaxable ?? true,
            taxRate: parsed.taxRate ?? 0.18,
            isArchived: parsed.isArchived ?? false,
            createdAt: parsed.updatedAt ?? Date.now(),
            updatedAt: Date.now(),
          });
          results.push({ queueId: item.queueId, status: "success", serverId: productId });
        } else if (item.entityType === "customer") {
          const existing = await ctx.db
            .query("customers")
            .withIndex("by_offline_id", (q) => q.eq("offlineId", parsed.id))
            .first();
          if (existing) {
            if (item.action === "update") {
              await ctx.db.patch(existing._id, {
                name: parsed.name,
                phone: parsed.phone,
                email: parsed.email,
                address: parsed.address,
                creditLimit: parsed.creditLimit ?? 0,
                notes: parsed.notes,
                updatedAt: Date.now(),
              });
            }
            results.push({ queueId: item.queueId, status: "success", serverId: existing._id });
            continue;
          }
          const customerId = await ctx.db.insert("customers", {
            businessId: args.businessId,
            offlineId: parsed.id,
            name: parsed.name,
            phone: parsed.phone,
            email: parsed.email,
            address: parsed.address,
            creditLimit: parsed.creditLimit ?? 0,
            currentDebt: parsed.currentDebt ?? 0,
            notes: parsed.notes,
            isArchived: parsed.isArchived ?? false,
            createdAt: parsed.createdAt ?? Date.now(),
            updatedAt: Date.now(),
          });
          results.push({ queueId: item.queueId, status: "success", serverId: customerId });
        } else if (item.entityType === "sale") {
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

          // Field names MUST match schema.ts exactly:
          // subtotal, discount, tax, total, amountPaid, balance, status
          const subtotal = parsed.subtotalAmount ?? parsed.subtotal ?? parsed.totalAmount ?? 0;
          const total = parsed.totalAmount ?? parsed.total ?? subtotal;
          const amountPaid = parsed.paidAmount ?? parsed.amountPaid ?? 0;
          const balance = Math.max(0, total - amountPaid);
          const saleStatus = balance === 0 ? "completed" : "pending";

          let resolvedCustomerId: Id<"customers"> | undefined;
          const customerPhone = typeof parsed.customerPhone === "string"
            ? parsed.customerPhone.replace(/[^0-9]/g, "")
            : "";
          if (customerPhone && customerPhone !== "0700000000") {
            const normalizedPhone = customerPhone.startsWith("0") && customerPhone.length === 10
              ? "256" + customerPhone.substring(1)
              : customerPhone;
            const customers = await ctx.db
              .query("customers")
              .withIndex("by_business", (q) => q.eq("businessId", args.businessId))
              .collect();
            const existingCustomer = customers.find((customer) => customer.phone === normalizedPhone);
            if (existingCustomer) {
              resolvedCustomerId = existingCustomer._id;
            } else if (parsed.customerName && parsed.customerName !== "Walk-in Customer") {
              resolvedCustomerId = await ctx.db.insert("customers", {
                businessId: args.businessId,
                name: parsed.customerName,
                phone: normalizedPhone,
                creditLimit: 0,
                currentDebt: 0,
                isArchived: false,
                createdAt: Date.now(),
                updatedAt: Date.now(),
              });
            }
          }

          const saleId = await ctx.db.insert("sales", {
            businessId: args.businessId,
            saleNumber,
            customerId: resolvedCustomerId,
            customerName: parsed.customerName,
            customerPhone: parsed.customerPhone,
            subtotal,
            discount: parsed.discountAmount ?? parsed.discount ?? 0,
            tax: parsed.taxAmount ?? parsed.tax ?? 0,
            total,
            amountPaid,
            balance,
            status: saleStatus,
            paymentMethod: parsed.paymentMethod ?? "cash",
            momoReference: parsed.momoReference,
            dueDate: parsed.dueDate,
            offlineId: item.queueId,
            deviceId: args.deviceId,
            localTimestamp: item.localTimestamp,
            createdBy: args.userId,
            createdAt: item.localTimestamp,
          });

          if (balance > 0 && resolvedCustomerId) {
            const customer = await ctx.db.get(resolvedCustomerId);
            if (customer) {
              await ctx.db.patch(resolvedCustomerId, {
                currentDebt: customer.currentDebt + balance,
                updatedAt: Date.now(),
              });
            }
            await ctx.db.insert("debts", {
              businessId: args.businessId,
              customerId: resolvedCustomerId,
              saleId,
              originalAmount: balance,
              amountPaid: 0,
              balance,
              dueDate: parsed.dueDate ?? Date.now() + 14 * 24 * 60 * 60 * 1000,
              status: "active",
              createdAt: Date.now(),
              updatedAt: Date.now(),
            });
          }

          // Reconcile any pending MoMo transaction that referenced this sale by offlineId
          const pendingMomo = await ctx.db
            .query("mobileMoneyTransactions")
            .withIndex("by_offline_sale_id", (q) => q.eq("offlineSaleId", item.queueId))
            .first();
          if (pendingMomo) {
            await ctx.db.patch(pendingMomo._id, { saleId, updatedAt: Date.now() });
          }

          // Stock delta deduction
          const items = parsed.items ?? parsed.cartItems ?? [];
          for (const it of items) {
            const products = await ctx.db
              .query("products")
              .withIndex("by_business", (q) => q.eq("businessId", args.businessId))
              .collect();
            const prod = products.find((product) =>
              (it.sku && product.sku === it.sku) || product.name === it.productName
            );
            let resolvedProductId: any = prod?._id;
            if (!prod) {
              resolvedProductId = await ctx.db.insert("products", {
                businessId: args.businessId,
                name: it.productName ?? "Unnamed item",
                sku: it.sku,
                category: it.category ?? "General",
                costPrice: it.costPrice ?? 0,
                sellingPrice: it.unitPrice ?? 0,
                stockQuantity: it.currentStock ?? 0,
                lowStockThreshold: 0,
                unit: it.unit ?? "pcs",
                isTaxable: true,
                taxRate: 0.18,
                isArchived: false,
                createdAt: Date.now(),
                updatedAt: Date.now(),
              });
            }
            if (resolvedProductId) {
              const previousStock = prod?.stockQuantity ?? 0;
              const newStock = Math.max(0, previousStock - it.quantity);
              await ctx.db.insert("saleItems", {
                saleId,
                businessId: args.businessId,
                productId: resolvedProductId,
                productName: it.productName ?? "Unnamed item",
                quantity: it.quantity ?? 1,
                unitPrice: it.unitPrice ?? 0,
                costPrice: it.costPrice ?? 0,
                discount: it.discount ?? 0,
                total: it.subtotal ?? (it.unitPrice ?? 0) * (it.quantity ?? 1),
              });
              await ctx.db.patch(resolvedProductId, { stockQuantity: newStock, updatedAt: Date.now() });
              await ctx.db.insert("stockMovements", {
                businessId: args.businessId,
                productId: resolvedProductId,
                deltaQuantity: -it.quantity,
                previousStock,
                newStock,
                reason: "sale",
                referenceId: saleId,
                deviceId: args.deviceId,
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
          const customerId = parsed.customerId as Id<"customers"> | undefined;
          const customer = customerId ? await ctx.db.get(customerId) : null;
          if (customer) {
            const newBal = Math.max(0, customer.currentDebt - parsed.amount);
            await ctx.db.patch(customer._id, { currentDebt: newBal, updatedAt: Date.now() });
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
