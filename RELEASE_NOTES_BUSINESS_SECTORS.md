# Business Sector Support

## Added

DUKA now supports 14 business sectors with vertical-aware configuration:

- Wholesale & Retail
- Food & Hospitality
- Agriculture & Agribusiness
- Manufacturing
- Automotive
- Personal Services
- Construction
- Transport & Logistics
- ICT & Digital
- Real Estate
- Financial Services
- Health
- Education
- Arts & Entertainment

Each sector provides product categories, subcategories, income categories, expense categories, recurring-expense suggestions, labels, and feature flags.

## Compatibility

Legacy IDs remain supported:

- `retail` and `wholesale` map to `wholesale_retail`
- `restaurant` maps to `food_hospitality`
- `salon` and `services` map to `personal_services`
- `clinic` maps to `health`

Existing product categories and Uganda-specific expense categories remain available, so existing records are not hidden or rewritten.

## Implementation

- `business_providers.dart` centralizes vertical-aware Riverpod providers.
- POS category filters include sector categories and existing product categories.
- Inventory product creation suggests categories from the current sector.
- Expense entry combines sector presets with Uganda-specific expense categories.
- Registration and business profile selection use canonical vertical IDs.

## Migration

No database migration is required. Categories are stored as strings in the existing JSON-backed local data model, and this release does not change that persisted schema.

## Validation

The business-sector and compatibility tests cover all 14 sectors and legacy ID mappings.
