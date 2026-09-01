import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import 'invoices_screen.dart';
import 'receivables_screen.dart';
import 'payables_screen.dart';

class AccountingHubScreen extends ConsumerStatefulWidget {
  const AccountingHubScreen({super.key});

  @override
  ConsumerState<AccountingHubScreen> createState() =>
      _AccountingHubScreenState();
}

class _AccountingHubScreenState extends ConsumerState<AccountingHubScreen> {
  late final AppDatabase db;
  List<LocalChartOfAccountData> accounts = [];
  List<LocalJournalEntryData> entries = [];

  @override
  void initState() {
    super.initState();
    db = ref.read(databaseProvider);
    _load();
  }

  Future<void> _load() async {
    await db.init();
    final coa = await db.getChartOfAccounts();
    final journal = await db.getJournalEntries();
    if (!mounted) return;
    setState(() {
      accounts = coa;
      entries = journal;
    });
  }

  Future<void> _createDemoEntry() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final entry = LocalJournalEntryData(
      id: 'je_${now}',
      businessId: 'biz_default',
      reference: 'JE-${DateTime.now().millisecondsSinceEpoch % 100000}',
      memo: 'Demo accounting entry',
      debitAccountId: 'coa_cash',
      creditAccountId: 'coa_sales',
      amount: 250000,
      entryDate: now,
      createdAt: now,
    );
    await db.createJournalEntry(entry);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Accounting Hub'),
        actions: [
          IconButton(
            onPressed: _createDemoEntry,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _summaryCard(
              'Chart of Accounts',
              '${accounts.length} active accounts',
              Icons.account_tree_rounded,
              AppColors.primaryEmerald,
            ),
            const SizedBox(height: 12),
            _summaryCard(
              'Journal Entries',
              '${entries.length} posted entries',
              Icons.receipt_long_rounded,
              AppColors.accentGold,
            ),
            const SizedBox(height: 20),
            const Text('Accounts',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 8),
            if (accounts.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No chart of accounts yet.'),
                ),
              )
            else
              ...accounts.take(6).map((account) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            AppColors.primaryEmerald.withValues(alpha: 0.12),
                        child: Text(account.code.substring(0, 1)),
                      ),
                      title: Text(account.name),
                      subtitle: Text('${account.code} • ${account.type}'),
                      trailing: Text(account.normalSide.toUpperCase()),
                    ),
                  )),
            const SizedBox(height: 20),
            const Text('Recent Journal Entries',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No journal entries yet.'),
                ),
              )
            else
              ...entries.take(5).map((entry) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      title: Text(entry.reference),
                      subtitle: Text(entry.memo),
                      trailing: Text('UGX ${entry.amount.toStringAsFixed(0)}'),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
      String title, String subtitle, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
