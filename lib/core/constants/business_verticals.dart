import 'package:flutter/material.dart';

class BusinessVertical {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String salesLabel;
  final String stockLabel;
  final String customerLabel;

  const BusinessVertical({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.salesLabel,
    required this.stockLabel,
    required this.customerLabel,
  });
}

const businessVerticals = [
  BusinessVertical(
    id: 'retail',
    name: 'Retail / Shop',
    description: 'Sell products and manage stock',
    icon: Icons.storefront_rounded,
    salesLabel: 'Sales',
    stockLabel: 'Inventory',
    customerLabel: 'Customers',
  ),
  BusinessVertical(
    id: 'clinic',
    name: 'Clinic / Pharmacy',
    description: 'Serve patients and manage medical supplies',
    icon: Icons.medical_services_rounded,
    salesLabel: 'Visits & Sales',
    stockLabel: 'Medical Stock',
    customerLabel: 'Patients',
  ),
  BusinessVertical(
    id: 'restaurant',
    name: 'Restaurant / Food',
    description: 'Manage orders, ingredients and tables',
    icon: Icons.restaurant_rounded,
    salesLabel: 'Orders',
    stockLabel: 'Ingredients',
    customerLabel: 'Guests',
  ),
  BusinessVertical(
    id: 'salon',
    name: 'Salon / Beauty',
    description: 'Manage appointments, services and products',
    icon: Icons.content_cut_rounded,
    salesLabel: 'Appointments',
    stockLabel: 'Products',
    customerLabel: 'Clients',
  ),
  BusinessVertical(
    id: 'services',
    name: 'Professional Services',
    description: 'Track jobs, invoices and client relationships',
    icon: Icons.work_outline_rounded,
    salesLabel: 'Jobs & Invoices',
    stockLabel: 'Resources',
    customerLabel: 'Clients',
  ),
  BusinessVertical(
    id: 'wholesale',
    name: 'Wholesale / Distribution',
    description: 'Move high-volume orders across your team',
    icon: Icons.local_shipping_rounded,
    salesLabel: 'Orders',
    stockLabel: 'Warehouse',
    customerLabel: 'Accounts',
  ),
  BusinessVertical(
    id: 'other',
    name: 'Other SME',
    description: 'Adapt DUKA to the way you work',
    icon: Icons.business_center_rounded,
    salesLabel: 'Transactions',
    stockLabel: 'Resources',
    customerLabel: 'Contacts',
  ),
];

BusinessVertical businessVerticalFor(String id) => businessVerticals.firstWhere(
      (vertical) => vertical.id == id,
      orElse: () => businessVerticals.first,
    );
