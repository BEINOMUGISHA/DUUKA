import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../expenses/presentation/expenses_screen.dart';
import '../../credit/presentation/debtor_book_screen.dart';

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

    const double totalBalance = 4286500;
    const double income = 1800000;
    const double expenses = 620000;
    const double profit = 1160000;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // surface-1
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
                color: Colors.white, // surface-2
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
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
                              color: AppColors.primaryForest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session?.businessName ?? 'Kampala Ventures',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                ref.tr('nav_dashboard'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Language Switcher
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                lang == 'lg' ? '🇺🇬 LG' : lang == 'rn' ? '🇺🇬 RN' : '🇬🇧 EN',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
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

                          // Notification Bell with Red Dot
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 19,
                                  color: Color(0xFF334155),
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

                  // --- 2. TOTAL BALANCE HERO CARD (With SVG Polyline Wave) ---
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryForest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // SVG Polyline Wave at bottom
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

                        // Card Content
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
                                _hideFigures ? 'UGX ••••••••' : 'UGX 4,286,500',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildStatColumn(
                                    label: lang == 'lg' ? 'Eziyingidde' : 'Income',
                                    value: _hideFigures ? '••••' : '↑ 1.8M',
                                  ),
                                  const SizedBox(width: 24),
                                  _buildStatColumn(
                                    label: lang == 'lg' ? 'Ezafulumye' : 'Expenses',
                                    value: _hideFigures ? '••••' : '↓ 620K',
                                  ),
                                  const SizedBox(width: 24),
                                  _buildStatColumn(
                                    label: lang == 'lg' ? 'Amagoba' : 'Profit',
                                    value: _hideFigures ? '••••' : '1.16M',
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
                        iconColor: const Color(0xFF0F766E), // text-accent
                        onTap: () => widget.onNavigateTab(1),
                      ),
                      _buildQuickAction(
                        icon: Icons.receipt_long_rounded,
                        label: lang == 'lg' ? 'Ezafulumye' : 'Expense',
                        iconColor: const Color(0xFFEF4444), // text-danger
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
                        iconColor: const Color(0xFF7C3AED), // text-pro
                        onTap: () => widget.onNavigateTab(3),
                      ),
                      _buildQuickAction(
                        icon: Icons.description_outlined,
                        label: lang == 'lg' ? 'Ebbanja' : 'Invoice',
                        iconColor: const Color(0xFF10B981), // text-success
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

                  // --- 4. TWO ALERT PILLS (Low stock & Overdue) ---
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => widget.onNavigateTab(3),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7), // bg-warning
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: Color(0xFFD97706),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    lang == 'lg' ? 'Ebyamaguzi 3 bikendedde' : '3 low stock items',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFB45309),
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
                              color: const Color(0xFFCCFBF1), // bg-accent
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: Color(0xFF0D9488),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    lang == 'lg' ? 'Amabanja 2 gayiseeko' : '2 invoices overdue',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F766E),
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      InkWell(
                        onTap: () => widget.onNavigateTab(2),
                        child: Text(
                          lang == 'lg' ? 'Laba byonna' : 'See all',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0F766E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Column(
                    children: [
                      _buildTransactionItem(
                        icon: Icons.north_east_rounded,
                        iconBg: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF16A34A),
                        title: 'Sale — cooking oil x2',
                        subtitle: 'MTN MoMo · 10 min ago',
                        amount: '+45,000',
                        amountColor: const Color(0xFF16A34A),
                        hasBorder: true,
                      ),
                      _buildTransactionItem(
                        icon: Icons.south_east_rounded,
                        iconBg: const Color(0xFFFEE2E2),
                        iconColor: const Color(0xFFDC2626),
                        title: 'Transport expense',
                        subtitle: 'Cash · 1 hr ago',
                        amount: '-15,000',
                        amountColor: const Color(0xFFDC2626),
                        hasBorder: true,
                      ),
                      _buildTransactionItem(
                        icon: Icons.access_time_rounded,
                        iconBg: const Color(0xFFF1F5F9),
                        iconColor: const Color(0xFF64748B),
                        title: 'Invoice — J. Okello',
                        subtitle: 'Credit sale · Yesterday',
                        amount: '120,000',
                        amountColor: const Color(0xFF334155),
                        hasBorder: false,
                      ),
                    ],
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
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF475569),
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: hasBorder
            ? const Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.5))
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
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

// Sparkline / Polyline Painter matching the SVG polyline in the HTML:
// points="0,40 30,32 60,38 90,20 120,28 150,10 180,22 210,14 240,18 270,6 300,12"
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
