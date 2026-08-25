import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/uganda_presets.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/providers/app_providers.dart';

class DebtorCustomer {
  final String id;
  final String name;
  final String phone;
  double balanceOwed;
  double creditLimit;
  String lastSaleDate;

  DebtorCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.balanceOwed,
    required this.creditLimit,
    required this.lastSaleDate,
  });
}

class DebtorBookScreen extends ConsumerStatefulWidget {
  const DebtorBookScreen({super.key});

  @override
  ConsumerState<DebtorBookScreen> createState() => _DebtorBookScreenState();
}

class _DebtorBookScreenState extends ConsumerState<DebtorBookScreen> {
  final List<DebtorCustomer> _debtors = [
    DebtorCustomer(id: 'c1', name: 'Mugisha Patrick (Farm)', phone: '0772889900', balanceOwed: 250000, creditLimit: 500000, lastSaleDate: '2026-08-20'),
    DebtorCustomer(id: 'c2', name: 'Mama Sarah General Store', phone: '0754112233', balanceOwed: 180000, creditLimit: 300000, lastSaleDate: '2026-08-22'),
    DebtorCustomer(id: 'c3', name: 'Kato Denis (Builder)', phone: '0701998877', balanceOwed: 140000, creditLimit: 200000, lastSaleDate: '2026-08-15'),
    DebtorCustomer(id: 'c4', name: 'Namubiru Grace', phone: '0788334455', balanceOwed: 70000, creditLimit: 100000, lastSaleDate: '2026-08-24'),
  ];

  double get _totalDebtorBalance => _debtors.fold(0, (sum, d) => sum + d.balanceOwed);

  void _showRecordPaymentDialog(DebtorCustomer debtor) {
    final amountCtrl = TextEditingController();
    String paymentMethod = UgandaPresets.paymentMtnMomo;
    final refCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('${ref.tr('record_repayment')}: ${debtor.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.creditAmber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ref.tr('current_balance_owed'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(
                        CurrencyFormatter.format(debtor.balanceOwed),
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.creditAmber, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${ref.tr('amount_paid')} *',
                    hintText: 'e.g. 50000',
                    prefixIcon: const Icon(Icons.payments_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: InputDecoration(labelText: ref.tr('paid_via')),
                  items: [
                    DropdownMenuItem(value: UgandaPresets.paymentMtnMomo, child: Text(ref.tr('pay_momo'))),
                    DropdownMenuItem(value: UgandaPresets.paymentAirtelMoney, child: Text(ref.tr('pay_airtel'))),
                    DropdownMenuItem(value: UgandaPresets.paymentCash, child: Text(ref.tr('pay_cash'))),
                    DropdownMenuItem(value: UgandaPresets.paymentBank, child: Text(ref.tr('pay_bank'))),
                  ],
                  onChanged: (val) => setDialogState(() => paymentMethod = val ?? UgandaPresets.paymentMtnMomo),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refCtrl,
                  decoration: InputDecoration(
                    labelText: ref.tr('description_optional'),
                    prefixIcon: const Icon(Icons.tag_rounded),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ref.tr('cancel'))),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amountCtrl.text) ?? 0;
                if (amt <= 0) return;

                setState(() {
                  debtor.balanceOwed = (debtor.balanceOwed - amt).clamp(0, 99999999);
                });

                final syncEngine = ref.read(syncEngineProvider);
                syncEngine?.enqueueMutation(
                  entityType: 'customer_payment',
                  action: 'create',
                  payload: {
                    'customerId': debtor.id,
                    'amount': amt,
                    'paymentMethod': paymentMethod,
                    'reference': refCtrl.text,
                  },
                );

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.primaryForest,
                    content: Text('🎉 ${CurrencyFormatter.format(amt)} collected from ${debtor.name}!'),
                  ),
                );
              },
              child: Text(ref.tr('save_repayment')),
            ),
          ],
        ),
      ),
    );
  }

  void _sendSmsReminder(DebtorCustomer debtor) {
    final lang = ref.read(languageProvider);
    final session = ref.read(authProvider);
    final businessName = session?.businessName ?? 'DUKA SME';
    final amountStr = CurrencyFormatter.format(debtor.balanceOwed);

    String message;
    if (lang == 'lg') {
      message = 'Nkulamusizza ${debtor.name}, eno ye $businessName. Tukujjukizaako ebbanja lyo erya $amountStr. Osobola okusasula ku MTN MoMo oba Airtel Money. Weebale nnyo!';
    } else if (lang == 'rn') {
      message = 'Agandi ${debtor.name}, oku niyo $businessName. Nitukwijutsya omwenda gwaawe gwa $amountStr. Noobaasa kushashura na MTN MoMo nari Airtel Money. Webare munonga!';
    } else {
      message = 'Dear ${debtor.name}, warm greetings from $businessName. This is a friendly reminder regarding your outstanding balance of $amountStr. You can pay via MTN MoMo, Airtel Money, or cash. Thank you for your business!';
    }

    Share.share(message, subject: 'Payment Reminder - $businessName');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(ref.tr('debtor_book_title')),
      ),
      body: Column(
        children: [
          // Total Debtor Balance Gradient Hero
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.creditGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.creditAmber.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
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
                      ref.tr('total_outstanding_credit'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(_totalDebtorBalance),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_debtors.length} ${ref.tr('active_debtors')}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.05, end: 0),

          // Debtors List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _debtors.length,
              itemBuilder: (ctx, index) {
                final debtor = _debtors[index];
                final creditRatio = (debtor.balanceOwed / debtor.creditLimit).clamp(0.0, 1.0);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
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
                          Expanded(
                            child: Text(
                              debtor.name,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(debtor.balanceOwed),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: AppColors.creditAmber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_rounded, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(debtor.phone, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 12),
                          Text('${ref.tr('last_sale')}: ${debtor.lastSaleDate}', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Credit Limit Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Credit Limit: ${CurrencyFormatter.formatCompact(debtor.creditLimit)}',
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${(creditRatio * 100).toInt()}% Used',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: creditRatio > 0.8 ? AppColors.danger : AppColors.creditAmber,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: creditRatio,
                              minHeight: 4,
                              backgroundColor: AppColors.surfaceMuted,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                creditRatio > 0.8 ? AppColors.danger : AppColors.creditAmber,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 20),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _sendSmsReminder(debtor),
                            icon: const Icon(Icons.sms_rounded, size: 14),
                            label: Text(ref.tr('sms_reminder'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryForest,
                              side: const BorderSide(color: AppColors.primaryForest),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showRecordPaymentDialog(debtor),
                            icon: const Icon(Icons.payment_rounded, size: 14),
                            label: Text(ref.tr('record_payment'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryForest,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
