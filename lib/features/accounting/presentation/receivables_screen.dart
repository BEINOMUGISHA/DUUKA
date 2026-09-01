import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';

class ReceivablesScreen extends ConsumerStatefulWidget {
  const ReceivablesScreen({super.key});

  @override
  ConsumerState<ReceivablesScreen> createState() => _ReceivablesScreenState();
}

class _ReceivablesScreenState extends ConsumerState<ReceivablesScreen> {
  late final AppDatabase db;
  List<LocalReceivableData> receivables = [];

  @override
  void initState() {
    super.initState();
    db = ref.read(databaseProvider);
    _load();
  }

  Future<void> _load() async {
    await db.init();
    final list = await db.getReceivables();
    if (!mounted) return;
    setState(() {
      receivables = list;
    });
  }

  Future<void> _recordPayment(LocalReceivableData rec) async {
    final amountController = TextEditingController();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${rec.customerName} - UGX ${rec.amount.toStringAsFixed(0)}'),
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
                await db.recordReceivablePayment(rec.id, amount);
                if (!mounted) return;
                Navigator.pop(ctx);
                await _load();
              }
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalAR = receivables.fold<double>(0, (sum, r) => sum + r.amount);
    final paidItems = receivables.where((r) => r.status == 'paid').length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Receivables (AR)'),
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
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.trending_down_rounded,
                          color: const Color(0xFF059669)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('UGX ${totalAR.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text('$paidItems of ${receivables.length} paid',
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
            if (receivables.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No outstanding receivables.'),
                ),
              )
            else
              ...receivables.map((rec) {
                final statusColor = rec.status == 'paid'
                    ? AppColors.success
                    : (rec.status == 'partial'
                        ? AppColors.accentGold
                        : AppColors.danger);
                final daysOverdue =
                    DateTime.now().millisecondsSinceEpoch > rec.dueDate
                        ? 'OVERDUE'
                        : '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    dense: true,
                    title: Text(rec.customerName),
                    subtitle: Text(
                        'Invoice: ${rec.invoiceId} • UGX ${rec.amount.toStringAsFixed(0)}'),
                    trailing: GestureDetector(
                      onTap: () => _recordPayment(rec),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                            rec.status.toUpperCase().isEmpty
                                ? 'OPEN'
                                : rec.status.toUpperCase(),
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
