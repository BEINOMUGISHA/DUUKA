import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

// Remote In-App Update Endpoint
export const getLatestAppVersion = query({
  args: {},
  handler: async (ctx) => {
    // In production, this can be read from a systemConfig table or static release manifest
    return {
      version: "1.0.1",
      buildNumber: 2,
      minSupportedVersion: "1.0.0",
      releaseDate: "2026-08-26",
      releaseNotes: "• Added Debtor Book (Ababanja) repayment tracking\n• Official MTN MoMo & Airtel Money Collections\n• SMS Reminder templates in English, Luganda & Runyankole\n• Real PDF receipts and CSV statements export\n• Performance optimizations for fast loading",
      downloadUrl: "https://github.com/BEINOMUGISHA/DUUKA/releases/latest",
      apkDirectUrl: "https://github.com/BEINOMUGISHA/DUUKA/releases/download/v1.0.1/duka-release.apk",
      playStoreUrl: "https://play.google.com/store/apps/details?id=com.duka.uganda",
      isMandatory: false,
    };
  },
});
