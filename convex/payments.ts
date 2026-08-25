import { action, mutation, query } from "./_generated/server";
import { v } from "convex/values";

// Mock/Action for initiating MTN MoMo Collection request (USSD push to customer)
export const initiateMtnMomoCollection = action({
  args: {
    businessId: v.id("businesses"),
    amount: v.number(),
    phone: v.string(), // e.g. "256771234567"
    orderReference: v.string(),
    description: v.string(),
  },
  handler: async (ctx, args) => {
    // In production, this issues an HTTP POST to MTN MoMo Collection API:
    // https://sandbox.momodeveloper.mtn.com/collection/v1_0/requesttopay
    // Here we generate a transaction reference and status for immediate confirmation
    const externalId = `MTN-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;

    return {
      success: true,
      status: "PENDING_CUSTOMER_PIN",
      referenceId: externalId,
      phone: args.phone,
      amount: args.amount,
      message: `Prompt sent to ${args.phone}. Please approve on your phone with your MTN MoMo PIN.`,
    };
  },
});

// Mock/Action for Airtel Money Collection
export const initiateAirtelMoneyCollection = action({
  args: {
    businessId: v.id("businesses"),
    amount: v.number(),
    phone: v.string(), // e.g. "256751234567"
    orderReference: v.string(),
    description: v.string(),
  },
  handler: async (ctx, args) => {
    // In production, calls Airtel Money Africa API: /merchant/v1/payments/
    const externalId = `AIRTEL-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;

    return {
      success: true,
      status: "PENDING_CUSTOMER_PIN",
      referenceId: externalId,
      phone: args.phone,
      amount: args.amount,
      message: `Prompt sent to ${args.phone}. Please enter your Airtel Money PIN to confirm.`,
    };
  },
});
