import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/uganda_presets.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/providers/app_providers.dart';
import '../../pos/presentation/pos_quick_sale_screen.dart';
import '../../expenses/presentation/expenses_screen.dart';
import '../../credit/presentation/debtor_book_screen.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../reports/presentation/reports_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final Function(int) onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _hideFigures = false;
  String _timeFilter = 'Today';

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider);
    final lang = ref.watch(languageProvider);
    final syncEngine = ref.watch(syncEngineProvider);

    const double todaySales = 1850000;
    const double todayTarget = 2500000;
    final double targetPercent = (todaySales / todayTarget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGold.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session?.businessName ?? ref.tr('app_name'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.emeraldNeon,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Kampala • ${session?.currency ?? "UGX"}',
                        style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Language Switcher Pill
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lang == 'lg' ? '🇺🇬 LG' : lang == 'rn' ? '🇺🇬 RN' : '🇬🇧 EN',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                ],
              ),
            ),
            onSelected: (val) => ref.read(languageProvider.notifier).setLanguage(val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'en', child: Text('🇬🇧 English (Default)')),
              const PopupMenuItem(value: 'lg', child: Text('🇺🇬 Oluganda (Main)')),
              const PopupMenuItem(value: 'rn', child: Text('🇺🇬 Orunyankore')),
            ],
          ),

          // Cloud Sync Pill
          Padding(
            padding: const EdgeInsets.only(right: 14, left: 2),
            child: InkWell(
              onTap: () {
                syncEngine?.syncNow();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ref.tr('sync_now')),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (syncEngine?.state.pendingCount ?? 0) > 0
                      ? AppColors.creditAmber.withOpacity(0.9)
                      : AppColors.primaryEmerald.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (syncEngine?.state.pendingCount ?? 0) > 0
                        ? AppColors.creditAmber
                        : AppColors.emeraldNeon.withOpacity(0.6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      (syncEngine?.state.pendingCount ?? 0) > 0 ? Icons.sync_rounded : Icons.check_circle_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (syncEngine?.state.pendingCount ?? 0) > 0
                          ? '${syncEngine?.state.pendingCount} ${ref.tr('pending')}'
                          : ref.tr('online'),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await syncEngine?.syncNow();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // HERO FINANCIAL CARD (Glassmorphism & Gradients)
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Ambient decorative glow rings
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryEmerald.withOpacity(0.12),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    left: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentGold.withOpacity(0.08),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Header with Streak and Privacy Eye
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Streak Flame Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.streakFlame.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.streakFlame.withOpacity(0.4)),
                              ],
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('🔥', style: TextStyle(fontSize: 12)),
                                  SizedBox(width: 4),
                                  Text(
                                    '5-Day Sales Streak!',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),

                            // Privacy toggle icon
                            IconButton(
                              icon: Icon(
                                _hideFigures ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setState(() => _hideFigures = !_hideFigures),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Total Sales Label
                        Text(
                          ref.tr('todays_sales'),
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),

                        // Big Revenue Text
                        Text(
                          _hideFigures ? 'UGX ••••••••' : CurrencyFormatter.format(todaySales),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Daily Target Goal Progress Bar
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Daily Target: ${(targetPercent * 100).toInt()}% Achieved',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    _hideFigures ? '••••' : 'Goal: ${CurrencyFormatter.formatCompact(todayTarget)}',
                                    style: TextStyle(color: AppColors.goldLight, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: targetPercent,
                                  minHeight: 6,
                                  backgroundColor: Colors.white12,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emeraldNeon),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 14),

            // DUAL CARDS: Credit / Debtors + Net Cash Flow
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => const DebtorBookScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
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
                                ref.tr('credit_balance'),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.creditAmber.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.people_alt_rounded, size: 14, color: AppColors.creditAmber),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _hideFigures ? '••••••' : CurrencyFormatter.format(640000),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.creditAmber),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '4 ${ref.tr('customers_owing')}',
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
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
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryEmerald.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.trending_up_rounded, size: 14, color: AppColors.primaryEmerald),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _hideFigures ? '••••••' : CurrencyFormatter.format(480000),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primaryForest),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '+26% profit margin',
                          style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // UGANDA CASH FLOW SPLIT (MTN MoMo, Airtel, Cash, Bank)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
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
                        ref.tr('cash_flow_breakdown'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      const Icon(Icons.account_balance_wallet_rounded, size: 18, color: AppColors.textLight),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildGatewayPill(
                        gateway: 'MTN MoMo',
                        amount: 980000,
                        color: AppColors.mtnYellow,
                        textColor: Colors.black,
                        icon: Icons.phone_android_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildGatewayPill(
                        gateway: 'Airtel Money',
                        amount: 320000,
                        color: AppColors.airtelRed,
                        textColor: Colors.white,
                        icon: Icons.send_to_mobile_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildGatewayPill(
                        gateway: ref.tr('pay_cash'),
                        amount: 450000,
                        color: AppColors.cashGreen,
                        textColor: Colors.white,
                        icon: Icons.payments_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildGatewayPill(
                        gateway: ref.tr('pay_bank'),
                        amount: 100000,
                        color: AppColors.bankBlue,
                        textColor: Colors.white,
                        icon: Icons.account_balance_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // QUICK ACTIONS (Tactile Colorful Grid)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ref.tr('quick_actions'),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.3),
                ),
              ],
            ),
            const SizedBox(height: 10),

            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildActionTile(
                  title: ref.tr('action_new_sale'),
                  icon: Icons.point_of_sale_rounded,
                  color: AppColors.primaryForest,
                  gradient: AppColors.heroGradient,
                  onTap: () => widget.onNavigateTab(1),
                ),
                _buildActionTile(
                  title: ref.tr('action_log_expense'),
                  icon: Icons.money_off_rounded,
                  color: AppColors.danger,
                  gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const ExpensesScreen()),
                    );
                  },
                ),
                _buildActionTile(
                  title: ref.tr('action_debtor_book'),
                  icon: Icons.people_alt_rounded,
                  color: AppColors.creditAmber,
                  gradient: AppColors.creditGradient,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const DebtorBookScreen()),
                    );
                  },
                ),
                _buildActionTile(
                  title: ref.tr('action_stock_levels'),
                  icon: Icons.inventory_2_rounded,
                  color: Colors.teal,
                  gradient: const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF0D9488)]),
                  onTap: () => widget.onNavigateTab(2),
                ),
                _buildActionTile(
                  title: ref.tr('action_reports'),
                  icon: Icons.bar_chart_rounded,
                  color: Colors.indigo,
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                  onTap: () => widget.onNavigateTab(3),
                ),
                _buildActionTile(
                  title: ref.tr('action_efris_tax'),
                  icon: Icons.verified_rounded,
                  color: AppColors.efrisIndigo,
                  gradient: const LinearGradient(colors: [Color(0xFF818CF8), Color(0xFF4F46E5)]),
                  onTap: () => widget.onNavigateTab(3),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // LOW STOCK WARNING ALERT BANNER
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: AppColors.accentAmber, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '2 ${ref.tr('low_stock_warning')}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.brown),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Super NPK Fertilizer (4 bags), Longe 5 Maize (2 pkts)',
                          style: TextStyle(fontSize: 11, color: Colors.brown.shade700),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => widget.onNavigateTab(2),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentAmber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(ref.tr('restock_btn'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGatewayPill({
    required String gateway,
    required num amount,
    required Color color,
    required Color textColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 10, color: textColor),
                      const SizedBox(width: 3),
                      Text(
                        gateway,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _hideFigures ? '••••••' : CurrencyFormatter.formatCompact(amount),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textMain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required Color color,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMain),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
