import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  late final AppDatabase db;
  List<LocalInvoiceData> invoices = [];

  @override
  void initState() {
    super.initState();
    db = ref.read(databaseProvider);
    _load();
  }

  Future<void> _load() async {
    await db.init();
    final list = await db.getInvoices();
    if (!mounted) return;
    setState(() {
      invoices = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Invoices'),
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
                        color: AppColors.accentGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.receipt_long_rounded,
                          color: AppColors.accentGold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${invoices.length} invoices',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text('Issued & tracked',
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
            if (invoices.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No invoices yet.'),
                ),
              )
            else
              ...invoices.map((inv) {
                final statusColor = inv.status == 'paid'
                    ? AppColors.success
                    : (inv.status == 'overdue'
                        ? AppColors.danger
                        : AppColors.accentGold);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    dense: true,
                    title: Text(inv.invoiceNumber),
                    subtitle: Text(
                        '${inv.customerName} • UGX ${inv.totalAmount.toStringAsFixed(0)}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(inv.status.toUpperCase(),
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
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
