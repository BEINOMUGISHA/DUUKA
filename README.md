# DUUKA - Uganda SME Finance & Inventory SaaS (Flutter + Convex)

DUUKA is a cross-platform, offline-first SaaS application designed specifically for Ugandan SMEs to manage POS sales, income, expenses, stock, debtors (credit sales), and EFRIS / URA tax compliance in real-time.

---

## 🇺🇬 Local Languages & Uganda Market Features

1. **Multi-Language Localization:**
   - **English (Default):** Full international business terminology.
   - **Luganda (Second Main Language):** Complete end-to-end vernacular translation for SME traders in Kampala, Wakiso, Mukono, and the Central region (*"Tunda"*, *"Ebbanja"*, *"Sttoka"*, *"Ssente Ezafulumye"*, *"Alipoota"*).
   - **Runyankole / Runyakitara:** Regional option for Western Uganda traders (*"Guza"*, *"Omwenda"*, *"Sitoka"*, *"Esente Ezashohoire"*).
   - Instant 1-tap language switching from the top header and Settings menu.

2. **First-Class Mobile Money:** Instant logging and tracking for **MTN MoMo** and **Airtel Money**, including USSD reference capture.
3. **Debtor Book ("Ababanja" / Credit Sales):** Built-in credit sales ledger with automatic customer balance tracking and multi-lingual SMS payment reminder templates (English, Luganda, and Runyankole).
4. **URA EFRIS e-Invoicing Compliance:** Fiscal invoice codes, 18% VAT automated computation, and QR code generation for receipt verification.
5. **Offline-First Resilience:** Drift (SQLite) local queue engine. Staff can make sales and log expenses completely offline; mutations sync to Convex Cloud automatically as soon as internet connection is restored.
6. **Delta-Based Stock Tracking:** Stock updates sync as mathematical deltas (`+/- qty`), eliminating write collisions when multiple staff members sell goods concurrently offline.
7. **Local Preset Categories:** 1-tap presets for Boda/Taxi transport (*"Entambula"*), Market dues (*"Panyiiti / Emisolo gya katale"*), Airtime/Internet (*"Kkaadi y'essimu / Data"*), Staff Lunch (*"Emmere y'abakozi"*), and Umeme/Water utilities (*"Amasannyalaze / Amazzi"*).

---

## 🏗️ Project Architecture

```
DUKA/
├── convex/                          # Convex Serverless Backend (TypeScript)
│   ├── schema.ts                   # Multi-tenant schema indexed by businessId
│   ├── auth.ts                     # Phone + PIN authentication & Onboarding
│   ├── products.ts                 # Inventory CRUD & delta stock processor
│   ├── sales.ts                    # POS checkout, EFRIS generator & debtor tracking
│   ├── credit.ts                   # Debtor Book & multi-lingual SMS reminders
│   ├── transactions.ts             # Daily cashbook (income & expenses)
│   ├── reports.ts                  # P&L, cash flow by payment method & stock valuation
│   ├── efris.ts                    # URA EFRIS fiscal formatting & QR builder
│   ├── payments.ts                 # MTN MoMo & Airtel Money integrations
│   └── sync.ts                     # Mobile offline queue batch sync mutation
│
├── lib/                             # Flutter Mobile & Desktop Client
│   ├── core/
│   │   ├── localization/           # AppTranslations dictionary (English, Luganda, Runyankole)
│   │   ├── constants/              # Uganda presets, categories & local strings
│   │   ├── database/               # Drift SQLite local tables & offline database
│   │   ├── network/                # Convex HTTP & reactive client bridge
│   │   ├── providers/              # Riverpod StateNotifier providers & ref.tr extension
│   │   ├── sync/                   # Offline SyncEngine & queue manager
│   │   ├── theme/                  # Uganda SME Forest Emerald design system
│   │   └── utils/                  # UGX CurrencyFormatter
│   │
│   ├── features/
│   │   ├── auth/                   # Phone + PIN login & onboarding wizard
│   │   ├── dashboard/              # Daily KPIs, MoMo vs Cash breakdown, low-stock alerts
│   │   ├── pos/                    # Quick-sale POS, item cart & shareable receipt
│   │   ├── inventory/              # Product catalog & stock delta adjustments
│   │   ├── credit/                 # Debtor Book ("Ababanja") & SMS reminders
│   │   ├── expenses/               # 1-tap Ugandan preset expense cashbook
│   │   ├── reports/                # Profit & Loss statement & URA VAT summary
│   │   └── settings/               # Business details, staff roles & offline sync queue
│   │
│   └── main.dart                   # Riverpod ProviderScope & BottomNavigation shell
│
├── pubspec.yaml                     # Flutter dependencies (Riverpod, Drift, QR, Share)
└── package.json                    # Convex backend dependencies
```

---

## 🚀 Getting Started

### 1. Backend (Convex) Setup

1. Install Convex CLI & dependencies:
   ```bash
   npm install
   ```
2. Start the Convex development server:
   ```bash
   npx convex dev
   ```
3. Copy the deployment URL from the Convex dashboard or `.env.local` and pass it to Flutter:
   ```bash
   flutter run --dart-define=CONVEX_URL=https://your-project.convex.cloud
   ```
   You can also set a default in the app by editing the fallback value in `lib/core/providers/app_providers.dart`.

### 2. Frontend (Flutter) Setup

1. Fetch Flutter dependencies:
   ```bash
   flutter pub get
   ```
2. Run the application:
   ```bash
   flutter run --dart-define=CONVEX_URL=https://your-project.convex.cloud
   ```

---

## 📱 Language Switching in Action

Users can switch languages anytime from the **top-right app bar pill (`🇬🇧 EN` / `🇺🇬 LG`)** or inside the **Settings menu (`Enteekateeka`)**:
- All navigation tabs, POS screens, carts, receipts, inventory lists, debtor statements, cashbooks, P&L reports, and onboarding dialogs instantly translate without requiring an app restart.
