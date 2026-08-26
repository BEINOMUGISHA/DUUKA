import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/phone_formatter.dart';
import '../../../core/providers/app_providers.dart';
import 'receive_payment_sheet.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  String _selectedProvider = 'All';

  @override
  Widget build(BuildContext context) {
    final momoTxs = ref.watch(mobileMoneyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = momoTxs.where((tx) {
      if (_selectedProvider == 'MTN') return tx.provider == 'mtn_momo';
      if (_selectedProvider == 'Airtel') return tx.provider == 'airtel_money';
      return true;
    }).toList();

    final totalCollected = momoTxs.where((tx) => tx.status == 'successful').fold<double>(0, (sum, tx) => sum + tx.amount);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mobile Money & Collections'),
      ),
      body: Column(
        children: [
          // Total Collected Banner
          Container(
            margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF854D0E), Color(0xFFCA8A04)],
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
                    const Text('Total Mobile Money Received', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(totalCollected),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => const ReceivePaymentSheet(amount: 50000),
                    );
                  },
                  icon: const Icon(Icons.send_to_mobile_rounded, size: 16),
                  label: const Text('Collect', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ],
            ),
          ),

          // Provider Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: ['All', 'MTN', 'Airtel'].map((p) {
                final isSelected = _selectedProvider == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(p, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600)),
                    selected: isSelected,
                    selectedColor: AppColors.primaryForest,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? AppColors.darkTextMain : AppColors.textMain)),
                    onSelected: (_) => setState(() => _selectedProvider = p),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 4),

          // Transactions List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          momoTxs.isEmpty ? 'No mobile money collections yet' : 'No transactions matching filter',
                          style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final tx = filtered[index];
                      final isMtn = tx.provider == 'mtn_momo';
                      final isSuccess = tx.status == 'successful';
                      final date = DateTime.fromMillisecondsSinceEpoch(tx.createdAt);
                      final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} · ${date.day}/${date.month}';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isMtn ? AppColors.mtnYellow : AppColors.airtelRed,
                            child: Icon(
                              Icons.phone_android_rounded,
                              color: isMtn ? Colors.black : Colors.white,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            '${isMtn ? 'MTN MoMo' : 'Airtel Money'} — +${PhoneFormatter.normalize(tx.phone)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(
                            'Ref: ${tx.externalReference.substring(0, 8)} · $timeStr',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(tx.amount),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.primaryForest),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSuccess ? Colors.green.shade50 : Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tx.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isSuccess ? AppColors.success : AppColors.creditAmber,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
