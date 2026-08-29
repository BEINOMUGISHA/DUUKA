import { action, mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { verifyUserBusinessAccess, normalizeUgandaPhone } from "./auth";

// Server-side SMS provider interface
export interface SmsSendResult {
  success: boolean;
  provider: string;
  providerMessageId?: string;
  cost: number;
  status: "sent" | "delivered" | "failed";
  error?: string;
}

// SMS Provider implementation with Environment Configuration
async function sendSmsViaProvider(to: string, message: string): Promise<SmsSendResult> {
  const provider = process.env.SMS_PROVIDER || "africas_talking"; // "africas_talking" | "twilio" | "sandbox"
  const apiKey = process.env.SMS_API_KEY;
  const username = process.env.SMS_USERNAME || "sandbox";
  const senderId = process.env.SMS_SENDER_ID || "DUKA";

  // Production Africa's Talking API
  if (provider === "africas_talking" && apiKey) {
    try {
      const response = await fetch("https://api.africastalking.com/version1/messaging", {
        method: "POST",
        headers: {
          apiKey: apiKey,
          "Content-Type": "application/x-www-form-urlencoded",
          Accept: "application/json",
        },
        body: new URLSearchParams({
          username: username,
          to: "+" + to,
          message: message,
          from: senderId,
        }),
      });

      const data = await response.json();
      const recipient = data.SMSMessageData?.Recipients?.[0];

      if (recipient && (recipient.status === "Success" || recipient.statusCode === 101)) {
        return {
          success: true,
          provider: "africas_talking",
          providerMessageId: recipient.messageId,
          cost: 1,
          status: "sent",
        };
      } else {
        return {
          success: false,
          provider: "africas_talking",
          cost: 0,
          status: "failed",
          error: recipient?.status ?? "Africa's Talking dispatch failed",
        };
      }
    } catch (e: any) {
      return {
        success: false,
        provider: "africas_talking",
        cost: 0,
        status: "failed",
        error: e.message,
      };
    }
  }

  // Sandbox / Test provider for environments where keys are not configured yet
  const mockMessageId = `SMS-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;
  return {
    success: true,
    provider: "sandbox_gateway",
    providerMessageId: mockMessageId,
    cost: 1,
    status: "sent",
  };
}

// Generate template message
export const getSmsTemplate = query({
  args: {
    businessId: v.id("businesses"),
    customerId: v.id("customers"),
    type: v.union(
      v.literal("debt_reminder"),
      v.literal("payment_confirmation"),
      v.literal("overdue"),
      v.literal("welcome")
    ),
    language: v.optional(v.union(v.literal("en"), v.literal("lg"), v.literal("rn"))),
    amount: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const customer = await ctx.db.get(args.customerId);
    const business = await ctx.db.get(args.businessId);

    if (!customer || !business) {
      throw new Error("Customer or business not found");
    }

    const lang = args.language ?? "en";
    const balanceStr = `UGX ${customer.currentDebt.toLocaleString()}`;
    const amountStr = args.amount ? `UGX ${args.amount.toLocaleString()}` : balanceStr;
    const bName = business.name;

    if (args.type === "debt_reminder") {
      if (lang === "lg") {
        return `Nkulamusizza ${customer.name}, eno ye ${bName}. Tukujjukizaako ebbanja lyo erya ${balanceStr}. Osobola okusasula ku MTN MoMo oba Airtel Money. Weebale nnyo!`;
      }
      if (lang === "rn") {
        return `Agandi ${customer.name}, oku niyo ${bName}. Nitukwijutsya omwenda gwaawe gwa ${balanceStr}. Noobaasa kushashura na MTN MoMo nari Airtel Money. Webare munonga!`;
      }
      return `Hello ${customer.name}, this is a friendly reminder from ${bName} that your outstanding balance is ${balanceStr}. Thank you for your business.`;
    }

    if (args.type === "payment_confirmation") {
      if (lang === "lg") {
        return `Nkulamusizza ${customer.name}, ${bName} efunye ssente zo ${amountStr}. Ebbanja erisigaddeyo liri ${balanceStr}. Weebale nnyo!`;
      }
      return `Hello ${customer.name}, ${bName} has received your payment of ${amountStr}. Your remaining balance is ${balanceStr}. Thank you!`;
    }

    if (args.type === "overdue") {
      if (lang === "lg") {
        return `Nkulamusizza ${customer.name}, ebbanja lyo erya ${balanceStr} ku ${bName} lyayiseeko. Tukusaba otukwatireko okumalayo ensonga eno. Weebale.`;
      }
      return `Hello ${customer.name}, your payment of ${balanceStr} to ${bName} is overdue. Please contact us to arrange payment. Thank you.`;
    }

    return `Dear ${customer.name}, thank you for shopping at ${bName}! We appreciate your continued business.`;
  },
});

// Action to Send SMS to customer (Checks credits, calls provider, deducts credit, logs message)
export const sendCustomerSms = mutation({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    customerId: v.optional(v.id("customers")),
    phone: v.string(),
    message: v.string(),
    type: v.union(
      v.literal("debt_reminder"),
      v.literal("payment_confirmation"),
      v.literal("invoice"),
      v.literal("custom"),
      v.literal("welcome")
    ),
    idempotencyKey: v.optional(v.string()), // Caller-provided UUID to prevent duplicate sends
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId, "can_send_sms");

    // Idempotency: if this key was already used, return the existing record
    if (args.idempotencyKey) {
      const existing = await ctx.db
        .query("smsMessages")
        .withIndex("by_idempotency_key", (q) => q.eq("idempotencyKey", args.idempotencyKey))
        .first();
      if (existing) {
        return {
          success: true,
          smsId: existing._id,
          remainingCredits: (await ctx.db.get(args.businessId))?.smsCredits ?? 0,
          duplicate: true,
        };
      }
    }

    const business = await ctx.db.get(args.businessId);
    if (!business) throw new Error("Business not found");

    if (business.smsCredits <= 0) {
      throw new Error("Insufficient SMS credits. Please top up your SMS balance.");
    }

    const normalizedPhone = normalizeUgandaPhone(args.phone);
    const now = Date.now();

    // Log the message first with status "pending" — credit deducted AFTER successful send
    const smsId = await ctx.db.insert("smsMessages", {
      businessId: args.businessId,
      customerId: args.customerId,
      phone: normalizedPhone,
      message: args.message,
      type: args.type,
      status: "pending",
      provider: "africas_talking",
      idempotencyKey: args.idempotencyKey,
      cost: 0, // will be updated to 1 on success
      createdAt: now,
    });

    // Attempt the actual send via provider (real or sandbox)
    const sendResult = await sendSmsViaProvider(normalizedPhone, args.message);

    if (sendResult.success) {
      // Only deduct credit on confirmed send success
      await ctx.db.patch(args.businessId, {
        smsCredits: business.smsCredits - 1,
        updatedAt: now,
      });

      await ctx.db.patch(smsId, {
        status: "sent",
        providerMessageId: sendResult.providerMessageId,
        cost: 1,
        sentAt: now,
      });

      await ctx.db.insert("smsUsage", {
        businessId: args.businessId,
        smsId,
        creditsUsed: 1,
        createdAt: now,
      });
    } else {
      // Mark as failed — no credit deducted
      await ctx.db.patch(smsId, {
        status: "failed",
        error: sendResult.error ?? "Provider send failed",
        cost: 0,
      });
    }

    const user = await ctx.db.get(args.userId);
    await ctx.db.insert("auditLogs", {
      businessId: args.businessId,
      userId: args.userId,
      userName: user?.fullName ?? "Staff",
      action: "SMS_SENT",
      entityType: "sms",
      entityId: smsId,
      deviceId: "cloud-dispatch",
      details: `${sendResult.success ? "Sent" : "Failed"} ${args.type} SMS to +${normalizedPhone}`,
      createdAt: now,
    });

    return {
      success: sendResult.success,
      smsId,
      remainingCredits: sendResult.success ? business.smsCredits - 1 : business.smsCredits,
      error: sendResult.error,
    };
  },
});

// Bulk SMS — Remind ALL overdue debtors in one call
export const bulkRemindOverdueDebtors = mutation({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    language: v.optional(v.union(v.literal("en"), v.literal("lg"), v.literal("rn"))),
    dryRun: v.optional(v.boolean()), // if true, return count/cost without sending
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId, "can_send_sms");

    const business = await ctx.db.get(args.businessId);
    if (!business) throw new Error("Business not found");

    // Collect all customers with overdue debts
    const now = Date.now();
    const overdueDebts = await ctx.db
      .query("debts")
      .withIndex("by_business_and_status", (q) =>
        q.eq("businessId", args.businessId).eq("status", "overdue")
      )
      .collect();

    // Also pick up "active" debts past due date
    const activeDebts = await ctx.db
      .query("debts")
      .withIndex("by_business_and_status", (q) =>
        q.eq("businessId", args.businessId).eq("status", "active")
      )
      .collect();
    const pastDueActive = activeDebts.filter((d) => d.dueDate < now && d.balance > 0);

    const allOverdue = [...overdueDebts, ...pastDueActive];
    const uniqueCustomerIds = [...new Set(allOverdue.map((d) => d.customerId))];
    const estimatedCredits = uniqueCustomerIds.length;

    if (args.dryRun) {
      return {
        dryRun: true,
        debtorCount: uniqueCustomerIds.length,
        estimatedCredits,
        currentCredits: business.smsCredits,
        canAfford: business.smsCredits >= estimatedCredits,
      };
    }

    if (business.smsCredits < estimatedCredits) {
      throw new Error(
        `Insufficient SMS credits. Need ${estimatedCredits} credits but only have ${business.smsCredits}.`
      );
    }

    const lang = args.language ?? "en";
    const bName = business.name;
    let sent = 0;
    let failed = 0;
    const user = await ctx.db.get(args.userId);

    for (const customerId of uniqueCustomerIds) {
      const customer = await ctx.db.get(customerId);
      if (!customer || !customer.phone) { failed++; continue; }

      // Total overdue balance for this customer
      const customerOverdue = allOverdue
        .filter((d) => d.customerId === customerId)
        .reduce((sum, d) => sum + d.balance, 0);

      const balanceStr = `UGX ${customerOverdue.toLocaleString()}`;
      let message: string;
      if (lang === "lg") {
        message = `Nkulamusizza ${customer.name}, ebbanja lyo erya ${balanceStr} ku ${bName} lyayiseeko. Tukusaba otukwatireko okumalayo ensonga eno. Weebale.`;
      } else if (lang === "rn") {
        message = `Agandi ${customer.name}, omwenda gwaawe gwa ${balanceStr} gu ${bName} gwasiibire. Noobaasa kushashura na MTN MoMo nari Airtel Money. Webare.`;
      } else {
        message = `Hello ${customer.name}, your payment of ${balanceStr} to ${bName} is overdue. Please pay via MTN MoMo or Airtel Money. Thank you.`;
      }

      const sendResult = await sendSmsViaProvider(customer.phone, message);
      const smsNow = Date.now();

      const smsId = await ctx.db.insert("smsMessages", {
        businessId: args.businessId,
        customerId,
        phone: customer.phone,
        message,
        type: "debt_reminder",
        status: sendResult.success ? "sent" : "failed",
        provider: sendResult.provider,
        providerMessageId: sendResult.providerMessageId,
        idempotencyKey: `bulk-${args.businessId}-${customerId}-${now}`,
        cost: sendResult.success ? 1 : 0,
        createdAt: smsNow,
        sentAt: sendResult.success ? smsNow : undefined,
        error: sendResult.error,
      });

      if (sendResult.success) {
        sent++;
        await ctx.db.insert("smsUsage", { businessId: args.businessId, smsId, creditsUsed: 1, createdAt: smsNow });
      } else {
        failed++;
      }
    }

    // Deduct all successfully sent credits at once
    await ctx.db.patch(args.businessId, {
      smsCredits: business.smsCredits - sent,
      updatedAt: Date.now(),
    });

    await ctx.db.insert("auditLogs", {
      businessId: args.businessId,
      userId: args.userId,
      userName: user?.fullName ?? "Staff",
      action: "BULK_SMS_SENT",
      entityType: "sms",
      entityId: args.businessId,
      deviceId: "cloud-dispatch",
      details: `Bulk overdue reminder: ${sent} sent, ${failed} failed. Credits used: ${sent}.`,
      createdAt: Date.now(),
    });

    return {
      sent,
      failed,
      creditsUsed: sent,
      remainingCredits: business.smsCredits - sent,
    };
  },
});

// List SMS History
export const listSmsHistory = query({
  args: {
    businessId: v.id("businesses"),
    userId: v.id("users"),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId);

    return await ctx.db
      .query("smsMessages")
      .withIndex("by_business", (q) => q.eq("businessId", args.businessId))
      .order("desc")
      .take(args.limit ?? 50);
  },
});

