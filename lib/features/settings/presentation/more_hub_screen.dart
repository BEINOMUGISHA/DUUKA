import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/constants/business_verticals.dart';
import '../../credit/presentation/debtor_book_screen.dart';
import '../../payments/presentation/payments_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../reports/presentation/eod_summary_screen.dart';
import '../../expenses/presentation/expenses_screen.dart';
import '../../sms/presentation/sms_screen.dart';
import '../../sales/presentation/sales_history_screen.dart';
import '../../suppliers/presentation/suppliers_screen.dart';
import '../../production/presentation/production_screen.dart';
import '../../branches/presentation/branches_screen.dart';
import '../../accounting/presentation/accounting_hub_screen.dart';
import '../../customers/presentation/customers_screen.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../pos/presentation/pos_quick_sale_screen.dart';
import 'settings_screen.dart';

class MoreHubScreen extends ConsumerWidget {
  const MoreHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vertical = businessVerticalFor(session?.businessVertical ?? 'retail');

    final tools = [
      {
        'title': 'Production & Recipes',
        'subtitle': 'Raw materials, formulations & batch runs',
        'icon': Icons.precision_manufacturing_rounded,
        'color': const Color(0xFF0F766E),
        'badge': 'NEW',
        'feature': 'production',
        'screen': const ProductionScreen(),
      },
      {
        'title': 'Branches & Stock Transfers',
        'subtitle': 'Multi-store locations & stock dispatch',
        'icon': Icons.account_tree_rounded,
        'color': const Color(0xFF0284C7),
        'badge': 'NEW',
        'feature': 'branches',
        'screen': const BranchesScreen(),
      },
      {
        'title': 'End of Day (EOD) Summary',
        'subtitle': 'Daily till reconciliation, SMS & PDF export',
        'icon': Icons.assessment_rounded,
        'color': const Color(0xFF059669),
        'badge': 'NEW',
        'screen': const EodSummaryScreen(),
      },
      {
        'title': 'Debtor Book (Ababanja)',
        'subtitle': 'Credit sales, due dates & reminders',
        'icon': Icons.book_online_rounded,
        'color': const Color(0xFFD97706),
        'feature': 'credit',
        'screen': const DebtorBookScreen(),
      },
      {
        'title': 'Mobile Money & Collections',
        'subtitle': 'MTN MoMo & Airtel Money gateway',
        'icon': Icons.send_to_mobile_rounded,
        'color': const Color(0xFF0284C7),
        'screen': const PaymentsScreen(),
      },
      {
        'title': 'Accounting & Trial Balance',
        'subtitle': 'Chart of accounts, journals & ledger posting',
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFF7C3AED),
        'screen': const AccountingHubScreen(),
      },
      {
        'title': 'Reports & P&L Analytics',
        'subtitle': 'Gross profit, staff performance & exports',
        'icon': Icons.bar_chart_rounded,
        'color': const Color(0xFF059669),
        'screen': const ReportsScreen(),
      },
      {
        'title': 'SMS & Customer Reminders',
        'subtitle': 'SMS templates & credit balance reminders',
        'icon': Icons.sms_rounded,
        'color': const Color(0xFF4F46E5),
        'feature': 'sms',
        'screen': const SmsScreen(),
      },
      {
        'title': 'Daily Expenses (Cashbook)',
        'subtitle': 'Transport, rent, wages & utilities',
        'icon': Icons.receipt_long_rounded,
        'color': const Color(0xFFE11D48),
        'screen': const ExpensesScreen(),
      },
      {
        'title': 'Sales History & Void Receipts',
        'subtitle': 'Full receipt archive & audit trail',
        'icon': Icons.history_rounded,
        'color': const Color(0xFF0D9488),
        'screen': const SalesHistoryScreen(),
      },
      {
        'title': 'Suppliers & Purchases (GRN)',
        'subtitle': 'Supplier master, purchase orders & AP',
        'icon': Icons.local_shipping_rounded,
        'color': const Color(0xFF8B5CF6),
        'feature': 'suppliers',
        'screen': const SuppliersScreen(),
      },
      {
        'title': 'Business Profile & Settings',
        'subtitle': 'EFRIS TIN, staff PINs, printers & backups',
        'icon': Icons.settings_suggest_rounded,
        'color': const Color(0xFF64748B),
        'screen': const SettingsScreen(),
      },
    ];

    final visibleTools = tools.where((tool) {
      final feature = tool['feature'] as String?;
      return feature == null || vertical.enabledFeatures.contains(feature);
    }).toList();

    final quickActions = switch (vertical.id) {
      'clinic' => [
          _quickAction(
              'Record patient sale / visit',
              'Open checkout',
              Icons.medical_services_rounded,
              const Color(0xFF0284C7),
              const PosQuickSaleScreen()),
          _quickAction(
              'Manage medical stock',
              'Track medicines and supplies',
              Icons.inventory_2_rounded,
              const Color(0xFF059669),
              const InventoryScreen()),
          _quickAction(
              'Open patient records',
              'View balances and history',
              Icons.people_alt_rounded,
              const Color(0xFF7C3AED),
              const CustomersScreen()),
        ],
      'restaurant' => [
          _quickAction(
              'Start a new order',
              'Take payment at the counter',
              Icons.restaurant_rounded,
              AppColors.accentGold,
              const PosQuickSaleScreen()),
          _quickAction(
              'Check ingredients',
              'Protect today\'s service',
              Icons.inventory_2_rounded,
              const Color(0xFF059669),
              const InventoryScreen()),
          _quickAction(
              'Close today\'s shift',
              'Reconcile cash and payments',
              Icons.assessment_rounded,
              const Color(0xFF0284C7),
              const EodSummaryScreen()),
        ],
      'salon' => [
          _quickAction(
              'Start a service sale',
              'Capture services and products',
              Icons.content_cut_rounded,
              const Color(0xFF7C3AED),
              const PosQuickSaleScreen()),
          _quickAction(
              'Manage products',
              'Keep retail supplies ready',
              Icons.inventory_2_rounded,
              const Color(0xFF059669),
              const InventoryScreen()),
          _quickAction(
              'Open client book',
              'Follow up with returning clients',
              Icons.people_alt_rounded,
              const Color(0xFF0284C7),
              const CustomersScreen()),
        ],
      'services' => [
          _quickAction(
              'Start a new job',
              'Capture a charge or invoice',
              Icons.work_outline_rounded,
              const Color(0xFF0284C7),
              const PosQuickSaleScreen()),
          _quickAction(
              'Open client book',
              'Keep relationships organized',
              Icons.people_alt_rounded,
              const Color(0xFF7C3AED),
              const CustomersScreen()),
          _quickAction(
              'Review business health',
              'See profit and cash movement',
              Icons.bar_chart_rounded,
              const Color(0xFF059669),
              const ReportsScreen()),
        ],
      'wholesale' => [
          _quickAction(
              'Create a customer order',
              'Move high-volume stock',
              Icons.local_shipping_rounded,
              const Color(0xFF0284C7),
              const PosQuickSaleScreen()),
          _quickAction(
              'Review warehouse',
              'Check stock before dispatch',
              Icons.inventory_2_rounded,
              const Color(0xFF059669),
              const InventoryScreen()),
          _quickAction(
              'Review customer accounts',
              'Track balances and credit',
              Icons.people_alt_rounded,
              const Color(0xFF7C3AED),
              const CustomersScreen()),
        ],
      _ => [
          _quickAction(
              'Record a sale',
              'Serve your next customer',
              Icons.point_of_sale_rounded,
              AppColors.accentGold,
              const PosQuickSaleScreen()),
          _quickAction(
              'Check inventory',
              'Know what is available',
              Icons.inventory_2_rounded,
              const Color(0xFF059669),
              const InventoryScreen()),
          _quickAction(
              'Open customer book',
              'Build repeat business',
              Icons.people_alt_rounded,
              const Color(0xFF7C3AED),
              const CustomersScreen()),
        ],
    };

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('DUUKA Tools & Hub'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Business Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white24,
                  child: Text(
                    (session?.businessName ?? 'D')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session?.businessName ?? 'Kisekka Agro & Hardware',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${session?.fullName ?? 'Owner'} · ${(session?.role ?? 'owner').toUpperCase()}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('PRO UG',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text('Start with ${vertical.name}',
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 10),
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: quickActions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final action = quickActions[index];
                return _QuickActionCard(action: action);
              },
            ),
          ),
          const SizedBox(height: 22),

          const Text('All Management Modules',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 12),

          ...visibleTools.map((t) {
            final color = t['color'] as Color;
            final badge = t['badge'] as String?;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => t['screen'] as Widget),
                  );
                },
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(t['icon'] as IconData, color: color, size: 22),
                ),
                title: Row(
                  children: [
                    Text(
                      t['title'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  t['subtitle'] as String,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textMuted),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.textMuted),
              ),
            );
          }),
        ],
      ),
    );
  }

  Map<String, dynamic> _quickAction(String title, String subtitle,
          IconData icon, Color color, Widget screen) =>
      {
        'title': title,
        'subtitle': subtitle,
        'icon': icon,
        'color': color,
        'screen': screen,
      };
}

class _QuickActionCard extends StatelessWidget {
  final Map<String, dynamic> action;

  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    final color = action['color'] as Color;
    return SizedBox(
      width: 190,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => action['screen'] as Widget),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(action['icon'] as IconData, color: color, size: 24),
                const Spacer(),
                Text(action['title'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(height: 2),
                Text(action['subtitle'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
