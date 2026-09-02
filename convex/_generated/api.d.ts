/* eslint-disable */
/**
 * Generated `api` utility.
 *
 * THIS CODE IS AUTOMATICALLY GENERATED.
 *
 * To regenerate, run `npx convex dev`.
 * @module
 */

import type * as auth from "../auth.js";
import type * as credit from "../credit.js";
import type * as customers from "../customers.js";
import type * as debts from "../debts.js";
import type * as efris from "../efris.js";
import type * as invoices from "../invoices.js";
import type * as payments from "../payments.js";
import type * as products from "../products.js";
import type * as reports from "../reports.js";
import type * as sales from "../sales.js";
import type * as sms from "../sms.js";
import type * as suppliers from "../suppliers.js";
import type * as sync from "../sync.js";
import type * as system from "../system.js";
import type * as transactions from "../transactions.js";

import type {
  ApiFromModules,
  FilterApi,
  FunctionReference,
} from "convex/server";

declare const fullApi: ApiFromModules<{
  auth: typeof auth;
  credit: typeof credit;
  customers: typeof customers;
  debts: typeof debts;
  efris: typeof efris;
  invoices: typeof invoices;
  payments: typeof payments;
  products: typeof products;
  reports: typeof reports;
  sales: typeof sales;
  sms: typeof sms;
  suppliers: typeof suppliers;
  sync: typeof sync;
  system: typeof system;
  transactions: typeof transactions;
}>;

/**
 * A utility for referencing Convex functions in your app's public API.
 *
 * Usage:
 * ```js
 * const myFunctionReference = api.myModule.myFunction;
 * ```
 */
export declare const api: FilterApi<
  typeof fullApi,
  FunctionReference<any, "public">
>;

/**
 * A utility for referencing Convex functions in your app's internal API.
 *
 * Usage:
 * ```js
 * const myFunctionReference = internal.myModule.myFunction;
 * ```
 */
export declare const internal: FilterApi<
  typeof fullApi,
  FunctionReference<any, "internal">
>;

export declare const components: {};
