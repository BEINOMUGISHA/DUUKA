/// Comprehensive Business Category Hierarchies
/// Provides industry-specific product and service categories for each business vertical

class BusinessCategoryHierarchy {
  final String verticalId;
  final String verticalName;
  final List<String> mainCategories;
  final Map<String, List<String>> subcategories;

  const BusinessCategoryHierarchy({
    required this.verticalId,
    required this.verticalName,
    required this.mainCategories,
    required this.subcategories,
  });
}

final businessCategoryHierarchies = {
  // 1. WHOLESALE & RETAIL
  'wholesale_retail': BusinessCategoryHierarchy(
    verticalId: 'wholesale_retail',
    verticalName: 'Wholesale & Retail',
    mainCategories: [
      'Electronics',
      'Clothing & Textiles',
      'Home & Furniture',
      'Hardware & Building',
      'Pharmacy & Medical',
      'Food & Beverages',
      'Personal Care',
      'Books & Stationery',
    ],
    subcategories: {
      'Electronics': [
        'Mobile Phones',
        'Laptops & Computers',
        'Accessories',
        'Power Banks',
        'Chargers',
      ],
      'Clothing & Textiles': [
        'Men\'s Clothing',
        'Women\'s Clothing',
        'Children\'s Clothing',
        'Shoes & Footwear',
        'Fabrics & Textiles',
      ],
      'Home & Furniture': [
        'Beds & Mattresses',
        'Sofas & Chairs',
        'Tables & Desks',
        'Kitchenware',
        'Decorations',
      ],
      'Hardware & Building': [
        'Cement & Concrete',
        'Nails & Fasteners',
        'Paints & Varnish',
        'Pipes & Fittings',
        'Doors & Windows',
      ],
      'Pharmacy & Medical': [
        'Tablets & Capsules',
        'Syrups & Liquids',
        'Injections',
        'Medical Supplies',
        'First Aid Kits',
      ],
      'Food & Beverages': [
        'Grains & Cereals',
        'Cooking Oil',
        'Sugar & Salt',
        'Tea & Coffee',
        'Beverages',
      ],
      'Personal Care': [
        'Soaps & Detergents',
        'Shampoos & Conditioners',
        'Toothpastes',
        'Cosmetics',
        'Deodorants',
      ],
      'Books & Stationery': [
        'Notebooks & Pads',
        'Pens & Pencils',
        'Books',
        'Printing Paper',
        'Office Supplies',
      ],
    },
  ),

  // 2. FOOD & HOSPITALITY
  'food_hospitality': BusinessCategoryHierarchy(
    verticalId: 'food_hospitality',
    verticalName: 'Food & Hospitality',
    mainCategories: [
      'Meals & Main Courses',
      'Beverages',
      'Desserts & Pastries',
      'Snacks',
      'Accommodation',
      'Catering Services',
    ],
    subcategories: {
      'Meals & Main Courses': [
        'Ugandan Dishes',
        'African Cuisine',
        'International Dishes',
        'Vegetarian Meals',
        'Rice & Carbs',
      ],
      'Beverages': [
        'Soft Drinks',
        'Alcoholic Drinks',
        'Tea & Coffee',
        'Fresh Juices',
        'Bottled Water',
      ],
      'Desserts & Pastries': [
        'Cakes & Pastries',
        'Donuts & Bread',
        'Ice Cream',
        'Chocolates',
        'Cookies',
      ],
      'Snacks': [
        'Chips & Crisps',
        'Fried Appetizers',
        'Sandwiches',
        'Roasted Items',
        'Nuts & Dried Fruits',
      ],
      'Accommodation': [
        'Single Rooms',
        'Double Rooms',
        'Family Suites',
        'Dormitory Beds',
      ],
      'Catering Services': [
        'Full Meal Packages',
        'Beverages Only',
        'Snacks & Appetizers',
        'Desserts',
        'Event Catering',
      ],
    },
  ),

  // 3. AGRICULTURE & AGRIBUSINESS
  'agriculture': BusinessCategoryHierarchy(
    verticalId: 'agriculture',
    verticalName: 'Agriculture & Agribusiness',
    mainCategories: [
      'Crops',
      'Livestock',
      'Dairy Products',
      'Agricultural Inputs',
      'Farm Equipment',
    ],
    subcategories: {
      'Crops': [
        'Maize & Cereals',
        'Beans & Pulses',
        'Vegetables',
        'Fruits',
        'Cash Crops',
      ],
      'Livestock': [
        'Poultry',
        'Cattle',
        'Goats & Sheep',
        'Pigs',
        'Rabbits',
      ],
      'Dairy Products': [
        'Fresh Milk',
        'Yogurt',
        'Cheese',
        'Ghee & Butter',
        'Ice Cream',
      ],
      'Agricultural Inputs': [
        'Seeds',
        'Fertilizers',
        'Pesticides',
        'Herbicides',
        'Animal Feed',
      ],
      'Farm Equipment': [
        'Hand Tools',
        'Power Tools',
        'Tractors & Machinery',
        'Irrigation Equipment',
        'Storage Containers',
      ],
    },
  ),

  // 4. MANUFACTURING
  'manufacturing': BusinessCategoryHierarchy(
    verticalId: 'manufacturing',
    verticalName: 'Manufacturing',
    mainCategories: [
      'Raw Materials',
      'Finished Products',
      'Work in Progress',
      'Production Supplies',
    ],
    subcategories: {
      'Raw Materials': [
        'Metals & Steel',
        'Wood & Timber',
        'Fabrics & Textiles',
        'Plastics & Polymers',
        'Chemicals & Additives',
      ],
      'Finished Products': [
        'Furniture',
        'Metal Products',
        'Clothing & Garments',
        'Detergents & Chemicals',
        'Food Products',
      ],
      'Work in Progress': [
        'Partially Assembled Units',
        'Quality Control Items',
        'Awaiting Finishing',
      ],
      'Production Supplies': [
        'Safety Equipment',
        'Packaging Materials',
        'Tools & Equipment',
        'Maintenance Supplies',
      ],
    },
  ),

  // 5. AUTOMOTIVE
  'automotive': BusinessCategoryHierarchy(
    verticalId: 'automotive',
    verticalName: 'Automotive',
    mainCategories: [
      'Spare Parts',
      'Accessories',
      'Services',
      'Fluids & Lubricants',
      'Tyres & Batteries',
    ],
    subcategories: {
      'Spare Parts': [
        'Engine Parts',
        'Transmission Parts',
        'Brake Components',
        'Electrical Components',
        'Body Parts',
      ],
      'Accessories': [
        'Seat Covers',
        'Floor Mats',
        'Air Fresheners',
        'Car Audio',
        'Security Systems',
      ],
      'Services': [
        'Car Wash',
        'Oil Change',
        'Repair Work',
        'Inspection',
        'Maintenance',
      ],
      'Fluids & Lubricants': [
        'Engine Oil',
        'Coolants',
        'Brake Fluid',
        'Gear Oil',
        'Grease',
      ],
      'Tyres & Batteries': [
        'Tyres',
        'Batteries',
        'Tyre Repair',
        'Battery Accessories',
      ],
    },
  ),

  // 6. PERSONAL SERVICES
  'personal_services': BusinessCategoryHierarchy(
    verticalId: 'personal_services',
    verticalName: 'Personal Services',
    mainCategories: [
      'Hair Services',
      'Beauty Treatments',
      'Laundry & Cleaning',
      'Products & Supplies',
    ],
    subcategories: {
      'Hair Services': [
        'Haircuts',
        'Braiding',
        'Hair Relaxer',
        'Hair Extensions',
        'Coloring',
      ],
      'Beauty Treatments': [
        'Facials',
        'Massages',
        'Manicure & Pedicure',
        'Waxing',
        'Threading',
      ],
      'Laundry & Cleaning': [
        'Washing',
        'Dry Cleaning',
        'Ironing',
        'Pressing',
        'Stain Removal',
      ],
      'Products & Supplies': [
        'Shampoos & Conditioners',
        'Cosmetics',
        'Skincare Products',
        'Cleaning Supplies',
      ],
    },
  ),

  // 7. CONSTRUCTION
  'construction': BusinessCategoryHierarchy(
    verticalId: 'construction',
    verticalName: 'Construction',
    mainCategories: [
      'Materials',
      'Labor & Services',
      'Tools & Equipment',
      'Safety Equipment',
    ],
    subcategories: {
      'Materials': [
        'Cement & Concrete',
        'Bricks & Blocks',
        'Sand & Aggregates',
        'Timber & Plywood',
        'Roofing Materials',
      ],
      'Labor & Services': [
        'Masonry',
        'Plumbing',
        'Electrical',
        'Carpentry',
        'Painting',
      ],
      'Tools & Equipment': [
        'Hand Tools',
        'Power Tools',
        'Scaffolding',
        'Heavy Equipment Rental',
      ],
      'Safety Equipment': [
        'Helmets',
        'Gloves',
        'Safety Boots',
        'Reflective Wear',
        'Fall Protection',
      ],
    },
  ),

  // 8. TRANSPORT & LOGISTICS
  'transport_logistics': BusinessCategoryHierarchy(
    verticalId: 'transport_logistics',
    verticalName: 'Transport & Logistics',
    mainCategories: [
      'Transportation Services',
      'Logistics Services',
      'Vehicle Maintenance',
      'Fuel & Supplies',
    ],
    subcategories: {
      'Transportation Services': [
        'Passenger Transport',
        'Cargo Transport',
        'Express Delivery',
        'Courier Services',
        'Boda Services',
      ],
      'Logistics Services': [
        'Warehousing',
        'Distribution',
        'Cross-Border Transport',
        'Customs Clearance',
      ],
      'Vehicle Maintenance': [
        'Repairs',
        'Servicing',
        'Inspections',
        'Spare Parts',
      ],
      'Fuel & Supplies': [
        'Fuel',
        'Lubricants',
        'Spare Parts',
        'Accessories',
      ],
    },
  ),

  // 9. ICT & DIGITAL
  'ict_digital': BusinessCategoryHierarchy(
    verticalId: 'ict_digital',
    verticalName: 'ICT & Digital',
    mainCategories: [
      'Hardware',
      'Software & Services',
      'Internet Services',
      'Repairs & Support',
      'Digital Products',
    ],
    subcategories: {
      'Hardware': [
        'Computers',
        'Laptops',
        'Phones',
        'Tablets',
        'Accessories',
      ],
      'Software & Services': [
        'Software Licenses',
        'Web Development',
        'App Development',
        'IT Consulting',
        'System Integration',
      ],
      'Internet Services': [
        'Internet Packages',
        'Airtime',
        'Data Bundles',
        'WiFi Services',
      ],
      'Repairs & Support': [
        'Phone Repair',
        'Computer Repair',
        'Software Support',
        'Hardware Support',
      ],
      'Digital Products': [
        'eBooks',
        'Online Courses',
        'Digital Templates',
        'Software',
      ],
    },
  ),

  // 10. REAL ESTATE
  'real_estate': BusinessCategoryHierarchy(
    verticalId: 'real_estate',
    verticalName: 'Real Estate',
    mainCategories: [
      'Properties',
      'Services',
      'Lease Management',
    ],
    subcategories: {
      'Properties': [
        'Residential Units',
        'Commercial Spaces',
        'Industrial Properties',
        'Land',
        'Mixed Use',
      ],
      'Services': [
        'Sales Commission',
        'Rental Management',
        'Property Maintenance',
        'Valuation',
        'Legal Services',
      ],
      'Lease Management': [
        'Monthly Rent',
        'Deposit Collections',
        'Maintenance Fees',
        'Utilities Management',
      ],
    },
  ),

  // 11. FINANCIAL SERVICES
  'financial_services': BusinessCategoryHierarchy(
    verticalId: 'financial_services',
    verticalName: 'Financial Services',
    mainCategories: [
      'Savings Groups',
      'Loans & Credit',
      'Insurance',
      'Investment Products',
      'Payments & Transfers',
    ],
    subcategories: {
      'Savings Groups': [
        'Member Contributions',
        'Dividends',
        'Loan Repayments',
      ],
      'Loans & Credit': [
        'Personal Loans',
        'Business Loans',
        'Emergency Loans',
        'Loan Interest',
      ],
      'Insurance': [
        'Health Insurance',
        'Life Insurance',
        'Vehicle Insurance',
        'Property Insurance',
      ],
      'Investment Products': [
        'Mutual Funds',
        'Bonds',
        'Savings Certificates',
      ],
      'Payments & Transfers': [
        'Money Transfers',
        'Bill Payments',
        'Commissions',
      ],
    },
  ),

  // 12. HEALTH
  'health': BusinessCategoryHierarchy(
    verticalId: 'health',
    verticalName: 'Health',
    mainCategories: [
      'Consultation Services',
      'Medical Supplies',
      'Procedures & Tests',
      'Medications',
    ],
    subcategories: {
      'Consultation Services': [
        'Doctor Visits',
        'Specialist Consultations',
        'Follow-up Visits',
        'Home Visits',
      ],
      'Medical Supplies': [
        'Syringes & Needles',
        'Bandages & Dressings',
        'Gloves & PPE',
        'Medical Equipment',
      ],
      'Procedures & Tests': [
        'Blood Tests',
        'X-Rays',
        'Ultrasounds',
        'Injections',
        'Minor Procedures',
      ],
      'Medications': [
        'Tablets & Capsules',
        'Syrups',
        'Injectables',
        'Topical Treatments',
      ],
    },
  ),

  // 13. EDUCATION
  'education': BusinessCategoryHierarchy(
    verticalId: 'education',
    verticalName: 'Education',
    mainCategories: [
      'Tuition & Fees',
      'Learning Materials',
      'Facilities & Services',
      'Examinations',
    ],
    subcategories: {
      'Tuition & Fees': [
        'Tuition Fees',
        'Registration',
        'Uniforms & ID',
        'Lunch Fees',
      ],
      'Learning Materials': [
        'Textbooks',
        'Notebooks & Stationery',
        'Practical Materials',
        'Digital Resources',
      ],
      'Facilities & Services': [
        'Accommodation',
        'Transportation',
        'Computer Lab Access',
        'Library Access',
      ],
      'Examinations': [
        'Exam Fees',
        'Certification Fees',
        'Diplomas & Certificates',
      ],
    },
  ),

  // 14. ARTS & ENTERTAINMENT
  'arts_entertainment': BusinessCategoryHierarchy(
    verticalId: 'arts_entertainment',
    verticalName: 'Arts & Entertainment',
    mainCategories: [
      'Services',
      'Production',
      'Entertainment Venues',
      'Products & Merchandise',
    ],
    subcategories: {
      'Services': [
        'Photography',
        'Videography',
        'Graphic Design',
        'Event Planning',
        'DJ & Sound',
      ],
      'Production': [
        'Video Production',
        'Audio Recording',
        'Editing Services',
        'Printing & Publishing',
      ],
      'Entertainment Venues': [
        'Event Venue Rental',
        'Concert Tickets',
        'Theater Tickets',
        'Club Admission',
      ],
      'Products & Merchandise': [
        'Artwork',
        'Crafts',
        'Prints & Posters',
        'Handmade Items',
        'Souvenirs',
      ],
    },
  ),
};

BusinessCategoryHierarchy? getCategoryHierarchyFor(String verticalId) =>
    businessCategoryHierarchies[verticalId];

List<String>? getSubcategoriesFor(String verticalId, String category) =>
    businessCategoryHierarchies[verticalId]?.subcategories[category];
