import { mutation, query, QueryCtx, MutationCtx } from "./_generated/server";
import { v } from "convex/values";
import { Id } from "./_generated/dataModel";

// Helper simple PIN hash
export function hashPin(pin: string): string {
  let hash = 0;
  for (let i = 0; i < pin.length; i++) {
    const char = pin.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash |= 0;
  }
  return "h_" + Math.abs(hash).toString(16) + "_" + pin.length;
}

// Ugandan phone normalizer: 07XXXXXXXX or +2567XXXXXXXX -> 2567XXXXXXXX
export function normalizeUgandaPhone(phone: string): string {
  let cleaned = phone.replace(/[^0-9]/g, "");
  if (cleaned.startsWith("0") && cleaned.length === 10) {
    cleaned = "256" + cleaned.substring(1);
  } else if (cleaned.startsWith("256") && cleaned.length === 12) {
    // already 2567XXXXXXXX
  } else if (cleaned.length === 9) {
    cleaned = "256" + cleaned;
  }
  return cleaned;
}

// Security: Verify user has valid active access to business with required role/permissions
export async function verifyUserBusinessAccess(
  ctx: QueryCtx | MutationCtx,
  userId: Id<"users">,
  businessId: Id<"businesses">,
  requiredPermission?: string
) {
  const user = await ctx.db.get(userId);
  if (!user || user.businessId !== businessId || !user.isActive) {
    throw new Error("UNAUTHORIZED: User does not have access to this business.");
  }
  if (requiredPermission && user.role !== "owner" && !user.permissions.includes(requiredPermission)) {
    throw new Error(`FORBIDDEN: Missing required permission: ${requiredPermission}`);
  }
  return user;
}

// Onboard a new business & owner
export const registerBusinessAndOwner = mutation({
  args: {
    businessName: v.string(),
    ownerName: v.string(),
    phone: v.string(),
    pin: v.string(),
    email: v.optional(v.string()),
    address: v.optional(v.string()),
    city: v.optional(v.string()),
    tin: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const normalizedPhone = normalizeUgandaPhone(args.phone);

    // Check if phone already registered
    const existingUser = await ctx.db
      .query("users")
      .withIndex("by_phone", (q) => q.eq("phone", normalizedPhone))
      .first();

    if (existingUser) {
      throw new Error("A user with this phone number is already registered.");
    }

    // 1. Create Business
    const businessId = await ctx.db.insert("businesses", {
      name: args.businessName,
      legalName: args.businessName,
      phone: normalizedPhone,
      email: args.email,
      address: args.address,
      city: args.city ?? "Kampala",
      country: "Uganda",
      currency: "UGX",
      tin: args.tin,
      smsCredits: 20, // Free 20 SMS credits for starter
      subscriptionTier: "free",
      status: "active",
      isEfrisEnrolled: !!args.tin,
      createdAt: now,
      updatedAt: now,
    });

    // 2. Create Owner User
    const userId = await ctx.db.insert("users", {
      businessId,
      phone: normalizedPhone,
      fullName: args.ownerName,
      role: "owner",
      pinHash: hashPin(args.pin),
      permissions: [
        "can_manage_business",
        "can_view_reports",
        "can_view_cost_price",
        "can_void_sale",
        "can_approve_credit",
        "can_send_sms",
        "can_manage_staff",
      ],
      isActive: true,
      lastLoginAt: now,
      createdAt: now,
    });

    // Set ownerId on business
    await ctx.db.patch(businessId, { ownerId: userId });

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
      phone: normalizedPhone,
      role: "owner",
      currency: "UGX",
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
    const normalizedPhone = normalizeUgandaPhone(args.phone);

    const user = await ctx.db
      .query("users")
      .withIndex("by_phone", (q) => q.eq("phone", normalizedPhone))
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
      smsCredits: business.smsCredits,
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
    role: v.union(
      v.literal("admin"),
      v.literal("manager"),
      v.literal("cashier"),
      v.literal("staff")
    ),
    permissions: v.array(v.string()),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.callerUserId, args.businessId, "can_manage_staff");

    const normalizedPhone = normalizeUgandaPhone(args.phone);

    const existingUser = await ctx.db
      .query("users")
      .withIndex("by_phone", (q) => q.eq("phone", normalizedPhone))
      .first();

    if (existingUser) {
      throw new Error("Phone number already associated with an account.");
    }

    const now = Date.now();
    const staffId = await ctx.db.insert("users", {
      businessId: args.businessId,
      phone: normalizedPhone,
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
    callerUserId: v.id("users"),
  },
  handler: async (ctx, args) => {
    await verifyUserBusinessAccess(ctx, args.callerUserId, args.businessId);

    return await ctx.db
      .query("users")
      .withIndex("by_business", (q) => q.eq("businessId", args.businessId))
      .collect();
  },
});
