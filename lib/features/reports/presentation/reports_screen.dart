import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
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

  DateTime _getFromDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'This Week':
        return now.subtract(const Duration(days: 7));
      case 'This Month':
        return DateTime(now.year, now.month, 1);
      case 'This Quarter':
        final qMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTime(now.year, qMonth, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  void _exportCSV(double grossRevenue, double cogs, double expenses, double netProfit, double vat) {
    final session = ref.read(authProvider);
    final businessName = session?.businessName ?? 'DUKA';
    final csv = '''
DUKA BUSINESS FINANCIAL REPORT
Business: $businessName
Period: $_selectedPeriod (${_getFromDate().toString().substring(0, 10)} to ${DateTime.now().toString().substring(0, 10)})
Generated: ${DateTime.now().toIso8601String()}

FINANCIAL SUMMARY (UGX)
Gross Revenue,${grossRevenue.toInt()}
Cost of Goods Sold (COGS),${cogs.toInt()}
Gross Profit,${(grossRevenue - cogs).toInt()}
Operating Expenses,${expenses.toInt()}
Net Profit,${netProfit.toInt()}
URA VAT (18%),${vat.toInt()}
''';
    Share.share(csv, subject: '$businessName - P&L Statement ($_selectedPeriod)');
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers to trigger rebuilds on new sales or expenses
    ref.watch(salesProvider);
    ref.watch(expensesProvider);

    final db = ref.watch(databaseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fromDate = _getFromDate();
    final toDate = DateTime.now().add(const Duration(days: 1));

    final grossRevenue = db.revenueInRange(fromDate, toDate);
    final costOfGoodsSold = db.costOfGoodsInRange(fromDate, toDate);
    final grossProfit = grossRevenue - costOfGoodsSold;
    final operatingExpenses = db.expensesInRange(fromDate, toDate);
    final netProfit = grossProfit - operatingExpenses;
    final profitMargin = grossRevenue > 0 ? (netProfit / grossRevenue) * 100 : 0.0;
    final vatCollected = db.taxInRange(fromDate, toDate);

    // 7-day trend data
    final dailyRevenues = db.dailyRevenueLastDays(7);
    final maxRevenue = dailyRevenues.fold<double>(100000, (m, r) => r > m ? r : m);

    // Expense breakdown by category
    final expenseMap = db.expensesByCategory(fromDate, toDate);

    final categories = ['Today', 'This Week', 'This Month', 'This Quarter'];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(ref.tr('reports_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Export CSV / Share',
            onPressed: () => _exportCSV(grossRevenue, costOfGoodsSold, operatingExpenses, netProfit, vatCollected),
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
              children: categories.map((p) {
                final isSelected = _selectedPeriod == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      p,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : (isDark ? AppColors.darkTextMain : AppColors.textMain),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primaryForest,
                    backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                    side: BorderSide(color: isSelected ? AppColors.primaryForest : (isDark ? AppColors.darkBorder : AppColors.borderLight)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onSelected: (_) => setState(() => _selectedPeriod = p),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Overview Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/reports_illustration.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Net Profitability',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(netProfit),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: netProfit >= 0 ? AppColors.primaryForest : AppColors.danger,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            profitMargin >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                            size: 16,
                            color: profitMargin >= 0 ? AppColors.success : AppColors.danger,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${profitMargin.toStringAsFixed(1)}% margin ($_selectedPeriod)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: profitMargin >= 0 ? AppColors.success : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 7-DAY REVENUE BAR CHART
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '7-Day Revenue Trend',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                    Icon(Icons.bar_chart_rounded, size: 20, color: AppColors.primaryForest),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: BarChart(
                    BarChartData(
                      maxY: maxRevenue * 1.2,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              CurrencyFormatter.format(rod.toY),
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final now = DateTime.now();
                              final target = now.subtract(Duration(days: 6 - val.toInt()));
                              const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              final dayName = weekdays[target.weekday - 1];
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(dayName, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      barGroups: List.generate(7, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: dailyRevenues[i],
                              color: i == 6 ? AppColors.emeraldNeon : AppColors.primaryForest,
                              width: 18,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Metrics Grid (2x2)
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              _buildMetricTile(
                title: ref.tr('gross_revenue'),
                value: CurrencyFormatter.format(grossRevenue),
                icon: Icons.payments_rounded,
                color: AppColors.primaryForest,
                isDark: isDark,
              ),
              _buildMetricTile(
                title: ref.tr('cost_of_goods'),
                value: CurrencyFormatter.format(costOfGoodsSold),
                icon: Icons.inventory_2_rounded,
                color: Colors.blueGrey,
                isDark: isDark,
              ),
              _buildMetricTile(
                title: ref.tr('operating_expenses'),
                value: CurrencyFormatter.format(operatingExpenses),
                icon: Icons.receipt_long_rounded,
                color: AppColors.danger,
                isDark: isDark,
              ),
              _buildMetricTile(
                title: ref.tr('gross_profit'),
                value: CurrencyFormatter.format(grossProfit),
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.success,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // EXPENSE BREAKDOWN (Pie Chart or Breakdown List)
          if (expenseMap.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expense Breakdown by Category',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  ...expenseMap.entries.map((entry) {
                    final percentage = operatingExpenses > 0 ? (entry.value / operatingExpenses) * 100 : 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text(CurrencyFormatter.format(entry.value), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: AppColors.surfaceMuted,
                                  color: AppColors.danger,
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // URA EFRIS & VAT Statement Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryForest.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.account_balance_rounded, color: AppColors.primaryForest, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'URA Tax Summary (18% VAT)',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Text(
                        'EFRIS Ready',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('VAT Collected on Sales (18%):', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    Text(
                      CurrencyFormatter.format(vatCollected),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primaryForest),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
