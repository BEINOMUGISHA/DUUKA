import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

// Helper simple PIN hash (in production, use bcrypt or crypto.subtle HMAC with salt)
function hashPin(pin: string): string {
  let hash = 0;
  for (let i = 0; i < pin.length; i++) {
    const char = pin.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash |= 0;
  }
  return "h_" + Math.abs(hash).toString(16) + "_" + pin.length;
}

// Onboard a new business & owner
export const registerBusinessAndOwner = mutation({
  args: {
    businessName: v.string(),
    ownerName: v.string(),
    phone: v.string(),
    pin: v.string(),
    currency: v.optional(v.string()),
    tin: v.optional(v.string()),
    address: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    
    // Check if phone already registered
    const existingUser = await ctx.db
      .query("users")
      .withIndex("by_phone", (q) => q.eq("phone", args.phone))
      .first();
    
    if (existingUser) {
      throw new Error("A user with this phone number already exists.");
    }

    // 1. Create Business
    const businessId = await ctx.db.insert("businesses", {
      name: args.businessName,
      legalName: args.businessName,
      tin: args.tin,
      currency: args.currency ?? "UGX",
      phone: args.phone,
      address: args.address,
      subscriptionTier: "free",
      subscriptionStatus: "active",
      isEfrisEnrolled: !!args.tin,
      createdAt: now,
      updatedAt: now,
    });

    // 2. Create Owner User
    const userId = await ctx.db.insert("users", {
      businessId,
      phone: args.phone,
      fullName: args.ownerName,
      role: "owner",
      pinHash: hashPin(args.pin),
      permissions: [
        "can_manage_business",
        "can_view_reports",
        "can_view_cost_price",
        "can_void_sale",
        "can_approve_credit",
        "can_manage_staff",
      ],
      isActive: true,
      lastLoginAt: now,
      createdAt: now,
    });

    // 3. Log Audit
    await ctx.db.insert("auditLogs", {
      businessId,
      userId,
      userName: args.ownerName,
      action: "REGISTER_BUSINESS",
      entityType: "business",
      entityId: businessId,
      deviceId: "initial-setup",
      details: `Business ${args.businessName} created with owner ${args.ownerName}`,
      createdAt: now,
    });

    return {
      businessId,
      userId,
      fullName: args.ownerName,
      phone: args.phone,
      role: "owner",
      currency: args.currency ?? "UGX",
      businessName: args.businessName,
    };
  },
});

// Login via Phone & PIN
export const loginWithPhoneAndPin = mutation({
  args: {
    phone: v.string(),
    pin: v.string(),
    deviceId: v.string(),
  },
  handler: async (ctx, args) => {
    const user = await ctx.db
      .query("users")
      .withIndex("by_phone", (q) => q.eq("phone", args.phone))
      .first();

    if (!user) {
      throw new Error("Invalid phone number or PIN");
    }

    if (!user.isActive) {
      throw new Error("Account is deactivated. Contact your business owner.");
    }

    const hashedInput = hashPin(args.pin);
    if (user.pinHash !== hashedInput && user.pinHash !== args.pin) {
      throw new Error("Invalid phone number or PIN");
    }

    const business = await ctx.db.get(user.businessId);
    if (!business) {
      throw new Error("Business not found");
    }

    const now = Date.now();
    await ctx.db.patch(user._id, { lastLoginAt: now });

    await ctx.db.insert("auditLogs", {
      businessId: user.businessId,
      userId: user._id,
      userName: user.fullName,
      action: "USER_LOGIN",
      entityType: "user",
      entityId: user._id,
      deviceId: args.deviceId,
      details: `Logged in from device ${args.deviceId}`,
      createdAt: now,
    });

    return {
      userId: user._id,
      businessId: user.businessId,
      fullName: user.fullName,
      phone: user.phone,
      role: user.role,
      permissions: user.permissions,
      businessName: business.name,
      currency: business.currency,
      subscriptionTier: business.subscriptionTier,
      isEfrisEnrolled: business.isEfrisEnrolled,
    };
  },
});

// Add Staff Member
export const addStaffMember = mutation({
  args: {
    businessId: v.id("businesses"),
    callerUserId: v.id("users"),
    fullName: v.string(),
    phone: v.string(),
    initialPin: v.string(),
    role: v.union(v.literal("manager"), v.literal("staff")),
    permissions: v.array(v.string()),
  },
  handler: async (ctx, args) => {
    const caller = await ctx.db.get(args.callerUserId);
    if (!caller || caller.businessId !== args.businessId || caller.role !== "owner") {
      throw new Error("Only the business owner can add staff members.");
    }

    const existingUser = await ctx.db
      .query("users")
      .withIndex("by_phone", (q) => q.eq("phone", args.phone))
      .first();

    if (existingUser) {
      throw new Error("Phone number already associated with an account.");
    }

    const now = Date.now();
    const staffId = await ctx.db.insert("users", {
      businessId: args.businessId,
      phone: args.phone,
      fullName: args.fullName,
      role: args.role,
      pinHash: hashPin(args.initialPin),
      permissions: args.permissions,
      isActive: true,
      createdAt: now,
    });

    return staffId;
  },
});

// List staff for business
export const listStaff = query({
  args: {
    businessId: v.id("businesses"),
  },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("users")
      .withIndex("by_business", (q) => q.eq("businessId", args.businessId))
      .collect();
  },
});
