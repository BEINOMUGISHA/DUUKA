import 'package:flutter/material.dart';

/// Comprehensive Business Vertical Definition
/// Supports 14 business sectors with industry-specific configuration
class BusinessVertical {
  final String id;
  final String name;
  final String description;
  final String fullDescription;
  final IconData icon;
  final String salesLabel;
  final String stockLabel;
  final String customerLabel;
  final Set<String> enabledFeatures;
  final String category; // Category grouping
  final List<String> examples; // Example businesses

  const BusinessVertical({
    required this.id,
    required this.name,
    required this.description,
    required this.fullDescription,
    required this.icon,
    required this.salesLabel,
    required this.stockLabel,
    required this.customerLabel,
    required this.enabledFeatures,
    required this.category,
    required this.examples,
  });
}

// ============================================================================
// ALL 14 BUSINESS SECTORS WITH FULL CONFIGURATION
// ============================================================================

const businessVerticals = [
  // 1. WHOLESALE & RETAIL
  BusinessVertical(
    id: 'wholesale_retail',
    name: 'Wholesale & Retail',
    description: 'Shops, supermarkets, boutiques, pharmacies',
    fullDescription:
        'Retail and wholesale businesses including shops, supermarkets, boutiques, hardware shops, electronics, spare parts dealers, and pharmacies.',
    icon: Icons.storefront_rounded,
    salesLabel: 'Sales',
    stockLabel: 'Inventory',
    customerLabel: 'Customers',
    enabledFeatures: {
      'inventory',
      'branches',
      'credit',
      'suppliers',
      'sms',
      'reports',
      'efris'
    },
    category: 'Retail & Commerce',
    examples: [
      'Supermarket',
      'Electronics Shop',
      'Hardware Store',
      'Pharmacy',
      'Boutique',
      'Spare Parts Dealer'
    ],
  ),

  // 2. FOOD & HOSPITALITY
  BusinessVertical(
    id: 'food_hospitality',
    name: 'Food & Hospitality',
    description: 'Restaurants, cafés, hotels, catering, food stalls',
    fullDescription:
        'Food service businesses including restaurants, cafés, food stalls, bakeries, catering services, hotels, and lodges.',
    icon: Icons.restaurant_rounded,
    salesLabel: 'Orders',
    stockLabel: 'Ingredients',
    customerLabel: 'Guests',
    enabledFeatures: {
      'inventory',
      'credit',
      'sms',
      'reports',
      'efris',
      'branches'
    },
    category: 'Food & Beverage',
    examples: [
      'Restaurant',
      'Café',
      'Food Stall',
      'Bakery',
      'Hotel',
      'Catering',
      'Lodges'
    ],
  ),

  // 3. AGRICULTURE & AGRIBUSINESS
  BusinessVertical(
    id: 'agriculture',
    name: 'Agriculture & Agribusiness',
    description: 'Farming, dairy, poultry, produce dealers, agro-input shops',
    fullDescription:
        'Agriculture and agribusiness including poultry, dairy, piggery, crop farming, produce dealers, and agro-input shops.',
    icon: Icons.eco_rounded,
    salesLabel: 'Harvest Sales',
    stockLabel: 'Stock',
    customerLabel: 'Buyers',
    enabledFeatures: {'inventory', 'credit', 'sms', 'reports', 'suppliers'},
    category: 'Agriculture',
    examples: [
      'Poultry Farm',
      'Dairy Farm',
      'Piggery',
      'Crop Farming',
      'Produce Dealer',
      'Agro-input Shop'
    ],
  ),

  // 4. MANUFACTURING
  BusinessVertical(
    id: 'manufacturing',
    name: 'Manufacturing',
    description:
        'Furniture, metal fabrication, detergents, clothing, food processing',
    fullDescription:
        'Manufacturing businesses including furniture production, metal fabrication, detergent manufacturing, clothing production, food processing, and construction materials.',
    icon: Icons.factory_rounded,
    salesLabel: 'Production Sales',
    stockLabel: 'Raw Materials',
    customerLabel: 'Buyers',
    enabledFeatures: {
      'inventory',
      'production',
      'branches',
      'credit',
      'suppliers',
      'sms',
      'reports'
    },
    category: 'Manufacturing',
    examples: [
      'Furniture Making',
      'Metal Fabrication',
      'Detergent Production',
      'Clothing Factory',
      'Food Processing',
      'Construction Materials'
    ],
  ),

  // 5. AUTOMOTIVE
  BusinessVertical(
    id: 'automotive',
    name: 'Automotive',
    description: 'Garages, car wash, tyre shops, motorcycle repair',
    fullDescription:
        'Automotive services including garages, car wash, tyre shops, spare-parts dealers, and motorcycle repair services.',
    icon: Icons.car_repair_rounded,
    salesLabel: 'Services & Sales',
    stockLabel: 'Spare Parts',
    customerLabel: 'Customers',
    enabledFeatures: {'inventory', 'credit', 'sms', 'reports', 'suppliers'},
    category: 'Automotive',
    examples: [
      'Garage',
      'Car Wash',
      'Tyre Shop',
      'Spare Parts Dealer',
      'Motorcycle Repair'
    ],
  ),

  // 6. PERSONAL SERVICES
  BusinessVertical(
    id: 'personal_services',
    name: 'Personal Services',
    description: 'Salons, barbershops, beauty, laundry, cleaning services',
    fullDescription:
        'Personal service businesses including salons, barbershops, beauty shops, laundry services, and cleaning services.',
    icon: Icons.content_cut_rounded,
    salesLabel: 'Services',
    stockLabel: 'Products & Supplies',
    customerLabel: 'Clients',
    enabledFeatures: {'inventory', 'credit', 'sms', 'reports'},
    category: 'Services',
    examples: [
      'Salon',
      'Barbershop',
      'Beauty Shop',
      'Laundry Service',
      'Cleaning Service'
    ],
  ),

  // 7. CONSTRUCTION
  BusinessVertical(
    id: 'construction',
    name: 'Construction',
    description:
        'Contractors, plumbers, electricians, painters, brick/block makers',
    fullDescription:
        'Construction services including contractors, plumbers, electricians, painters, brick/block makers, and other construction specialists.',
    icon: Icons.construction_rounded,
    salesLabel: 'Project Income',
    stockLabel: 'Materials',
    customerLabel: 'Clients',
    enabledFeatures: {
      'inventory',
      'credit',
      'sms',
      'reports',
      'suppliers',
      'branches'
    },
    category: 'Construction & Services',
    examples: [
      'Contractor',
      'Plumber',
      'Electrician',
      'Painter',
      'Brick Maker',
      'Carpenter'
    ],
  ),

  // 8. TRANSPORT & LOGISTICS
  BusinessVertical(
    id: 'transport_logistics',
    name: 'Transport & Logistics',
    description: 'Taxi operators, delivery, courier, boda-related businesses',
    fullDescription:
        'Transport and logistics businesses including delivery services, taxi operators, trucking, courier services, and boda-related businesses.',
    icon: Icons.local_shipping_rounded,
    salesLabel: 'Transport Revenue',
    stockLabel: 'Fleet',
    customerLabel: 'Clients',
    enabledFeatures: {'credit', 'sms', 'reports', 'inventory'},
    category: 'Transport & Logistics',
    examples: [
      'Taxi Service',
      'Delivery Business',
      'Courier Service',
      'Trucking',
      'Boda Operator'
    ],
  ),

  // 9. ICT & DIGITAL
  BusinessVertical(
    id: 'ict_digital',
    name: 'ICT & Digital',
    description: 'Computer shops, software, internet cafés, phone repair',
    fullDescription:
        'ICT and digital businesses including computer shops, software companies, internet cafés, digital marketing, and phone repair services.',
    icon: Icons.computer_rounded,
    salesLabel: 'Sales & Services',
    stockLabel: 'Inventory',
    customerLabel: 'Customers',
    enabledFeatures: {'inventory', 'credit', 'sms', 'reports', 'suppliers'},
    category: 'Technology',
    examples: [
      'Computer Shop',
      'Software Company',
      'Internet Café',
      'Digital Marketing',
      'Phone Repair',
      'IT Support'
    ],
  ),

  // 10. REAL ESTATE
  BusinessVertical(
    id: 'real_estate',
    name: 'Real Estate',
    description: 'Property agents, rentals management, construction services',
    fullDescription:
        'Real estate businesses including property agents, rental management, property sales, and construction/property services.',
    icon: Icons.apartment_rounded,
    salesLabel: 'Commissions & Income',
    stockLabel: 'Properties',
    customerLabel: 'Clients',
    enabledFeatures: {'credit', 'sms', 'reports'},
    category: 'Real Estate',
    examples: [
      'Property Agent',
      'Rental Management',
      'Property Sales',
      'Construction Services'
    ],
  ),

  // 11. FINANCIAL SERVICES
  BusinessVertical(
    id: 'financial_services',
    name: 'Financial Services',
    description: 'SACCOs, savings groups, insurance, financial agents',
    fullDescription:
        'Financial services including SACCOs, savings groups, insurance agencies, and financial advisors.',
    icon: Icons.account_balance_rounded,
    salesLabel: 'Income',
    stockLabel: 'Funds',
    customerLabel: 'Members',
    enabledFeatures: {'credit', 'sms', 'reports'},
    category: 'Financial Services',
    examples: [
      'SACCO',
      'Savings Group',
      'Insurance Agent',
      'Financial Advisor'
    ],
  ),

  // 12. HEALTH
  BusinessVertical(
    id: 'health',
    name: 'Health',
    description: 'Clinics, laboratories, drug shops, dental practices',
    fullDescription:
        'Health service businesses including clinics, laboratories, drug shops, dental practices, and other health-service providers.',
    icon: Icons.medical_services_rounded,
    salesLabel: 'Services & Sales',
    stockLabel: 'Medical Stock',
    customerLabel: 'Patients',
    enabledFeatures: {'inventory', 'credit', 'sms', 'reports'},
    category: 'Healthcare',
    examples: [
      'Clinic',
      'Laboratory',
      'Drug Shop',
      'Dental Practice',
      'Health Center'
    ],
  ),

  // 13. EDUCATION
  BusinessVertical(
    id: 'education',
    name: 'Education',
    description: 'Nursery/primary schools, tutoring, vocational institutions',
    fullDescription:
        'Education businesses including nursery and primary schools, tutoring centres, and vocational training institutions.',
    icon: Icons.school_rounded,
    salesLabel: 'Fees',
    stockLabel: 'Materials',
    customerLabel: 'Students',
    enabledFeatures: {'credit', 'sms', 'reports', 'inventory'},
    category: 'Education',
    examples: [
      'Nursery School',
      'Primary School',
      'Tutoring Centre',
      'Vocational School',
      'Online Course Platform'
    ],
  ),

  // 14. ARTS & ENTERTAINMENT
  BusinessVertical(
    id: 'arts_entertainment',
    name: 'Arts & Entertainment',
    description: 'Events, photography, video, entertainment, crafts',
    fullDescription:
        'Arts and entertainment including events organization, photography, video production, entertainment venues, and craft businesses.',
    icon: Icons.theater_comedy_rounded,
    salesLabel: 'Sales & Services',
    stockLabel: 'Products',
    customerLabel: 'Clients',
    enabledFeatures: {'credit', 'sms', 'reports', 'inventory'},
    category: 'Arts & Entertainment',
    examples: [
      'Event Planner',
      'Photography',
      'Video Production',
      'Entertainment Venue',
      'Craft Business'
    ],
  ),
];

