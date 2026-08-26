import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../expenses/presentation/expenses_screen.dart';
import '../../credit/presentation/debtor_book_screen.dart';
import '../../sales/presentation/sales_history_screen.dart';

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
    final lang = ref.watch(languageProvider);
    final syncEngine = ref.watch(syncEngineProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sales = ref.watch(salesProvider);
    final expenses = ref.watch(expensesProvider);
    final products = ref.watch(productsProvider);
    final debtors = ref.watch(debtorsProvider);

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

    final totalRevenue = sales.where((s) => !s.isVoided).fold<double>(0, (sum, s) => sum + s.totalAmount);
    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final netBalance = totalRevenue - totalExpenses;

    final todaySales = sales.where((s) => !s.isVoided && s.localTimestamp >= todayStart).fold<double>(0, (sum, s) => sum + s.totalAmount);
    final todayExpenses = expenses.where((e) => e.date >= todayStart).fold<double>(0, (sum, e) => sum + e.amount);
    final todayProfit = todaySales - todayExpenses;

    final lowStockCount = products.where((p) => p.currentStock <= p.minStockLevel).length;
    final overdueCount = debtors.where((d) => d.balanceOwed > 0).length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9), // surface-1
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
                color: isDark ? AppColors.darkSurface : Colors.white, // surface-2
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
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
                                color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
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
                              Text(
                                session?.businessName ?? 'Kampala Ventures',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Row(
                                children: [
                                  Text(
                                    session?.fullName ?? 'Business Owner',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextMain : const Color(0xFF0F172A),
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
                              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              size: 20,
                              color: isDark ? AppColors.accentGold : const Color(0xFF334155),
                            ),
                            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                            tooltip: 'Toggle Color Mode',
                          ),

                          // Language Switcher
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                lang == 'lg' ? '🇺🇬 LG' : lang == 'rn' ? '🇺🇬 RN' : '🇬🇧 EN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextMain : const Color(0xFF334155),
                                ),
                              ),
                            ),
                            onSelected: (val) => ref.read(languageProvider.notifier).setLanguage(val),
                            itemBuilder: (ctx) => const [
                              PopupMenuItem(value: 'en', child: Text('🇬🇧 English')),
                              PopupMenuItem(value: 'lg', child: Text('🇺🇬 Oluganda')),
                              PopupMenuItem(value: 'rn', child: Text('🇺🇬 Orunyankore')),
                            ],
                          ),
                          const SizedBox(width: 8),

                          // Notification Bell
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                                width: 0.5,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_none_rounded,
                                  size: 19,
                                  color: isDark ? AppColors.darkTextMain : const Color(0xFF334155),
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

                  const SizedBox(height: 18),

                  // --- 2. TOTAL BALANCE HERO CARD ---
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF072B1E) : AppColors.primaryForest,
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    lang == 'lg' ? 'Ssente Zonna Eziriwo' : 'Total balance',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _hideFigures ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      color: Colors.white.withValues(alpha: 0.7),
                                      size: 17,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => setState(() => _hideFigures = !_hideFigures),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _hideFigures ? 'UGX ••••••••' : CurrencyFormatter.format(netBalance),
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
                                    label: lang == 'lg' ? 'Eziyingidde (Leero)' : 'Today Income',
                                    value: _hideFigures ? '••••' : '↑ ${CurrencyFormatter.format(todaySales)}',
                                  ),
                                  const SizedBox(width: 16),
                                  _buildStatColumn(
                                    label: lang == 'lg' ? 'Ezafulumye' : 'Today Expenses',
                                    value: _hideFigures ? '••••' : '↓ ${CurrencyFormatter.format(todayExpenses)}',
                                  ),
                                  const SizedBox(width: 16),
                                  _buildStatColumn(
                                    label: lang == 'lg' ? 'Amagoba' : 'Today Profit',
                                    value: _hideFigures ? '••••' : CurrencyFormatter.format(todayProfit),
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

                  // --- 3. 4-COLUMN QUICK ACTIONS ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickAction(
                        icon: Icons.add_rounded,
                        label: lang == 'lg' ? 'Tunda' : 'New sale',
                        iconColor: isDark ? AppColors.emeraldNeon : const Color(0xFF0F766E),
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
                            MaterialPageRoute(builder: (ctx) => const ExpensesScreen()),
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
                        icon: Icons.description_outlined,
                        label: lang == 'lg' ? 'Ebbanja' : 'Debtors',
                        iconColor: const Color(0xFF34D399),
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (ctx) => const DebtorBookScreen()),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // --- 4. TWO ALERT PILLS ---
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => widget.onNavigateTab(2),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2005) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(16),
                              border: isDark ? Border.all(color: const Color(0xFF59400B)) : null,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    lang == 'lg' ? '$lowStockCount ebiba bikendedde' : '$lowStockCount low stock items',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                              MaterialPageRoute(builder: (ctx) => const DebtorBookScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF042621) : const Color(0xFFCCFBF1),
                              borderRadius: BorderRadius.circular(16),
                              border: isDark ? Border.all(color: const Color(0xFF0C4D44)) : null,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF14B8A6)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    lang == 'lg' ? '$overdueCount amabanja' : '$overdueCount overdue debts',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF99F6E4) : const Color(0xFF0F766E),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // --- 5. RECENT TRANSACTIONS ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang == 'lg' ? 'Ebikolwa ebyakakolebwa' : 'Recent transactions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextMain : const Color(0xFF0F172A),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (ctx) => const SalesHistoryScreen()),
                          );
                        },
                        child: Text(
                          lang == 'lg' ? 'Laba byonna' : 'See all',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.emeraldNeon : const Color(0xFF0F766E),
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
                          const Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.textMuted),
                          const SizedBox(height: 6),
                          const Text('No sales recorded yet', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () => widget.onNavigateTab(2),
                            icon: const Icon(Icons.point_of_sale_rounded, size: 16),
                            label: const Text('Make First Sale', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: sales.take(5).map((s) {
                        final isLast = s == sales.take(5).last;
                        final date = DateTime.fromMillisecondsSinceEpoch(s.localTimestamp);
                        final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} · ${s.paymentMethod.toUpperCase()}';

                        return _buildTransactionItem(
                          icon: s.isCredit ? Icons.schedule_rounded : Icons.north_east_rounded,
                          iconBg: s.isCredit
                              ? (isDark ? const Color(0xFF332005) : const Color(0xFFFEF3C7))
                              : (isDark ? const Color(0xFF052B1E) : const Color(0xFFDCFCE7)),
                          iconColor: s.isCredit ? const Color(0xFFD97706) : const Color(0xFF22C55E),
                          title: '${s.saleNumber} — ${s.customerName ?? 'Walk-in'}',
                          subtitle: timeStr,
                          amount: '+${CurrencyFormatter.format(s.totalAmount)}',
                          amountColor: s.isCredit ? const Color(0xFFD97706) : const Color(0xFF22C55E),
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
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
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
                    color: isDark ? AppColors.darkTextMain : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
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
