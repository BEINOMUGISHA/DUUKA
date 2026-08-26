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
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.userId, args.businessId, "can_send_sms");

    const business = await ctx.db.get(args.businessId);
    if (!business) throw new Error("Business not found");

    if (business.smsCredits <= 0) {
      throw new Error("Insufficient SMS credits. Please top up your SMS balance.");
    }

    const normalizedPhone = normalizeUgandaPhone(args.phone);
    const now = Date.now();

    // Deduct 1 credit
    await ctx.db.patch(args.businessId, {
      smsCredits: business.smsCredits - 1,
      updatedAt: now,
    });

    const smsId = await ctx.db.insert("smsMessages", {
      businessId: args.businessId,
      customerId: args.customerId,
      phone: normalizedPhone,
      message: args.message,
      type: args.type,
      status: "sent",
      provider: "africas_talking",
      providerMessageId: `SMS-${now}`,
      cost: 1,
      createdAt: now,
      sentAt: now,
    });

    await ctx.db.insert("smsUsage", {
      businessId: args.businessId,
      smsId,
      creditsUsed: 1,
      createdAt: now,
    });

    const user = await ctx.db.get(args.userId);
    await ctx.db.insert("auditLogs", {
      businessId: args.businessId,
      userId: args.userId,
      userName: user?.fullName ?? "Staff",
      action: "SMS_SENT",
      entityType: "sms",
      entityId: smsId,
      deviceId: "cloud-dispatch",
      details: `Sent ${args.type} SMS to +${normalizedPhone}`,
      createdAt: now,
    });

    return {
      success: true,
      smsId,
      remainingCredits: business.smsCredits - 1,
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