/// Get business vertical by ID
BusinessVertical businessVerticalFor(String id) {
  if (id == 'retail' || id == 'other' || id == 'unknown') {
    return _legacyRetailFallback;
  }

  final canonicalId = canonicalBusinessVerticalId(id);
  return businessVerticals.firstWhere(
    (vertical) => vertical.id == canonicalId,
    orElse: () => _legacyRetailFallback,
  );
}

const _legacyRetailFallback = BusinessVertical(
  id: 'retail',
  name: 'Retail / Shop',
  description: 'Sell products and manage stock',
  fullDescription: 'Legacy retail business configuration.',
  icon: Icons.storefront_rounded,
  salesLabel: 'Sales',
  stockLabel: 'Inventory',
  customerLabel: 'Customers',
  enabledFeatures: {'inventory', 'credit', 'suppliers', 'sms'},
  category: 'Retail & Commerce',
  examples: ['Shop'],
);

String canonicalBusinessVerticalId(String? id) {
  switch (id) {
    case 'retail':
    case 'wholesale':
      return 'wholesale_retail';
    case 'restaurant':
      return 'food_hospitality';
    case 'salon':
    case 'services':
      return 'personal_services';
    case 'clinic':
      return 'health';
    case 'wholesale_retail':
    case 'food_hospitality':
    case 'agriculture':
    case 'manufacturing':
    case 'automotive':
    case 'personal_services':
    case 'construction':
    case 'transport_logistics':
    case 'ict_digital':
    case 'real_estate':
    case 'financial_services':
    case 'health':
    case 'education':
    case 'arts_entertainment':
      return id!;
    case 'other':
    case null:
      return 'wholesale_retail';
    default:
      return 'wholesale_retail';
  }
}

/// Get all verticals by category
List<BusinessVertical> businessVerticalsByCategory(String category) =>
    businessVerticals.where((v) => v.category == category).toList();

/// Get unique categories
Set<String> getBusinessCategories() =>
    businessVerticals.map((v) => v.category).toSet();

/// Get vertical by name (case-insensitive)
BusinessVertical? businessVerticalByName(String name) {
  try {
    return businessVerticals.firstWhere(
      (v) => v.name.toLowerCase() == name.toLowerCase(),
    );
  } catch (e) {
    return null;
  }
}
