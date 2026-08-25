import { action, mutation, query } from "./_generated/server";
import { v } from "convex/values";

// Generate URA EFRIS formatted e-Receipt data
export const generateEfrisInvoicePayload = query({
  args: {
    businessId: v.id("businesses"),
    saleId: v.id("sales"),
  },
  handler: async (ctx, args) => {
    const business = await ctx.db.get(args.businessId);
    const sale = await ctx.db.get(args.saleId);

    if (!business || !sale) {
      throw new Error("Business or Sale not found");
    }

    const items = sale.items.map((item, index) => {
      const vatRate = 0.18;
      const netAmount = item.subtotal / (1 + vatRate);
      const taxAmount = item.subtotal - netAmount;

      return {
        itemSeq: index + 1,
        goodsCode: `G-${item.productId.slice(-6)}`,
        goodsDescription: item.productName,
        quantity: item.quantity,
        unitPrice: Math.round(item.unitPrice / (1 + vatRate)),
        totalAmount: item.subtotal,
        taxRate: vatRate,
        taxAmount: Math.round(taxAmount),
        discount: 0,
      };
    });

    return {
      sellerDetails: {
        tin: business.tin ?? "1000000000",
        legalName: business.legalName ?? business.name,
        businessAddress: business.address ?? "Kampala, Uganda",
        currency: business.currency ?? "UGX",
      },
      buyerDetails: {
        buyerTin: "N/A",
        buyerName: sale.customerName ?? "Walk-in Customer",
        buyerPhone: sale.customerPhone ?? "N/A",
      },
      invoiceDetails: {
        invoiceNo: sale.efrisInvoiceNo ?? `URA-${sale.saleNumber}`,
        fiscalCode: sale.efrisFiscalCode ?? "FC-PENDING",
        verificationCode: sale.efrisVerificationCode ?? "VC-PENDING",
        issuedDate: new Date(sale.createdAt).toISOString(),
        paymentMethod: sale.paymentMethod,
        currency: "UGX",
        items,
        subtotalAmount: sale.subtotalAmount,
        totalTaxAmount: sale.taxAmount,
        netTotalAmount: sale.totalAmount,
        qrCodeUrl: sale.efrisQrCodeData,
      },
    };
  },
});

// Configure EFRIS credentials for a business
export const updateEfrisSettings = mutation({
  args: {
    businessId: v.id("businesses"),
    tin: v.string(),
    efrisDeviceId: v.string(),
    efrisKey: v.string(),
  },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.businessId, {
      tin: args.tin,
      efrisDeviceId: args.efrisDeviceId,
      efrisKey: args.efrisKey,
      isEfrisEnrolled: true,
      updatedAt: Date.now(),
    });
  },
});
