import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/providers/app_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedPeriod = 'This Month';

  @override
  Widget build(BuildContext context) {
    const double grossRevenue = 12450000;
    const double costOfGoodsSold = 8900000;
    const double grossProfit = grossRevenue - costOfGoodsSold;
    const double operatingExpenses = 1200000;
    const double netProfit = grossProfit - operatingExpenses;
    const double profitMargin = (netProfit / grossRevenue) * 100;
    const double vatCollected = grossRevenue * (0.18 / 1.18);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(ref.tr('reports_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_rounded),
            tooltip: 'Export PDF / CSV',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting URA Tax & P&L Statement to CSV/PDF...')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Period Selector Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Today', 'This Week', 'This Month', 'This Quarter'].map((p) {
                final isSelected = _selectedPeriod == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      p,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textMain,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primaryForest,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSelected ? AppColors.primaryForest : AppColors.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onSelected: (_) => setState(() => _selectedPeriod = p),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Net Profit Luxury Hero Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryForest.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ref.tr('net_business_profit'),
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${profitMargin.toStringAsFixed(1)}% Margin',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  CurrencyFormatter.format(netProfit),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 30, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  '${ref.tr('gross_sales')}: ${CurrencyFormatter.format(grossRevenue)} • ${ref.tr('expenses_label')}: ${CurrencyFormatter.format(operatingExpenses)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.05, end: 0),

          const SizedBox(height: 16),

          // Accounting P&L Statement Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(ref.tr('pl_summary'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    const Icon(Icons.table_chart_rounded, size: 18, color: AppColors.textLight),
                  ],
                ),
                const Divider(height: 24),
                _buildStatementRow(ref.tr('gross_revenue'), grossRevenue, isBold: true, color: AppColors.primaryForest),
                _buildStatementRow(ref.tr('cogs'), -costOfGoodsSold, color: AppColors.textMuted),
                const Divider(height: 18),
                _buildStatementRow(ref.tr('gross_profit'), grossProfit, isBold: true),
                _buildStatementRow(ref.tr('operating_expenses'), -operatingExpenses, color: AppColors.danger),
                const Divider(height: 18),
                _buildStatementRow(ref.tr('net_operating_profit'), netProfit, isBold: true, color: AppColors.primaryForest, isHighlight: true),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // URA EFRIS & VAT Compliance Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ref.tr('efris_tax_summary'),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.indigo),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.efrisIndigo,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('18% VAT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${ref.tr('taxable_turnover')}:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(CurrencyFormatter.format(grossRevenue - vatCollected), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${ref.tr('output_vat')}:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.indigo)),
                    Text(CurrencyFormatter.format(vatCollected), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.indigo)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Top Selling Products Leaderboard
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ref.tr('top_products'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 14),
                _buildTopProductRow('🥇', 'NPK 17:17:17 Fertilizer', 45, 8325000),
                _buildTopProductRow('🥈', 'Tororo Cement 32.5R', 120, 4320000),
                _buildTopProductRow('🥉', 'DAP Fertilizer 50kg', 18, 3780000),
                _buildTopProductRow('4', 'Bazooka Maize Seeds', 85, 1572500),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementRow(String label, double amount, {bool isBold = false, Color? color, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              fontSize: isHighlight ? 14 : 13,
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              fontSize: isHighlight ? 15 : 13,
              color: color ?? AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductRow(String rank, String name, int unitsSold, double revenue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(rank, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                Text('$unitsSold ${ref.tr('units_sold')}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(revenue),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.primaryForest),
          ),
        ],
      ),
    );
  }
}
