import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/export_service.dart';
import 'eod_summary_screen.dart';

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

  void _exportCSV(double grossRevenue, double cogs, double expenses, double netProfit, double vat, Map<String, double> expenseMap) async {
    final session = ref.read(authProvider);
    final businessName = session?.businessName ?? 'DUKA';
    final fromStr = _getFromDate().toString().substring(0, 10);
    final toStr = DateTime.now().toString().substring(0, 10);

    final buffer = StringBuffer();
    buffer.writeln('DUKA BUSINESS FINANCIAL REPORT');
    buffer.writeln('Business,$businessName');
    buffer.writeln('Period,$_selectedPeriod ($fromStr to $toStr)');
    buffer.writeln('Generated,${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    buffer.writeln('FINANCIAL SUMMARY (UGX)');
    buffer.writeln('Gross Revenue,${grossRevenue.toInt()}');
    buffer.writeln('Cost of Goods Sold (COGS),${cogs.toInt()}');
    buffer.writeln('Gross Profit,${(grossRevenue - cogs).toInt()}');
    buffer.writeln('Operating Expenses,${expenses.toInt()}');
    buffer.writeln('Net Profit,${netProfit.toInt()}');
    buffer.writeln('URA VAT (18%),${vat.toInt()}');
    buffer.writeln('');
    if (expenseMap.isNotEmpty) {
      buffer.writeln('OPERATING EXPENSES BREAKDOWN');
      buffer.writeln('Category,Amount (UGX)');
      expenseMap.forEach((category, amount) {
        buffer.writeln('$category,${amount.toInt()}');
      });
    }

    await ExportService.exportCsv(
      fileName: 'DUKA_Report_${_selectedPeriod.replaceAll(' ', '_')}_$toStr',
      csvContent: buffer.toString(),
      subject: '$businessName - P&L Statement ($_selectedPeriod)',
    );
  }

  void _exportPdf(double grossRevenue, double cogs, double expenses, double netProfit, double vat, Map<String, double> expenseMap) async {
    final session = ref.read(authProvider);
    final businessName = session?.businessName ?? 'DUKA';
    final fromDate = _getFromDate();
    final toDate = DateTime.now();

    final bytes = await ExportService.generateFinancialReportPdf(
      businessName: businessName,
      period: _selectedPeriod,
      fromDate: fromDate,
      toDate: toDate,
      grossRevenue: grossRevenue,
      costOfGoodsSold: cogs,
      grossProfit: grossRevenue - cogs,
      operatingExpenses: expenses,
      netProfit: netProfit,
      vatCollected: vat,
      expenseBreakdown: expenseMap,
    );

    final toStr = toDate.toString().substring(0, 10);
    await ExportService.shareOrPrintPdf(
      pdfBytes: bytes,
      fileName: 'DUKA_Statement_${_selectedPeriod.replaceAll(' ', '_')}_$toStr',
    );
  }

  void _showExportOptions(double grossRevenue, double cogs, double expenses, double netProfit, double vat, Map<String, double> expenseMap) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Export Financial Statement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF0284C7)),
                ),
                title: const Text('Export as PDF Document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Official A4 printable statement with tables & header', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportPdf(grossRevenue, cogs, expenses, netProfit, vat, expenseMap);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFDCFCE7),
                  child: Icon(Icons.table_chart_rounded, color: Color(0xFF16A34A)),
                ),
                title: const Text('Export as CSV Spreadsheet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Excel / Google Sheets compatible data file', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportCSV(grossRevenue, cogs, expenses, netProfit, vat, expenseMap);
                },
              ),
            ],
          ),
        ),
      ),
    );
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
            icon: const Icon(Icons.file_download_rounded),
            tooltip: 'Export Statement (PDF / CSV)',
            onPressed: () => _showExportOptions(grossRevenue, costOfGoodsSold, operatingExpenses, netProfit, vatCollected, expenseMap),
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
          const SizedBox(height: 14),

          // --- STAFF PERFORMANCE TRACKING (UgaPOS feature) ---
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
                            color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.badge_rounded, color: Color(0xFF0284C7), size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Staff Performance Tracking',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ],
                    ),
                    Text(
                      _selectedPeriod,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 20),
                ...() {
                  final staffMap = db.salesByCashierInRange(fromDate, toDate);
                  if (staffMap.isEmpty) {
                    return [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No cashier transactions recorded in this period.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      )
                    ];
                  }
                  return staffMap.values.map((staff) {
                    final name = staff['name'] as String;
                    final total = staff['totalSales'] as double;
                    final count = staff['count'] as int;
                    final avgTicket = count > 0 ? (total / count) : 0.0;
                    final share = grossRevenue > 0 ? (total / grossRevenue) * 100 : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(
                                CurrencyFormatter.format(total),
                                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryForest, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$count transactions · Avg ticket: ${CurrencyFormatter.format(avgTicket)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              Text('${share.toStringAsFixed(1)}% of revenue', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (share / 100).clamp(0.0, 1.0),
                              backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                }(),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // EOD Button Card
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryForest,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.assessment_rounded, color: Colors.white),
              label: const Text('Open Daily EOD Close-Day Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const EodSummaryScreen()),
                );
              },
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
