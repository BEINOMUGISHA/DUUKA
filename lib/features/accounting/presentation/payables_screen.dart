import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';

class PayablesScreen extends ConsumerStatefulWidget {
  const PayablesScreen({super.key});

  @override
  ConsumerState<PayablesScreen> createState() => _PayablesScreenState();
}

class _PayablesScreenState extends ConsumerState<PayablesScreen> {
  late final AppDatabase db;
  List<LocalPayableData> payables = [];

  @override
  void initState() {
    super.initState();
    db = ref.read(databaseProvider);
    _load();
  }

  Future<void> _load() async {
    await db.init();
    final list = await db.getPayables();
    if (!mounted) return;
    setState(() {
      payables = list;
    });
  }

  Future<void> _recordPayment(LocalPayableData pay) async {
    final amountController = TextEditingController();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pay Bill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${pay.vendorName} - UGX ${pay.amount.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Amount to pay',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                await db.recordPayablePayment(pay.id, amount);
                if (!mounted) return;
                Navigator.pop(ctx);
                await _load();
              }
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalAP = payables.fold<double>(0, (sum, p) => sum + p.amount);
    final paidItems = payables.where((p) => p.status == 'paid').length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Payables (AP)'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.trending_up_rounded,
                          color: AppColors.danger),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('UGX ${totalAP.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text('$paidItems of ${payables.length} paid',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (payables.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No outstanding payables.'),
                ),
              )
            else
              ...payables.map((pay) {
                final statusColor = pay.status == 'paid'
                    ? AppColors.success
                    : (pay.status == 'partial'
                        ? AppColors.accentGold
                        : AppColors.danger);
                final daysOverdue =
                    DateTime.now().millisecondsSinceEpoch > pay.dueDate
                        ? 'OVERDUE'
                        : '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    dense: true,
                    title: Text(pay.vendorName),
                    subtitle: Text(
                        '${pay.reference} • UGX ${pay.amount.toStringAsFixed(0)}'),
                    trailing: GestureDetector(
                      onTap: () => _recordPayment(pay),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                            pay.status.toUpperCase().isEmpty
                                ? 'OPEN'
                                : pay.status.toUpperCase(),
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
