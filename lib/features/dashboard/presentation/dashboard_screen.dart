import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/constants/business_verticals.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/animated_counter.dart';
import '../../../core/widgets/offline_sync_indicator.dart';
import '../../expenses/presentation/expenses_screen.dart';
import '../../credit/presentation/debtor_book_screen.dart';
import '../../sales/presentation/sales_history_screen.dart';
import '../../production/presentation/production_screen.dart';
import '../../branches/presentation/branches_screen.dart';
import '../../reports/presentation/eod_summary_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final Function(int) onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _hideFigures = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider);
    final vertical = businessVerticalFor(session?.businessVertical ?? 'retail');
    final lang = ref.watch(languageProvider);
    final syncEngine = ref.watch(syncEngineProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sales = ref.watch(salesProvider);
    final expenses = ref.watch(expensesProvider);
    final products = ref.watch(productsProvider);
    final debtors = ref.watch(debtorsProvider);

    final now = DateTime.now();
    final todayStart =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

    final totalRevenue = sales
        .where((s) => !s.isVoided)
        .fold<double>(0, (sum, s) => sum + s.totalAmount);
    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final netBalance = totalRevenue - totalExpenses;

    final todaySales = sales
        .where((s) => !s.isVoided && s.localTimestamp >= todayStart)
        .fold<double>(0, (sum, s) => sum + s.totalAmount);
    final todayExpenses = expenses
        .where((e) => e.date >= todayStart)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final todayProfit = todaySales - todayExpenses;

    final performanceRevenue = List<double>.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day - (6 - index));
      final nextDay = day.add(const Duration(days: 1));
      return sales
          .where((sale) =>
              !sale.isVoided &&
              sale.localTimestamp >= day.millisecondsSinceEpoch &&
              sale.localTimestamp < nextDay.millisecondsSinceEpoch)
          .fold<double>(0, (sum, sale) => sum + sale.totalAmount);
    });
    final performanceExpenses = List<double>.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day - (6 - index));
      final nextDay = day.add(const Duration(days: 1));
      return expenses
          .where((expense) =>
              expense.date >= day.millisecondsSinceEpoch &&
              expense.date < nextDay.millisecondsSinceEpoch)
          .fold<double>(0, (sum, expense) => sum + expense.amount);
    });
    final performanceRevenueTotal =
        performanceRevenue.fold<double>(0, (sum, value) => sum + value);
    final performanceExpenseTotal =
        performanceExpenses.fold<double>(0, (sum, value) => sum + value);
    final performanceNet = performanceRevenueTotal - performanceExpenseTotal;

    final lowStockCount =
        products.where((p) => p.currentStock <= p.minStockLevel).length;
    final totalOverdueAmount = debtors
        .where((d) => d.balanceOwed > 0)
        .fold<double>(0, (sum, d) => sum + d.balanceOwed);
    final overdueCount = debtors.where((d) => d.balanceOwed > 0).length;

    // --- BUSINESS HEALTH SCORE CALCULATION (0 - 100) ---
    // 1. Profit Margin (30 pts max)
    final profitMargin = totalRevenue > 0 ? (netBalance / totalRevenue) : 0.0;
    final marginScore = profitMargin >= 0.25
        ? 30
        : profitMargin >= 0.15
            ? 22
            : profitMargin > 0
                ? 12
                : 0;

    // 2. Stock Health (25 pts max)
    final stockOkRatio = products.isNotEmpty
        ? ((products.length - lowStockCount) / products.length)
        : 1.0;
    final stockScore = (stockOkRatio * 25).round();

    // 3. Debt Risk Ratio (25 pts max)
    final debtRatio = totalRevenue > 0
        ? (totalOverdueAmount / totalRevenue)
        : (totalOverdueAmount > 0 ? 1.0 : 0.0);
    final debtScore = debtRatio == 0
        ? 25
        : debtRatio <= 0.1
            ? 20
            : debtRatio <= 0.25
                ? 12
                : 5;

    // 4. Sales Activity (20 pts max)
    final activityScore = todaySales > 0
        ? 20
        : sales.isNotEmpty
            ? 10
            : 0;

    final healthScore =
        (marginScore + stockScore + debtScore + activityScore).clamp(0, 100);
    final (healthLabel, healthColor, healthDesc) = healthScore >= 80
        ? (
            'Excellent',
            const Color(0xFF10B981),
            'High profitability & healthy stock levels'
          )
        : healthScore >= 60
            ? (
                'Good',
                const Color(0xFF0F766E),
                'Stable cash flow, monitor low stock'
              )
            : healthScore >= 40
                ? (
                    'Fair',
                    const Color(0xFFF59E0B),
                    'Collect overdue credit to improve cash'
                  )
                : (
                    'Needs Attention',
                    const Color(0xFFEF4444),
                    'High credit risk or low stock balance'
                  );

    final attentionActions = <Map<String, dynamic>>[];
    if (lowStockCount > 0) {
      attentionActions.add({
        'title':
            '$lowStockCount ${vertical.stockLabel.toLowerCase()} alert${lowStockCount == 1 ? '' : 's'}',
        'subtitle': 'Review and reorder',
        'icon': Icons.inventory_2_rounded,
        'color': const Color(0xFFF59E0B),
        'onTap': () => widget.onNavigateTab(2),
      });
    }
    if (totalOverdueAmount > 0) {
      attentionActions.add({
        'title': 'Collect overdue balance',
        'subtitle': CurrencyFormatter.format(totalOverdueAmount),
        'icon': Icons.payments_rounded,
        'color': const Color(0xFF0F766E),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => const DebtorBookScreen()),
            ),
      });
    }
    if ((syncEngine?.pendingCount ?? 0) > 0) {
      attentionActions.add({
        'title': 'Finish syncing records',
        'subtitle': '${syncEngine!.pendingCount} waiting to upload',
        'icon': Icons.cloud_upload_rounded,
        'color': const Color(0xFF2563EB),
        'onTap': () {
          syncEngine.syncNow();
        },
      });
    }
    if (attentionActions.isEmpty) {
      attentionActions.add({
        'title': 'You are ready for today',
        'subtitle': 'Open ${vertical.salesLabel.toLowerCase()} to get started',
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF059669),
        'onTap': () => widget.onNavigateTab(1),
      });
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF1F5F9), // surface-1
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await syncEngine?.syncNow();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.darkSurface : Colors.white, // surface-2
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color:
                      isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. TOP HEADER ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : const Color(0xFFE2E8F0),
                                width: 0.5,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/images/duka_logo.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    session?.businessName ?? 'Kampala Ventures',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Live Cloud Sync Status Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (syncEngine?.isSyncing == true)
                                          ? Colors.amber.withValues(alpha: 0.15)
                                          : (syncEngine?.pendingCount ?? 0) > 0
                                              ? Colors.orange
                                                  .withValues(alpha: 0.15)
                                              : Colors.green
                                                  .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: (syncEngine?.isSyncing ==
                                                    true)
                                                ? Colors.amber.shade700
                                                : (syncEngine?.pendingCount ??
                                                            0) >
                                                        0
                                                    ? Colors.orange.shade700
                                                    : const Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                            .animate(
                                                onPlay: (c) =>
                                                    c.repeat(reverse: true))
                                            .scale(duration: 800.ms),
                                        const SizedBox(width: 4),
                                        Text(
                                          (syncEngine?.isSyncing == true)
                                              ? 'Syncing'
                                              : (syncEngine?.pendingCount ??
                                                          0) >
                                                      0
                                                  ? '${syncEngine!.pendingCount} Pending'
                                                  : 'Cloud Synced',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: (syncEngine?.isSyncing ==
                                                    true)
                                                ? Colors.amber.shade800
                                                : (syncEngine?.pendingCount ??
                                                            0) >
                                                        0
                                                    ? Colors.orange.shade800
                                                    : const Color(0xFF10B981),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Row(
                                children: [
                                  Text(
                                    session?.fullName ?? 'Business Owner',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.darkTextMain
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 15,
                                    color: Color(0xFF0F766E),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Theme Mode Quick Toggle
                          IconButton(
                            icon: Icon(
                              isDark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              size: 20,
                              color: isDark
                                  ? AppColors.accentGold
                                  : const Color(0xFF334155),
                            ),
                            onPressed: () => ref
                                .read(themeModeProvider.notifier)
                                .toggleTheme(),
                            tooltip: 'Toggle Color Mode',
                          ),

                          // Language Switcher
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCard
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                lang == 'lg'
                                    ? '🇺🇬 LG'
                                    : lang == 'rn'
                                        ? '🇺🇬 RN'
                                        : '🇬🇧 EN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextMain
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ),
                            onSelected: (val) => ref
                                .read(languageProvider.notifier)
                                .setLanguage(val),
                            itemBuilder: (ctx) => const [
                              PopupMenuItem(
                                  value: 'en', child: Text('🇬🇧 English')),
                              PopupMenuItem(
                                  value: 'lg', child: Text('🇺🇬 Oluganda')),
                              PopupMenuItem(
                                  value: 'rn', child: Text('🇺🇬 Orunyankore')),
                            ],
                          ),
                          const SizedBox(width: 8),

                          // Notification Bell
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCard
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : const Color(0xFFE2E8F0),
                                width: 0.5,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_none_rounded,
                                  size: 19,
                                  color: isDark
                                      ? AppColors.darkTextMain
                                      : const Color(0xFF334155),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Offline Sync Indicator Banner (Design System Item #10)
                  OfflineSyncIndicator(
                    isOffline: syncEngine?.isOffline ?? false,
                    pendingCount: syncEngine?.pendingCount ?? 0,
                    onSyncPressed: () => syncEngine?.syncNow(),
                  ),

                  const SizedBox(height: 14),

                  // --- 2. TOTAL BALANCE HERO CARD ---
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF072B1E)
                          : AppColors.primaryForest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 44,
                          child: Opacity(
                            opacity: 0.35,
                            child: CustomPaint(
                              painter: _PolylineWavePainter(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    lang == 'lg'
                                        ? 'Ssente Zonna Eziriwo'
                                        : 'Total balance',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _hideFigures
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      size: 17,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => setState(
                                        () => _hideFigures = !_hideFigures),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _hideFigures
                                  ? const Text(
                                      'UGX ••••••••',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    )
                                  : AnimatedCounter(
                                      value: netBalance,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildStatColumn(
                                    label: lang == 'lg'
                                        ? 'Eziyingidde (Leero)'
                                        : 'Today Income',
                                    value: _hideFigures
                                        ? '••••'
                                        : '↑ ${CurrencyFormatter.format(todaySales)}',
                                  ),
                                  const SizedBox(width: 16),
                                  _buildStatColumn(
                                    label: lang == 'lg'
                                        ? 'Ezafulumye'
                                        : 'Today Expenses',
                                    value: _hideFigures
                                        ? '••••'
                                        : '↓ ${CurrencyFormatter.format(todayExpenses)}',
                                  ),
                                  const SizedBox(width: 16),
                                  _buildStatColumn(
                                    label: lang == 'lg'
                                        ? 'Amagoba'
                                        : 'Today Profit',
                                    value: _hideFigures
                                        ? '••••'
                                        : CurrencyFormatter.format(todayProfit),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Needs your attention',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Next best actions',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 86,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: attentionActions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final action = attentionActions[index];
                        return _buildAttentionAction(
                          title: action['title'] as String,
                          subtitle: action['subtitle'] as String,
                          icon: action['icon'] as IconData,
                          color: action['color'] as Color,
                          isDark: isDark,
                          onTap: action['onTap'] as VoidCallback,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  _buildPerformanceChart(
                    context: context,
                    revenue: performanceRevenue,
                    expenses: performanceExpenses,
                    revenueTotal: performanceRevenueTotal,
                    expenseTotal: performanceExpenseTotal,
                    net: performanceNet,
                    isDark: isDark,
                    vertical: vertical,
                  ),

                  const SizedBox(height: 18),

                  // --- 3. 6-ITEM UGA-POS QUICK ACTIONS ---
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      _buildQuickAction(
                        icon: Icons.add_shopping_cart_rounded,
                        label: lang == 'lg' ? 'Tunda' : 'New sale',
                        iconColor: isDark
                            ? AppColors.emeraldNeon
                            : const Color(0xFF0F766E),
                        isDark: isDark,
                        onTap: () => widget.onNavigateTab(1),
                      ),
                      _buildQuickAction(
                        icon: Icons.receipt_long_rounded,
                        label: lang == 'lg' ? 'Ezafulumye' : 'Expense',
                        iconColor: const Color(0xFFEF4444),
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) => const ExpensesScreen()),
                          );
                        },
                      ),
                      _buildQuickAction(
                        icon: Icons.inventory_2_outlined,
                        label: lang == 'lg' ? 'Sttoka' : 'Stock',
                        iconColor: const Color(0xFFA78BFA),
                        isDark: isDark,
                        onTap: () => widget.onNavigateTab(2),
                      ),
                      _buildQuickAction(
                        icon: Icons.precision_manufacturing_rounded,
                        label: 'Production',
                        iconColor: const Color(0xFFF59E0B),
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) => const ProductionScreen()),
                          );
                        },
                      ),
                      _buildQuickAction(
                        icon: Icons.domain_rounded,
                        label: 'Branches',
                        iconColor: const Color(0xFF0284C7),
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) => const BranchesScreen()),
                          );
                        },
                      ),
                      _buildQuickAction(
                        icon: Icons.assessment_rounded,
                        label: 'Close Day',
                        iconColor: const Color(0xFF10B981),
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) => const EodSummaryScreen()),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // --- 3.5. BUSINESS HEALTH SCORE CARD ---
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: healthColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
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
                                    color: healthColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.analytics_rounded,
                                      size: 16, color: healthColor),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  lang == 'lg'
                                      ? 'Endabika Y\'obusuubuzi'
                                      : 'Business Health Score',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.darkTextMain
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: healthColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: healthColor.withValues(alpha: 0.3),
                                    width: 0.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$healthScore/100',
                                    style: TextStyle(
                                      color: healthColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '· $healthLabel',
                                    style: TextStyle(
                                      color: healthColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                              begin: 0.0, end: healthScore / 100.0),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, val, _) => ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: val,
                              backgroundColor: isDark
                                  ? Colors.white10
                                  : const Color(0xFFE2E8F0),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(healthColor),
                              minHeight: 7,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          healthDesc,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- 4. TWO ALERT PILLS (VELOCITY STOCK & OVERDUE UGX) ---
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => widget.onNavigateTab(2),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C2005)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF59400B)
                                    : const Color(0xFFFDE68A),
                                width: 0.8,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 11),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    size: 16, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lang == 'lg'
                                            ? '$lowStockCount ebiba bikendedde'
                                            : '$lowStockCount Low Stock',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? const Color(0xFFFDE68A)
                                              : const Color(0xFFB45309),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'Re-order required',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          color: isDark
                                              ? const Color(0xFFFDE68A)
                                                  .withValues(alpha: 0.7)
                                              : const Color(0xFFB45309)
                                                  .withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (ctx) => const DebtorBookScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF042621)
                                  : const Color(0xFFCCFBF1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF0C4D44)
                                    : const Color(0xFF99F6E4),
                                width: 0.8,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 11),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 16, color: Color(0xFF14B8A6)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        totalOverdueAmount > 0
                                            ? CurrencyFormatter.format(
                                                totalOverdueAmount)
                                            : '$overdueCount Debts',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? const Color(0xFF99F6E4)
                                              : const Color(0xFF0F766E),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        '$overdueCount Overdue debtor${overdueCount == 1 ? '' : 's'}',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          color: isDark
                                              ? const Color(0xFF99F6E4)
                                                  .withValues(alpha: 0.7)
                                              : const Color(0xFF0F766E)
                                                  .withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // --- 4.5. TOP SELLING PRODUCTS MINI-SECTION (UgaPOS feature) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Top Selling Products',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      InkWell(
                        onTap: () => widget.onNavigateTab(2),
                        child: Text(
                          'View all',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.emeraldNeon
                                : const Color(0xFF0F766E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFE2E8F0),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildTopItemRow('1', 'NPK 17:17:17 Fertilizer 50kg',
                            '24 bags sold', 'UGX 4,440,000', isDark),
                        const Divider(height: 16),
                        _buildTopItemRow('2', 'Tororo Cement 32.5R 50kg',
                            '18 bags sold', 'UGX 648,000', isDark),
                        const Divider(height: 16),
                        _buildTopItemRow('3', 'Bazooka Maize Seeds 2kg',
                            '14 pkts sold', 'UGX 259,000', isDark),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- 5. RECENT TRANSACTIONS ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang == 'lg'
                            ? 'Ebikolwa ebyakakolebwa'
                            : 'Recent transactions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextMain
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) => const SalesHistoryScreen()),
                          );
                        },
                        child: Text(
                          lang == 'lg' ? 'Laba byonna' : 'See all',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.emeraldNeon
                                : const Color(0xFF0F766E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (sales.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long_outlined,
                              size: 36, color: AppColors.textMuted),
                          const SizedBox(height: 6),
                          const Text('No sales recorded yet',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () => widget.onNavigateTab(1),
                            icon: const Icon(Icons.point_of_sale_rounded,
                                size: 16),
                            label: const Text('Make First Sale',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: sales.take(5).map((s) {
                        final isLast = s == sales.take(5).last;
                        final date = DateTime.fromMillisecondsSinceEpoch(
                            s.localTimestamp);
                        final timeStr =
                            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} · ${s.paymentMethod.toUpperCase()}';

                        return _buildTransactionItem(
                          icon: s.isCredit
                              ? Icons.schedule_rounded
                              : Icons.north_east_rounded,
                          iconBg: s.isCredit
                              ? (isDark
                                  ? const Color(0xFF332005)
                                  : const Color(0xFFFEF3C7))
                              : (isDark
                                  ? const Color(0xFF052B1E)
                                  : const Color(0xFFDCFCE7)),
                          iconColor: s.isCredit
                              ? const Color(0xFFD97706)
                              : const Color(0xFF22C55E),
                          title:
                              '${s.saleNumber} — ${s.customerName ?? 'Walk-in'}',
                          subtitle: timeStr,
                          amount: '+${CurrencyFormatter.format(s.totalAmount)}',
                          amountColor: s.isCredit
                              ? const Color(0xFFD97706)
                              : const Color(0xFF22C55E),
                          hasBorder: !isLast,
                          isDark: isDark,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                width: 0.5,
              ),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart({
    required BuildContext context,
    required List<double> revenue,
    required List<double> expenses,
    required double revenueTotal,
    required double expenseTotal,
    required double net,
    required bool isDark,
    required BusinessVertical vertical,
  }) {
    final maxValue = [...revenue, ...expenses].fold<double>(
      0,
      (maximum, value) => value > maximum ? value : maximum,
    );
    final chartMax = maxValue == 0 ? 100.0 : maxValue * 1.25;
    final netColor = net >= 0 ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vertical.salesLabel} performance',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Last 7 days',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildChartLegend('Income', AppColors.primaryEmerald),
                  const SizedBox(width: 8),
                  _buildChartLegend('Costs', AppColors.accentGold),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 145,
            child: BarChart(
              BarChartData(
                maxY: chartMax,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                      CurrencyFormatter.format(rod.toY),
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final target = DateTime.now().subtract(
                          Duration(days: 6 - value.toInt()),
                        );
                        const labels = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            labels[target.weekday - 1],
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                alignment: BarChartAlignment.spaceAround,
                barGroups: List.generate(7, (index) {
                  return BarChartGroupData(
                    x: index,
                    barsSpace: 3,
                    barRods: [
                      BarChartRodData(
                        toY: revenue[index],
                        color: AppColors.primaryEmerald,
                        width: 7,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                      BarChartRodData(
                        toY: expenses[index],
                        color: AppColors.accentGold,
                        width: 7,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildChartSummary(
                  'Income',
                  CurrencyFormatter.format(revenueTotal),
                  AppColors.primaryEmerald,
                ),
              ),
              Expanded(
                child: _buildChartSummary(
                  'Costs',
                  CurrencyFormatter.format(expenseTotal),
                  AppColors.accentGold,
                ),
              ),
              Expanded(
                child: _buildChartSummary(
                  'Net',
                  CurrencyFormatter.format(net),
                  netColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }

  Widget _buildChartSummary(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
        const SizedBox(height: 2),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            )),
      ],
    );
  }

  Widget _buildAttentionAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 210,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String amount,
    required Color amountColor,
    required bool hasBorder,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: hasBorder
            ? Border(
                bottom: BorderSide(
                  color:
                      isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  width: 0.5,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextMain
                        : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItemRow(
      String rank, String name, String qtySold, String revenue, bool isDark) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: rank == '1'
                ? AppColors.accentGold
                : (isDark ? AppColors.darkSurface : const Color(0xFFE2E8F0)),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            rank,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: rank == '1'
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF334155)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                qtySold,
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        Text(
          revenue,
          style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.primaryForest,
              fontSize: 12),
        ),
      ],
    );
  }
}

// Polyline Wave Painter matching the HTML polyline
class _PolylineWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final points = [
      Offset(0 * (size.width / 300), 40 * (size.height / 50)),
      Offset(30 * (size.width / 300), 32 * (size.height / 50)),
      Offset(60 * (size.width / 300), 38 * (size.height / 50)),
      Offset(90 * (size.width / 300), 20 * (size.height / 50)),
      Offset(120 * (size.width / 300), 28 * (size.height / 50)),
      Offset(150 * (size.width / 300), 10 * (size.height / 50)),
      Offset(180 * (size.width / 300), 22 * (size.height / 50)),
      Offset(210 * (size.width / 300), 14 * (size.height / 50)),
      Offset(240 * (size.width / 300), 18 * (size.height / 50)),
      Offset(270 * (size.width / 300), 6 * (size.height / 50)),
      Offset(300 * (size.width / 300), 12 * (size.height / 50)),
    ];

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
