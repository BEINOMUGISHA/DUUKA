import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/export_service.dart';
import 'pos_quick_sale_screen.dart';

class ReceiptShareScreen extends ConsumerWidget {
  final String saleNumber;
  final String customerName;
  final String? customerPhone;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final String paymentMethod;
  final String? momoReference;
  final String? fiscalCode;
  final List<CartItem> items;

  const ReceiptShareScreen({
    super.key,
    required this.saleNumber,
    required this.customerName,
    this.customerPhone,
    required this.totalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.paymentMethod,
    this.momoReference,
    this.fiscalCode,
    required this.items,
  });

  String _generateTextReceipt(String businessName, String currency, String thankYouMsg) {
    final buffer = StringBuffer();
    buffer.writeln('==============================');
    buffer.writeln('  $businessName');
    buffer.writeln('  Official Sales Receipt');
    buffer.writeln('==============================');
    buffer.writeln('Receipt No: $saleNumber');
    buffer.writeln('Date: ${DateTime.now().toLocal().toString().substring(0, 16)}');
    buffer.writeln('Customer: $customerName');
    if (customerPhone != null && customerPhone!.isNotEmpty) {
      buffer.writeln('Phone: $customerPhone');
    }
    buffer.writeln('------------------------------');
    for (final item in items) {
      buffer.writeln('${item.product.name} x ${item.quantity}');
      buffer.writeln('  @ ${CurrencyFormatter.format(item.product.sellPrice)} = ${CurrencyFormatter.format(item.subtotal)}');
    }
    buffer.writeln('------------------------------');
    buffer.writeln('TOTAL: ${CurrencyFormatter.format(totalAmount)}');
    buffer.writeln('Paid Amount: ${CurrencyFormatter.format(paidAmount)}');
    if (dueAmount > 0) {
      buffer.writeln('Balance Due: ${CurrencyFormatter.format(dueAmount)} (Credit Sale)');
    }
    buffer.writeln('Payment Method: ${paymentMethod.toUpperCase()}');
    if (momoReference != null && momoReference!.isNotEmpty) {
      buffer.writeln('MoMo Ref: $momoReference');
    }
    if (fiscalCode != null) {
      buffer.writeln('URA EFRIS Fiscal Code: $fiscalCode');
    }
    buffer.writeln('==============================');
    buffer.writeln(thankYouMsg);
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider);
    final lang = ref.watch(languageProvider);
    final businessName = session?.businessName ?? 'DUKA SME';

    final thankYouMsg = lang == 'lg'
        ? 'Mweebale nnyo okugula gye tuli! (Thank you for your business!)'
        : 'Thank you for your business! Webale nnyo!';

    final receiptText = _generateTextReceipt(businessName, session?.currency ?? 'UGX', thankYouMsg);
    final qrData = 'https://efris.ura.go.ug/verify?inv=$saleNumber&amt=$totalAmount&fc=${fiscalCode ?? "FC-OFFLINE"}';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate aesthetic backdrop
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(ref.tr('sales_receipt')),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          children: [
            // Success animation checkmark
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.emeraldNeon.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.emeraldNeon,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.black, size: 28),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 14),
            const Text(
              'Sale Completed Successfully! 🎉',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
            ),
            const SizedBox(height: 18),

            // Modern Paper Ticket Receipt
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Business Header
                  Text(
                    businessName,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primaryForest, letterSpacing: -0.3),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kampala, Uganda • Tel: ${session?.phone ?? "+256770000000"}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),

                  // EFRIS Badge
                  if (session?.isEfrisEnrolled == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.efrisIndigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.efrisIndigo.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'URA EFRIS FISCAL RECEIPT: ${fiscalCode ?? "FC-SYNC-PENDING"}',
                        style: const TextStyle(color: AppColors.efrisIndigo, fontWeight: FontWeight.w800, fontSize: 10),
                      ),
                    ),

                  const SizedBox(height: 16),
                  _buildDashedLine(),
                  const SizedBox(height: 14),

                  // Sale Metadata
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${ref.tr('sales_receipt')}: $saleNumber', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                      Text(DateTime.now().toString().substring(0, 10), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${ref.tr('customer_name')}: $customerName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryForest.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          paymentMethod.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppColors.primaryForest),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  _buildDashedLine(),
                  const SizedBox(height: 14),

                  // Item breakdown
                  ...items.map((it) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('${it.product.name} (x${it.quantity})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                        Text(CurrencyFormatter.format(it.subtotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  )),

                  const SizedBox(height: 14),
                  _buildDashedLine(),
                  const SizedBox(height: 14),

                  // Totals
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${ref.tr('total_payable')}:', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      Text(
                        CurrencyFormatter.format(totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primaryForest),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${ref.tr('amount_paid')}:', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      Text(CurrencyFormatter.format(paidAmount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  if (dueAmount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${ref.tr('credit_balance')}:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.creditAmber)),
                        Text(CurrencyFormatter.format(dueAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.creditAmber)),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // QR Code verification
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 90.0,
                        ),
                        const SizedBox(height: 4),
                        Text(ref.tr('scan_efris_qr'), style: const TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.1, end: 0, duration: 300.ms).fadeIn(),

            const SizedBox(height: 20),

            // Print PDF & Share Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final pdfBytes = await ExportService.generateReceiptPdf(
                        businessName: businessName,
                        phone: session?.phone ?? '+256770000000',
                        saleNumber: saleNumber,
                        customerName: customerName,
                        customerPhone: customerPhone,
                        totalAmount: totalAmount,
                        paidAmount: paidAmount,
                        dueAmount: dueAmount,
                        paymentMethod: paymentMethod,
                        momoReference: momoReference,
                        fiscalCode: fiscalCode,
                        items: items.map((it) => {
                          'name': it.product.name,
                          'qty': it.quantity,
                          'total': it.subtotal,
                        }).toList(),
                      );
                      await ExportService.shareOrPrintPdf(
                        pdfBytes: pdfBytes,
                        fileName: 'Receipt_$saleNumber',
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('PDF / Print', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Share.share(receiptText, subject: 'Receipt from $businessName - $saleNumber');
                    },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text(ref.tr('share_whatsapp_sms')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.done_rounded, size: 18),
                  label: Text(ref.tr('done')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFCBD5E1)),
              ),
            );
          }),
        );
      },
    );
  }
}
