import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/uganda_presets.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/providers/app_providers.dart';

class LocalExpense {
  final String id;
  final String categoryName;
  final String icon;
  final double amount;
  final String paymentMethod;
  final String notes;
  final String timeStr;

  LocalExpense({
    required this.id,
    required this.categoryName,
    required this.icon,
    required this.amount,
    required this.paymentMethod,
    required this.notes,
    required this.timeStr,
  });
}

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final List<LocalExpense> _expenses = [
    LocalExpense(id: 'e1', categoryName: 'Transport (Boda/Taxi/Fuel)', icon: '🛵', amount: 25000, paymentMethod: 'cash', notes: 'Boda for seed delivery to market', timeStr: '11:30 AM'),
    LocalExpense(id: 'e2', categoryName: 'Staff Meals & Refreshments', icon: '🍲', amount: 15000, paymentMethod: 'mtn_momo', notes: 'Staff lunch (Kiyindi)', timeStr: '01:15 PM'),
    LocalExpense(id: 'e3', categoryName: 'Airtime & Internet / Data', icon: '📱', amount: 10000, paymentMethod: 'airtel_money', notes: 'Monthly shop WhatsApp bundle', timeStr: '02:45 PM'),
  ];

  double get _totalExpenses => _expenses.fold(0, (sum, e) => sum + e.amount);

  void _showAddExpenseDialog([UgandaExpenseCategory? preset]) {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedCategory = preset?.labelEn ?? UgandaPresets.expenseCategories.first.labelEn;
    String paymentMethod = UgandaPresets.paymentCash;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(ref.tr('log_expense'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const Divider(),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(labelText: '${ref.tr('expense_category')} *'),
                  items: UgandaPresets.expenseCategories.map((cat) {
                    final lang = ref.read(languageProvider);
                    final label = lang == 'lg' ? cat.labelLg : lang == 'rn' ? cat.labelRn : cat.labelEn;
                    return DropdownMenuItem(value: cat.labelEn, child: Text(label, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) => setSheetState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${ref.tr('amount_spent')} *',
                    hintText: 'e.g. 20000',
                    prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: InputDecoration(labelText: '${ref.tr('paid_via')} *'),
                  items: [
                    DropdownMenuItem(value: UgandaPresets.paymentCash, child: Text(ref.tr('pay_cash'))),
                    DropdownMenuItem(value: UgandaPresets.paymentMtnMomo, child: Text(ref.tr('pay_momo'))),
                    DropdownMenuItem(value: UgandaPresets.paymentAirtelMoney, child: Text(ref.tr('pay_airtel'))),
                    DropdownMenuItem(value: UgandaPresets.paymentBank, child: Text(ref.tr('pay_bank'))),
                  ],
                  onChanged: (val) => setSheetState(() => paymentMethod = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(
                    labelText: ref.tr('description_optional'),
                    hintText: 'e.g. Fuel for generator or market receipt',
                    prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final amt = double.tryParse(amountCtrl.text) ?? 0;
                      if (amt <= 0) return;

                      setState(() {
                        _expenses.insert(
                          0,
                          LocalExpense(
                            id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
                            categoryName: selectedCategory,
                            icon: '💸',
                            amount: amt,
                            paymentMethod: paymentMethod,
                            notes: notesCtrl.text.isEmpty ? 'Daily expense' : notesCtrl.text,
                            timeStr: 'Just now',
                          ),
                        );
                      });

                      final syncEngine = ref.read(syncEngineProvider);
                      syncEngine?.enqueueMutation(
                        entityType: 'transaction',
                        action: 'create',
                        payload: {
                          'type': 'expense',
                          'category': selectedCategory,
                          'amount': amt,
                          'paymentMethod': paymentMethod,
                          'notes': notesCtrl.text,
                        },
                      );

                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: Text(ref.tr('save_expense'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(ref.tr('expenses_title')),
      ),
      body: Column(
        children: [
          // Total Expense Header Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.tr('todays_total_expenses'),
                      style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(_totalExpenses),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.danger, letterSpacing: -0.5),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddExpenseDialog(),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(ref.tr('log_expense'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),

          // 1-Tap Preset Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const Icon(Icons.flash_on_rounded, size: 16, color: AppColors.accentGold),
                  const SizedBox(width: 4),
                  Text(
                    ref.tr('one_tap_presets'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textMain),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          SizedBox(
            height: 42,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              itemCount: UgandaPresets.expenseCategories.length,
              itemBuilder: (ctx, i) {
                final cat = UgandaPresets.expenseCategories[i];
                final label = lang == 'lg' ? cat.labelLg : lang == 'rn' ? cat.labelRn : cat.labelEn;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onPressed: () => _showAddExpenseDialog(cat),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // Expense List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _expenses.length,
              itemBuilder: (ctx, index) {
                final exp = _expenses[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.015),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(exp.icon, style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exp.categoryName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('${exp.notes} • ${exp.timeStr}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '- ${CurrencyFormatter.format(exp.amount)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.danger, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              exp.paymentMethod.toUpperCase(),
                              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
