import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
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
import 'settings_screen.dart';

class MoreHubScreen extends ConsumerWidget {
  const MoreHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tools = [
      {
        'title': 'Production & Recipes',
        'subtitle': 'Raw materials, formulations & batch runs',
        'icon': Icons.precision_manufacturing_rounded,
        'color': const Color(0xFF0F766E),
        'badge': 'NEW',
        'screen': const ProductionScreen(),
      },
      {
        'title': 'Branches & Stock Transfers',
        'subtitle': 'Multi-store locations & stock dispatch',
        'icon': Icons.account_tree_rounded,
        'color': const Color(0xFF0284C7),
        'badge': 'NEW',
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('DUKA Tools & Hub'),
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
                    (session?.businessName ?? 'D').substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session?.businessName ?? 'Kisekka Agro & Hardware',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${session?.fullName ?? 'Owner'} · ${(session?.role ?? 'owner').toUpperCase()}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('PRO UG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('All Management Modules', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 12),

          ...tools.map((t) {
            final color = t['color'] as Color;
            final badge = t['badge'] as String?;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  t['subtitle'] as String,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
              ),
            );
          }),
        ],
      ),
    );
  }
}
