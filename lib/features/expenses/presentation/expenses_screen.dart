import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/uganda_presets.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/database/app_database.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String _selectedFilter = 'All';

  void _showAddExpenseDialog([UgandaExpenseCategory? preset]) {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedCategory = preset?.labelEn ?? UgandaPresets.expenseCategories.first.labelEn;
    String paymentMethod = UgandaPresets.paymentCash;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  initialValue: selectedCategory,
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
                    labelText: '${ref.tr('amount_spent')} (UGX) *',
                    hintText: 'e.g. 20000',
                    prefixIcon: const Icon(Icons.payments_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(
                    labelText: ref.tr('expense_notes'),
                    hintText: 'e.g. Boda for deliveries to market',
                    prefixIcon: const Icon(Icons.note_alt_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 14),
                Text(ref.tr('select_payment_method'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPayMethodCard(
                      label: 'Cash',
                      value: UgandaPresets.paymentCash,
                      isSelected: paymentMethod == UgandaPresets.paymentCash,
                      color: AppColors.cashGreen,
                      onTap: () => setSheetState(() => paymentMethod = UgandaPresets.paymentCash),
                    ),
                    const SizedBox(width: 8),
                    _buildPayMethodCard(
                      label: 'MTN MoMo',
                      value: UgandaPresets.paymentMtnMomo,
                      isSelected: paymentMethod == UgandaPresets.paymentMtnMomo,
                      color: AppColors.mtnYellow,
                      onTap: () => setSheetState(() => paymentMethod = UgandaPresets.paymentMtnMomo),
                    ),
                    const SizedBox(width: 8),
                    _buildPayMethodCard(
                      label: 'Airtel',
                      value: UgandaPresets.paymentAirtelMoney,
                      isSelected: paymentMethod == UgandaPresets.paymentAirtelMoney,
                      color: AppColors.airtelRed,
                      onTap: () => setSheetState(() => paymentMethod = UgandaPresets.paymentAirtelMoney),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid expense amount')),
                        );
                        return;
                      }

                      final catObj = UgandaPresets.expenseCategories.firstWhere(
                        (c) => c.labelEn == selectedCategory,
                        orElse: () => UgandaPresets.expenseCategories.first,
                      );

                      final session = ref.read(authProvider);
                      final newExpense = LocalExpenseData(
                        id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
                        businessId: session?.businessId ?? 'biz_default',
                        categoryName: selectedCategory,
                        icon: catObj.icon,
                        amount: amount,
                        paymentMethod: paymentMethod,
                        notes: notesCtrl.text.trim(),
                        date: DateTime.now().millisecondsSinceEpoch,
                      );

                      ref.read(expensesProvider.notifier).addExpense(newExpense);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ref.tr('expense_logged'))),
                      );
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: Text(ref.tr('save_expense'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPayMethodCard({
    required String label,
    required String value,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? Colors.transparent : AppColors.borderLight),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? (value == UgandaPresets.paymentMtnMomo ? Colors.black : Colors.white) : AppColors.textMain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final weekStart = now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    final monthStart = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;

    final filtered = expenses.where((e) {
      switch (_selectedFilter) {
        case 'Today':
          return e.date >= todayStart;
        case 'This Week':
          return e.date >= weekStart;
        case 'This Month':
          return e.date >= monthStart;
        default:
          return true;
      }
    }).toList();

    final totalSpent = filtered.fold<double>(0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(ref.tr('expenses_title')),
      ),
      body: Column(
        children: [
          // Total Spent Banner
          Container(
            margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF881337), Color(0xFFE11D48)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.tr('total_expenses'),
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(totalSpent),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${filtered.length} Items',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Quick Presets Carousel
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: UgandaPresets.expenseCategories.take(4).map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Text(cat.icon, style: const TextStyle(fontSize: 12)),
                    label: Text(cat.labelEn, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _showAddExpenseDialog(cat),
                  ),
                );
              }).toList(),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: ['All', 'Today', 'This Week', 'This Month'].map((f) {
                final isSelected = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(f, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600)),
                    selected: isSelected,
                    selectedColor: AppColors.primaryForest,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? AppColors.darkTextMain : AppColors.textMain)),
                    onSelected: (_) => setState(() => _selectedFilter = f),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 4),

          // Expenses List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          expenses.isEmpty ? ref.tr('no_expenses') : 'No expenses in selected period',
                          style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final item = filtered[index];
                      final date = DateTime.fromMillisecondsSinceEpoch(item.date);
                      final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} · ${date.day}/${date.month}';

                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: AppColors.danger,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          ref.read(expensesProvider.notifier).deleteExpense(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Expense deleted')),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(item.icon, style: const TextStyle(fontSize: 20)),
                            ),
                            title: Text(
                              item.categoryName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            subtitle: Text(
                              '${item.notes.isNotEmpty ? '${item.notes} · ' : ''}$timeStr',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              CurrencyFormatter.format(item.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialog(),
        backgroundColor: const Color(0xFFE11D48),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          ref.tr('log_expense'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
