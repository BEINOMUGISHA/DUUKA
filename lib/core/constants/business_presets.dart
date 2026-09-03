/// Business-specific Income and Expense Presets
/// Provides pre-configured transaction categories for each business vertical

class BusinessPresets {
  final String verticalId;
  final String verticalName;
  final List<String> incomeCategories;
  final List<String> expenseCategories;
  final Map<String, String> recurringExpenses; // expense -> frequency

  const BusinessPresets({
    required this.verticalId,
    required this.verticalName,
    required this.incomeCategories,
    required this.expenseCategories,
    required this.recurringExpenses,
  });
}

final businessPresets = {
  // 1. WHOLESALE & RETAIL
  'wholesale_retail': BusinessPresets(
    verticalId: 'wholesale_retail',
    verticalName: 'Wholesale & Retail',
    incomeCategories: [
      'Retail Sales',
      'Wholesale Sales',
      'Returns & Refunds',
      'Delivery Charges',
      'Service Charges',
    ],
    expenseCategories: [
      'Stock Purchase',
      'Supplier Payments',
      'Rent / Shop Space',
      'Utilities (Electricity, Water)',
      'Staff Wages',
      'Transport & Delivery',
      'Advertising & Marketing',
      'Packaging Materials',
      'Shop Maintenance',
      'Insurance',
      'Licenses & Permits',
      'Bank Charges',
      'Mobile Money Fees',
    ],
    recurringExpenses: {
      'Rent / Shop Space': 'Monthly',
      'Utilities (Electricity, Water)': 'Monthly',
      'Staff Wages': 'Monthly',
      'Insurance': 'Monthly',
      'Licenses & Permits': 'Annual',
    },
  ),

  // 2. FOOD & HOSPITALITY
  'food_hospitality': BusinessPresets(
    verticalId: 'food_hospitality',
    verticalName: 'Food & Hospitality',
    incomeCategories: [
      'Food Sales',
      'Beverage Sales',
      'Room Revenue',
      'Catering Services',
      'Event Services',
      'Room Service',
      'Delivery Orders',
    ],
    expenseCategories: [
      'Food & Ingredients',
      'Beverages Purchase',
      'Staff Wages',
      'Rent / Premises',
      'Utilities (Electricity, Water, Gas)',
      'Kitchen Equipment Maintenance',
      'Food Packaging',
      'Advertising & Promotions',
      'Licenses & Health Permits',
      'Pest Control',
      'Cleaning & Sanitization',
      'Laundry & Linen',
      'Insurance',
      'Bank Charges',
    ],
    recurringExpenses: {
      'Staff Wages': 'Bi-weekly',
      'Rent / Premises': 'Monthly',
      'Utilities (Electricity, Water, Gas)': 'Monthly',
      'Pest Control': 'Monthly',
      'Licenses & Health Permits': 'Annual',
    },
  ),

  // 3. AGRICULTURE & AGRIBUSINESS
  'agriculture': BusinessPresets(
    verticalId: 'agriculture',
    verticalName: 'Agriculture & Agribusiness',
    incomeCategories: [
      'Crop Sales',
      'Livestock Sales',
      'Dairy Sales',
      'Seed Sales',
      'Livestock Services',
      'Farm Produce Trading',
    ],
    expenseCategories: [
      'Seeds & Seedlings',
      'Fertilizers',
      'Pesticides & Herbicides',
      'Animal Feed',
      'Veterinary Services',
      'Farm Labor',
      'Land Rent',
      'Water / Irrigation',
      'Farm Equipment Maintenance',
      'Transport & Market Fees',
      'Storage & Warehousing',
      'Packaging & Containers',
      'Insurance',
      'Bank Charges',
    ],
    recurringExpenses: {
      'Farm Labor': 'Weekly',
      'Animal Feed': 'Weekly',
      'Land Rent': 'Monthly',
      'Water / Irrigation': 'Monthly',
      'Insurance': 'Annual',
    },
  ),

  // 4. MANUFACTURING
  'manufacturing': BusinessPresets(
    verticalId: 'manufacturing',
    verticalName: 'Manufacturing',
    incomeCategories: [
      'Product Sales',
      'Bulk Orders',
      'Custom Orders',
      'Returns (Credit Notes)',
      'Scrap & Waste Sales',
    ],
    expenseCategories: [
      'Raw Materials',
      'Production Labor',
      'Factory Rent',
      'Utilities (Electricity, Water)',
      'Equipment Maintenance',
      'Production Tools & Supplies',
      'Quality Control',
      'Packaging & Labeling',
      'Transport & Logistics',
      'Safety Equipment',
      'Staff Wages',
      'Insurance',
      'Licenses & Permits',
      'Bank Charges',
    ],
    recurringExpenses: {
      'Production Labor': 'Bi-weekly',
      'Factory Rent': 'Monthly',
      'Utilities (Electricity, Water)': 'Monthly',
      'Staff Wages': 'Monthly',
      'Equipment Maintenance': 'Quarterly',
      'Insurance': 'Annual',
    },
  ),

  // 5. AUTOMOTIVE
  'automotive': BusinessPresets(
    verticalId: 'automotive',
    verticalName: 'Automotive',
    incomeCategories: [
      'Repair Services',
      'Spare Parts Sales',
      'Car Wash',
      'Accessories Sales',
      'Inspection Fees',
      'Tyre Services',
      'Labor Charges',
    ],
    expenseCategories: [
      'Spare Parts Inventory',
      'Tools & Equipment',
      'Shop Rent',
      'Utilities (Electricity, Water)',
      'Staff Wages',
      'Lubricants & Fluids',
      'Safety Equipment',
      'Cleaning Supplies',
      'Advertising',
      'Vehicle Maintenance',
      'Insurance',
      'Licenses & Permits',
      'Bank Charges',
    ],
    recurringExpenses: {
      'Shop Rent': 'Monthly',
      'Utilities (Electricity, Water)': 'Monthly',
      'Staff Wages': 'Bi-weekly',
      'Insurance': 'Monthly',
      'Licenses & Permits': 'Annual',
    },
  ),

  // 6. PERSONAL SERVICES
  'personal_services': BusinessPresets(
    verticalId: 'personal_services',
    verticalName: 'Personal Services',
    incomeCategories: [
      'Service Fees',
      'Product Sales',
      'Membership Fees',
      'Package Deals',
    ],
    expenseCategories: [
      'Salon / Shop Products',
      'Staff Wages',
      'Shop Rent',
      'Utilities (Electricity, Water)',
      'Equipment Maintenance',
      'Supplies & Consumables',
      'Hygiene & Sanitation',
      'Advertising & Promotions',
      'Uniforms',
      'Insurance',
      'Licenses & Health Permits',
      'Bank Charges',
    ],
    recurringExpenses: {
      'Staff Wages': 'Bi-weekly',
      'Shop Rent': 'Monthly',
      'Utilities (Electricity, Water)': 'Monthly',
      'Supplies & Consumables': 'Monthly',
      'Licenses & Health Permits': 'Annual',
    },
  ),

  // 7. CONSTRUCTION
  'construction': BusinessPresets(
    verticalId: 'construction',
    verticalName: 'Construction',
    incomeCategories: [
      'Project Payments',
      'Material Sales',
      'Labor Contract',
      'Equipment Rental',
      'Consultation Fees',
    ],
    expenseCategories: [
      'Building Materials',
      'Labor Costs',
      'Equipment Rental',
      'Transport & Logistics',
      'Tools & Equipment',
      'Safety Equipment',
      'Site Office Rent',
      'Utilities',
      'Insurance',
      'Licenses & Permits',
      'Subcontractor Payments',
      'Fuel',
      'Bank Charges',
    ],
    recurringExpenses: {
      'Labor Costs': 'Weekly',
      'Equipment Rental': 'Monthly',
      'Site Office Rent': 'Monthly',
      'Insurance': 'Monthly',
      'Licenses & Permits': 'Annual',
    },
  ),

  // 8. TRANSPORT & LOGISTICS
  'transport_logistics': BusinessPresets(
    verticalId: 'transport_logistics',
    verticalName: 'Transport & Logistics',
    incomeCategories: [
      'Passenger Revenue',
      'Cargo Revenue',
      'Delivery Services',
      'Express Delivery',
      'Warehousing Fees',
      'Handling Fees',
    ],
    expenseCategories: [
      'Fuel & Diesel',
      'Vehicle Maintenance',
      'Driver Wages',
      'Vehicle Insurance',
      'Spare Parts',
      'Licenses & Permits',
      'Warehouse Rent',
      'Utilities',
      'Loading & Unloading Labor',
      'Transport Fees (for subcontracts)',
      'Equipment Maintenance',
      'Cleaning & Sanitization',
      'Bank Charges',
    ],
    recurringExpenses: {
      'Fuel & Diesel': 'Weekly',
      'Driver Wages': 'Weekly',
      'Vehicle Maintenance': 'Monthly',
      'Vehicle Insurance': 'Monthly',
      'Warehouse Rent': 'Monthly',
      'Licenses & Permits': 'Annual',
    },
  ),

  // 9. ICT & DIGITAL
  'ict_digital': BusinessPresets(
    verticalId: 'ict_digital',
    verticalName: 'ICT & Digital',
    incomeCategories: [
      'Hardware Sales',
      'Software Sales',
      'Repair Services',
      'Support Services',
      'Training Services',
      'Consulting Fees',
      'Airtime / Data Top-ups',
    ],
    expenseCategories: [
      'Hardware Inventory',
      'Software Licenses',
      'Shop Rent',
      'Utilities (Electricity, Internet)',
      'Staff Wages',
      'Tools & Test Equipment',
      'Spare Parts',
      'Internet Subscription',
      'Cloud Services',
      'Advertising & Marketing',
      'Insurance',
      'Licenses & Permits',
      'Bank Charges',
    ],
    recurringExpenses: {
      'Shop Rent': 'Monthly',
      'Utilities (Electricity, Internet)': 'Monthly',
      'Staff Wages': 'Bi-weekly',
      'Internet Subscription': 'Monthly',
      'Software Licenses': 'Annual',
      'Insurance': 'Annual',
    },
  ),

  // 10. REAL ESTATE
  'real_estate': BusinessPresets(
    verticalId: 'real_estate',
    verticalName: 'Real Estate',
    incomeCategories: [
      'Rental Income',
      'Sales Commission',
      'Property Management Fees',
      'Lease Deposits',
      'Service Charges',
    ],
    expenseCategories: [
      'Property Maintenance',
      'Cleaning & Sanitation',
      'Property Insurance',
      'Property Taxes',
      'Office Rent',
      'Staff Wages',
      'Utilities (for common areas)',
      'Marketing & Advertising',
      'Legal & Professional Fees',
      'Licenses & Permits',
      'Security Services',
      'Tenant Management Software',
      'Bank Charges',
    ],
    recurringExpenses: {
      'Property Maintenance': 'Monthly',
      'Cleaning & Sanitation': 'Weekly',
      'Property Insurance': 'Annual',
      'Property Taxes': 'Annual',
      'Office Rent': 'Monthly',
      'Security Services': 'Monthly',
    },
  ),

  // 11. FINANCIAL SERVICES
  'financial_services': BusinessPresets(
    verticalId: 'financial_services',
    verticalName: 'Financial Services',
    incomeCategories: [
      'Loan Interest',
      'Membership Fees',
      'Service Charges',
      'Investment Returns',
      'Commission Income',
      'Late Payment Fees',
    ],
    expenseCategories: [
      'Staff Wages',
      'Office Rent',
      'Utilities (Electricity, Internet)',
      'Member Benefits',
      'Insurance',
      'Audit & Compliance',
      'Software & Systems',
      'Training & Development',
      'Marketing & Advertising',
      'Office Equipment',
      'Licenses & Permits',
      'Bank Charges',
      'Bad Debts Provision',
    ],
    recurringExpenses: {
      'Staff Wages': 'Bi-weekly',
      'Office Rent': 'Monthly',
      'Utilities (Electricity, Internet)': 'Monthly',
      'Insurance': 'Annual',
      'Audit & Compliance': 'Annual',
      'Software & Systems': 'Annual',
    },
  ),

  // 12. HEALTH
  'health': BusinessPresets(
    verticalId: 'health',
    verticalName: 'Health',
    incomeCategories: [
      'Consultation Fees',
      'Medical Services',
      'Procedure Fees',
      'Laboratory Tests',
      'Medicine Sales',
      'Medical Supply Sales',
      'Insurance Claims',
    ],
    expenseCategories: [
      'Medical Supplies',
      'Medicines & Pharmaceuticals',
      'Staff Wages',
      'Clinic Rent',
      'Utilities (Electricity, Water)',
      'Medical Equipment Maintenance',
      'Sterilization & Sanitation',
      'Licenses & Health Permits',
      'Insurance',
      'Training & Professional Development',
      'Waste Management',
      'Advertising',
      'Bank Charges',
    ],
    recurringExpenses: {
      'Staff Wages': 'Bi-weekly',
      'Clinic Rent': 'Monthly',
      'Utilities (Electricity, Water)': 'Monthly',
      'Sterilization & Sanitation': 'Monthly',
      'Licenses & Health Permits': 'Annual',
      'Insurance': 'Annual',
    },
  ),

  // 13. EDUCATION
  'education': BusinessPresets(
    verticalId: 'education',
    verticalName: 'Education',
    incomeCategories: [
      'Tuition Fees',
      'Registration Fees',
      'Examination Fees',
      'Teaching Services',
      'Course Materials Sales',
      'Facility Rental',
    ],
    expenseCategories: [
      'Staff Salaries',
      'Premises Rent',
      'Utilities (Electricity, Water, Internet)',
      'Teaching Materials',
      'Textbooks & References',
      'Equipment & Laboratory Setup',
      'Maintenance & Repairs',
      'Insurance',
      'Licenses & Permits',
      'Student Support Services',
      'Cleaning & Sanitation',
      'Advertising & Recruitment',
      'Bank Charges',
    ],
    recurringExpenses: {
      'Staff Salaries': 'Monthly',
      'Premises Rent': 'Monthly',
      'Utilities (Electricity, Water, Internet)': 'Monthly',
      'Cleaning & Sanitation': 'Weekly',
      'Insurance': 'Annual',
      'Licenses & Permits': 'Annual',
    },
  ),

  // 14. ARTS & ENTERTAINMENT
  'arts_entertainment': BusinessPresets(
    verticalId: 'arts_entertainment',
    verticalName: 'Arts & Entertainment',
    incomeCategories: [
      'Event Services',
      'Photography / Videography',
      'Production Services',
      'Ticket Sales',
      'Venue Rental',
      'Product Sales',
      'Commissions',
    ],
    expenseCategories: [
      'Equipment & Props',
      'Artist Fees',
      'Production Costs',
      'Venue Rent',
      'Insurance',
      'Licenses & Permits',
      'Marketing & Promotion',
      'Transportation',
      'Catering (for events)',
      'Software & Creative Tools',
      'Staff Wages',
      'Office Rent',
      'Bank Charges',
    ],
    recurringExpenses: {
      'Office Rent': 'Monthly',
      'Software & Creative Tools': 'Monthly',
      'Staff Wages': 'Bi-weekly',
      'Insurance': 'Annual',
      'Licenses & Permits': 'Annual',
    },
  ),
};

BusinessPresets? getPresetsFor(String verticalId) =>
    businessPresets[verticalId];

List<String> getIncomeCategories(String verticalId) =>
    businessPresets[verticalId]?.incomeCategories ?? [];

List<String> getExpenseCategories(String verticalId) =>
    businessPresets[verticalId]?.expenseCategories ?? [];

Map<String, String> getRecurringExpenses(String verticalId) =>
    businessPresets[verticalId]?.recurringExpenses ?? {};
