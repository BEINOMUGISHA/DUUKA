import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/phone_formatter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/database/app_database.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final LocalCustomerData customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  void _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not initiate call to $phone')),
        );
      }
    }
  }

  void _sendSmsReminder(LocalCustomerData customer) {
    final session = ref.read(authProvider);
    final businessName = session?.businessName ?? 'DUUKA Shop';
    final message =
        'Hello ${customer.name}, this is a friendly reminder from $businessName that your current balance is ${CurrencyFormatter.format(customer.currentDebt)}. Please pay via MTN MoMo or Airtel Money. Thank you!';

    final sms = LocalSmsData(
      id: 'sms_${DateTime.now().millisecondsSinceEpoch}',
      businessId: customer.businessId,
      customerId: customer.id,
      phone: customer.phone,
      message: message,
      type: 'debt_reminder',
      status: 'sent',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    ref.read(smsProvider.notifier).logSms(sms);

    Share.share(message, subject: 'Payment Reminder - $businessName');
  }

  void _sendWhatsAppReceipt(
      LocalCustomerData customer, LocalSaleData sale) async {
    final session = ref.read(authProvider);
    final businessName = session?.businessName ?? 'DUUKA Shop';
    final date = DateTime.fromMillisecondsSinceEpoch(sale.localTimestamp);
    final dateStr = '${date.day}/${date.month}/${date.year}';

    String itemsText = '';
    try {
      final items = jsonDecode(sale.itemsJson) as List<dynamic>;
      for (final it in items) {
        itemsText +=
            '• ${it['quantity']}x ${it['name']} - ${CurrencyFormatter.format((it['subtotal'] as num).toDouble())}\n';
      }
    } catch (_) {}

    final text = '''
🧾 *RECEIPT: ${sale.saleNumber}*
🏪 *$businessName*
📅 Date: $dateStr
👤 Customer: ${customer.name}

*Items Purchased:*
$itemsText
*Total Amount:* ${CurrencyFormatter.format(sale.totalAmount)}
*Payment Method:* ${sale.paymentMethod.toUpperCase()}
${sale.isCredit ? '⏳ Payment Status: Credit / Pending' : '✅ Payment Status: Paid in Full'}

Thank you for your business! 🙏
''';

    final normalized = PhoneFormatter.normalize(customer.phone);
    final uri = Uri.parse(
        'https://wa.me/$normalized?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showRecordPaymentDialog(LocalCustomerData customer) {
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    String paymentMethod = 'mtn_momo';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text('Receive Payment from ${customer.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Outstanding Debt: ${CurrencyFormatter.format(customer.currentDebt)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.danger),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount Paid (UGX) *',
                  prefixIcon: Icon(Icons.payments_rounded),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'mtn_momo', child: Text('MTN MoMo')),
                  DropdownMenuItem(
                      value: 'airtel_money', child: Text('Airtel Money')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                ],
                onChanged: (val) => setModalState(() => paymentMethod = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid amount')),
                  );
                  return;
                }

                final updatedDebt =
                    (customer.currentDebt - amount).clamp(0.0, double.infinity);
                ref.read(customersProvider.notifier).updateCustomer(
                      customer.copyWith(currentDebt: updatedDebt),
                    );

                ref.read(debtorsProvider.notifier).recordPayment(
                      'd_${customer.id}',
                      amount,
                      paymentMethod,
                      refCtrl.text.trim().isNotEmpty
                          ? refCtrl.text.trim()
                          : null,
                    );

                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Payment of ${CurrencyFormatter.format(amount)} recorded')),
                );
              },
              child: const Text('Confirm Payment',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);
    final currentCustomer = customers.firstWhere(
        (c) => c.id == widget.customer.id,
        orElse: () => widget.customer);
    final sales = ref
        .watch(salesProvider)
        .where((s) =>
            s.customerId == currentCustomer.id ||
            s.customerPhone == currentCustomer.phone)
        .toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate customer analytics
    final totalSpent = sales.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final orderCount = sales.length;
    final aov = orderCount > 0 ? (totalSpent / orderCount) : 0.0;

    // Top purchased products by this customer
    final productCounts = <String, double>{};
    for (final s in sales) {
      try {
        final items = jsonDecode(s.itemsJson) as List<dynamic>;
        for (final it in items) {
          final n = it['name'] as String? ?? 'Item';
          final q = (it['quantity'] as num?)?.toDouble() ?? 1.0;
          productCounts[n] = (productCounts[n] ?? 0) + q;
        }
      } catch (_) {}
    }
    final topPurchased = productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(currentCustomer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_rounded),
            tooltip: 'Call Customer',
            onPressed: () => _makePhoneCall(currentCustomer.phone),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Customer Summary Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(currentCustomer.tagColor),
                  Color(currentCustomer.tagColor).withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  currentCustomer.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (currentCustomer.tier == 'wholesale') ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('WHOLESALE',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 9)),
                                ),
                              ] else if (currentCustomer.isFavorite ||
                                  currentCustomer.tier == 'vip') ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentGold,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star_rounded,
                                          size: 12, color: Colors.white),
                                      SizedBox(width: 2),
                                      Text('VIP',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            PhoneFormatter.formatDisplay(currentCustomer.phone),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            CustomerFavoriteColors.getByColorValue(
                                    currentCustomer.tagColor)
                                .label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Outstanding Debt',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11)),
                        Text(
                          CurrencyFormatter.format(currentCustomer.currentDebt),
                          style: TextStyle(
                            color: currentCustomer.currentDebt > 0
                                ? const Color(0xFFFCA5A5)
                                : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Credit Limit',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11)),
                        Text(
                          CurrencyFormatter.format(currentCustomer.creditLimit),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRecordPaymentDialog(currentCustomer),
                  icon: const Icon(Icons.payments_rounded, size: 18),
                  label: const Text('Pay Debt',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _sendSmsReminder(currentCustomer),
                  icon: const Icon(Icons.sms_rounded, size: 18),
                  label: const Text('SMS Reminder'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Customer Spending Insights (UgaPOS feature)
          const Text('Customer Spending Patterns',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Lifetime Spend',
                  value: CurrencyFormatter.format(totalSpent),
                  color: AppColors.primaryForest,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricBox(
                  icon: Icons.shopping_basket_rounded,
                  label: 'Total Orders',
                  value: '$orderCount Visits',
                  color: const Color(0xFF0284C7),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricBox(
                  icon: Icons.pie_chart_outline_rounded,
                  label: 'Avg Order',
                  value: CurrencyFormatter.format(aov),
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Top Purchased Products by this Customer
          if (topPurchased.isNotEmpty) ...[
            const Text('Favorite / Most Purchased Products',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: topPurchased.take(4).map((e) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    '${e.key} (${e.value.toInt()}x)',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
          ],

          // Sales History
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Purchase & Receipt History',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              Text('${sales.length} orders',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),

          if (sales.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Text(
                  'No transactions recorded for this customer yet.',
                  style: TextStyle(color: AppColors.textMuted)),
            )
          else
            ...sales.map((s) {
              final date =
                  DateTime.fromMillisecondsSinceEpoch(s.localTimestamp);
              final timeStr =
                  '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: s.isCredit
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          s.isCredit
                              ? Icons.schedule_rounded
                              : Icons.receipt_rounded,
                          color: s.isCredit
                              ? const Color(0xFFD97706)
                              : AppColors.primaryForest,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.saleNumber,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                              '$timeStr · ${s.paymentMethod.toUpperCase()}',
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(s.totalAmount),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: s.isCredit
                                  ? const Color(0xFFD97706)
                                  : AppColors.primaryForest,
                            ),
                          ),
                          const SizedBox(height: 2),
                          InkWell(
                            onTap: () =>
                                _sendWhatsAppReceipt(currentCustomer, s),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_rounded,
                                    size: 12, color: Color(0xFF0D9488)),
                                SizedBox(width: 2),
                                Text(
                                  'Send Receipt',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF0D9488),
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMetricBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 9.5,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w900, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
