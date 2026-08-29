import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/uganda_presets.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/phone_formatter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/database/app_database.dart';

class DebtorBookScreen extends ConsumerStatefulWidget {
  const DebtorBookScreen({super.key});

  @override
  ConsumerState<DebtorBookScreen> createState() => _DebtorBookScreenState();
}

class _DebtorBookScreenState extends ConsumerState<DebtorBookScreen> {
  String _searchQuery = '';

  void _showRecordPaymentDialog(LocalDebtorData debtor) {
    final amountCtrl = TextEditingController();
    String paymentMethod = UgandaPresets.paymentMtnMomo;
    final refCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            '${ref.tr('record_repayment')}: ${debtor.name}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Balance Owed: ${CurrencyFormatter.format(debtor.balanceOwed)}',
                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount Paid (UGX) *',
                    hintText: 'e.g. 50000',
                    prefixIcon: Icon(Icons.payments_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: paymentMethod,
                  decoration: const InputDecoration(labelText: 'Payment Channel *'),
                  items: [
                    DropdownMenuItem(value: UgandaPresets.paymentCash, child: const Text('Cash')),
                    DropdownMenuItem(value: UgandaPresets.paymentMtnMomo, child: const Text('MTN MoMo')),
                    DropdownMenuItem(value: UgandaPresets.paymentAirtelMoney, child: const Text('Airtel Money')),
                    DropdownMenuItem(value: UgandaPresets.paymentBank, child: const Text('Bank Transfer')),
                  ],
                  onChanged: (val) => setDialogState(() => paymentMethod = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refCtrl,
                  decoration: const InputDecoration(
                    labelText: 'MoMo / Receipt Ref (Optional)',
                    hintText: 'e.g. 2489012389',
                    prefixIcon: Icon(Icons.tag_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (amount <= 0 || amount > debtor.balanceOwed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount not exceeding balance owed')),
                  );
                  return;
                }

                // Record payment in debtor record
                ref.read(debtorsProvider.notifier).recordPayment(
                      debtor.id,
                      amount,
                      paymentMethod,
                      refCtrl.text.trim().isNotEmpty ? refCtrl.text.trim() : null,
                    );

                // Also record transaction in ledger
                final session = ref.read(authProvider);
                final tx = LocalTransactionData(
                  id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                  businessId: session?.businessId ?? 'biz_default',
                  type: 'debtor_repayment',
                  category: 'Credit Collection',
                  amount: amount,
                  paymentMethod: paymentMethod,
                  reference: refCtrl.text.trim(),
                  notes: 'Repayment from ${debtor.name}',
                  date: DateTime.now().millisecondsSinceEpoch,
                  deviceId: session?.deviceId ?? 'device-001',
                );
                ref.read(databaseProvider).insertTransaction(tx);

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Received ${CurrencyFormatter.format(amount)} from ${debtor.name}')),
                );
              },
              child: const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDebtorDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final limitCtrl = TextEditingController(text: '300000');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Credit Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Customer Full Name *', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number (WhatsApp/SMS) *', prefixIcon: Icon(Icons.phone)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Initial Debt (UGX) *'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: limitCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Credit Limit (UGX)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                    final limit = double.tryParse(limitCtrl.text.trim()) ?? 300000;
                    final session = ref.read(authProvider);

                    if (name.isEmpty || phone.isEmpty || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all required fields')),
                      );
                      return;
                    }

                    final newDebtor = LocalDebtorData(
                      id: 'd_${DateTime.now().millisecondsSinceEpoch}',
                      businessId: session?.businessId ?? 'biz_default',
                      name: name,
                      phone: phone,
                      balanceOwed: amount,
                      creditLimit: limit,
                      lastSaleDate: DateTime.now().millisecondsSinceEpoch,
                    );

                    ref.read(debtorsProvider.notifier).addDebtor(newDebtor);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Customer added to Debtor Book')),
                    );
                  },
                  child: const Text('Save Customer', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendWhatsAppReminder(LocalDebtorData debtor) async {
    final session = ref.read(authProvider);
    final businessName = session?.businessName ?? 'DUKA Shop';
    final normalizedPhone = PhoneFormatter.normalize(debtor.phone);
    final message =
        'Hello ${debtor.name},\nThis is a friendly payment reminder from $businessName. Your outstanding balance is ${CurrencyFormatter.format(debtor.balanceOwed)}.\nPlease pay via MTN MoMo / Airtel Money. Thank you!';
    final whatsappUrl = Uri.parse('https://wa.me/$normalizedPhone?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        await Share.share(message, subject: 'Payment Reminder - $businessName');
      }
    } catch (_) {
      await Share.share(message, subject: 'Payment Reminder - $businessName');
    }
  }

  Future<void> _sendSmsReminder(LocalDebtorData debtor) async {
    final session = ref.read(authProvider);
    if (session == null) return;
    final businessName = session.businessName;
    final message =
        'Hello ${debtor.name}, friendly reminder from $businessName: your outstanding balance is ${CurrencyFormatter.format(debtor.balanceOwed)}. Please pay via MoMo/Airtel. Thank you!';

    try {
      final convex = ref.read(convexClientProvider);
      final res = await convex.mutation('sms:sendCustomerSms', {
        'businessId': session.businessId,
        'userId': session.userId,
        'phone': debtor.phone,
        'message': message,
        'type': 'debt_reminder',
        'idempotencyKey': 'sms-${debtor.id}-${DateTime.now().millisecondsSinceEpoch}',
      });
      if (mounted) {
        final success = res != null && (res['success'] == true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'SMS sent to ${debtor.name}. Remaining credits: ${res['remainingCredits']}'
                : 'Failed to send SMS: ${res?['error'] ?? 'Unknown error'}'),
            backgroundColor: success ? AppColors.success : AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SMS error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showReminderOptions(LocalDebtorData debtor) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send Reminder to ${debtor.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Amount Due: ${CurrencyFormatter.format(debtor.balanceOwed)}',
                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF25D366),
                  child: Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
                ),
                title: const Text('WhatsApp Message (Free)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Open WhatsApp directly with prefilled message'),
                onTap: () {
                  Navigator.pop(ctx);
                  _sendWhatsAppReminder(debtor);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF4F46E5),
                  child: Icon(Icons.sms_outlined, color: Colors.white, size: 20),
                ),
                title: const Text('Direct SMS (1 Credit)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Dispatches telecom SMS to their phone'),
                onTap: () {
                  Navigator.pop(ctx);
                  _sendSmsReminder(debtor);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF64748B),
                  child: Icon(Icons.share_outlined, color: Colors.white, size: 20),
                ),
                title: const Text('Share via Any App', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Copy or share to Telegram, Email, etc.'),
                onTap: () {
                  Navigator.pop(ctx);
                  final session = ref.read(authProvider);
                  final businessName = session?.businessName ?? 'DUKA Shop';
                  final message =
                      'Hello ${debtor.name},\nThis is a payment reminder from $businessName. Outstanding balance: ${CurrencyFormatter.format(debtor.balanceOwed)}.\nPlease pay via MTN MoMo / Airtel Money. Thank you!';
                  Share.share(message, subject: 'Payment Reminder - $businessName');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBulkRemindDialog() {
    final debtors = ref.read(debtorsProvider);
    final overdueDebtors = debtors.where((d) => d.balanceOwed > 0).toList();
    String selectedLanguage = 'en';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.mark_chat_unread_rounded, color: Color(0xFF4F46E5)),
              SizedBox(width: 10),
              Expanded(
                child: Text('Bulk SMS Reminder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debtors to Remind: ${overdueDebtors.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Estimated SMS Cost: ${overdueDebtors.length} Credits',
                      style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text('Select SMS Language:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedLanguage,
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'lg', child: Text('Luganda')),
                  DropdownMenuItem(value: 'rn', child: Text('Runyankole')),
                ],
                onChanged: (val) => setDialogState(() => selectedLanguage = val!),
              ),
              const SizedBox(height: 12),
              const Text(
                'Each debtor will receive a localized reminder containing their current balance owed.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: isSubmitting
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(
                isSubmitting ? 'Sending...' : 'Send to All (${overdueDebtors.length})',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              onPressed: (overdueDebtors.isEmpty || isSubmitting)
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      final session = ref.read(authProvider);
                      if (session == null) {
                        Navigator.pop(ctx);
                        return;
                      }

                      try {
                        final convex = ref.read(convexClientProvider);
                        final res = await convex.mutation('sms:bulkRemindOverdueDebtors', {
                          'businessId': session.businessId,
                          'userId': session.userId,
                          'language': selectedLanguage,
                          'dryRun': false,
                        });

                        Navigator.pop(ctx);
                        if (mounted) {
                          final sent = res?['sent'] ?? 0;
                          final failed = res?['failed'] ?? 0;
                          final credits = res?['remainingCredits'] ?? 0;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Bulk SMS complete! Sent: $sent, Failed: $failed. Credits remaining: $credits'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Bulk SMS error: $e'), backgroundColor: AppColors.danger),
                          );
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final debtors = ref.watch(debtorsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = debtors.where((d) {
      return d.name.toLowerCase().contains(_searchQuery.toLowerCase()) || d.phone.contains(_searchQuery);
    }).toList();

    final totalOwed = filtered.fold<double>(0, (sum, d) => sum + d.balanceOwed);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(ref.tr('debtor_book')),
        actions: [
          IconButton(
            icon: const Icon(Icons.send_rounded),
            tooltip: 'Bulk SMS Remind All',
            onPressed: debtors.any((d) => d.balanceOwed > 0) ? _showBulkRemindDialog : null,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Add Debtor',
            onPressed: _showAddDebtorDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Receivables Banner
          Container(
            margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF92400E), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Outstanding Credit',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(totalOwed),
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
                    '${filtered.length} Debtors',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search debtors by name or phone...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          const SizedBox(height: 4),

          // Debtor List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          debtors.isEmpty ? 'No debtors recorded yet' : 'No matching debtors',
                          style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final debtor = filtered[index];
                      final isOverLimit = debtor.balanceOwed > debtor.creditLimit;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ExpansionTile(
                          shape: const Border(),
                          collapsedShape: const Border(),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.creditAmber.withValues(alpha: 0.15),
                            child: const Icon(Icons.person_outline_rounded, color: AppColors.creditAmber),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  debtor.name,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(debtor.balanceOwed),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.danger),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${debtor.phone} · Limit: ${CurrencyFormatter.format(debtor.creditLimit)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isOverLimit ? AppColors.danger : AppColors.textMuted,
                              fontWeight: isOverLimit ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(),
                                  if (debtor.paymentHistory.isNotEmpty) ...[
                                    const Text('Payment History:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    ...debtor.paymentHistory.map((p) {
                                      final pDate = DateTime.fromMillisecondsSinceEpoch(p['date'] as int);
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${pDate.day}/${pDate.month} · ${p['method'].toString().toUpperCase()}',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                            ),
                                            Text(
                                              '+${CurrencyFormatter.format((p['amount'] as num).toDouble())}',
                                              style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 8),
                                  ],
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => _showReminderOptions(debtor),
                                        icon: const Icon(Icons.send_rounded, size: 15),
                                        label: const Text('Send Reminder', style: TextStyle(fontSize: 12)),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => _showRecordPaymentDialog(debtor),
                                        icon: const Icon(Icons.payments_rounded, size: 16),
                                        label: const Text('Repay', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
