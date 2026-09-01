import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/uganda_presets.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/phone_formatter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/database/app_database.dart';

enum PaymentState { initial, requesting, waitingForPin, successful, failed }

class ReceivePaymentSheet extends ConsumerStatefulWidget {
  final double amount;
  final String? initialPhone;
  final String? customerName;
  final String? saleId;
  final Function(String reference, String method)? onPaymentSuccess;

  const ReceivePaymentSheet({
    super.key,
    required this.amount,
    this.initialPhone,
    this.customerName,
    this.saleId,
    this.onPaymentSuccess,
  });

  @override
  ConsumerState<ReceivePaymentSheet> createState() =>
      _ReceivePaymentSheetState();
}

class _ReceivePaymentSheetState extends ConsumerState<ReceivePaymentSheet> {
  late TextEditingController _phoneController;
  late TextEditingController _amountController;
  String _selectedProvider = UgandaPresets.paymentMtnMomo;
  PaymentState _state = PaymentState.initial;
  String _statusMessage = '';
  String? _transactionReference;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _amountController =
        TextEditingController(text: widget.amount.toInt().toString());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _initiatePayment() async {
    final rawPhone = _phoneController.text.trim();
    final amt = double.tryParse(_amountController.text.trim()) ?? widget.amount;

    if (rawPhone.isEmpty || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid phone number and amount')),
      );
      return;
    }

    final normalizedPhone = PhoneFormatter.normalize(rawPhone);
    final refUuid = const Uuid().v4();

    setState(() {
      _state = PaymentState.requesting;
      _statusMessage =
          'Contacting ${_selectedProvider == UgandaPresets.paymentMtnMomo ? 'MTN' : 'Airtel'} gateway...';
    });

    final convex = ref.read(convexClientProvider);
    final session = ref.read(authProvider);

    try {
      final res = await convex.mutation('payments:initiateMobileMoneyPayment', {
        'businessId': session?.businessId ?? 'biz_default',
        'userId': session?.userId ?? 'usr_default',
        'provider': _selectedProvider == UgandaPresets.paymentMtnMomo
            ? 'mtn_momo'
            : 'airtel_money',
        'phone': normalizedPhone,
        'amount': amt,
        'externalReference': refUuid,
        'saleId': widget.saleId,
      });

      _transactionReference = res['transactionId'] ?? refUuid;

      setState(() {
        _state = PaymentState.waitingForPin;
        _statusMessage =
            'Prompt sent to +$normalizedPhone.\nEnter PIN on your mobile phone to approve.';
      });

      // Poll status for sandbox/live confirmation
      int attempts = 0;
      _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        attempts++;
        if (attempts > 15) {
          timer.cancel();
          if (mounted && _state == PaymentState.waitingForPin) {
            setState(() {
              _state = PaymentState.failed;
              _statusMessage = 'Transaction timed out. Please try again.';
            });
          }
          return;
        }

        try {
          final statusRes =
              await convex.mutation('payments:checkMobileMoneyStatus', {
            'businessId': session?.businessId ?? 'biz_default',
            'userId': session?.userId ?? 'usr_default',
            'transactionId': _transactionReference,
            'simulateSuccess': attempts >= 3,
          });

          if (statusRes['status'] == 'successful') {
            timer.cancel();
            if (mounted) {
              setState(() {
                _state = PaymentState.successful;
                _statusMessage =
                    'Payment confirmed! Received ${CurrencyFormatter.format(amt)}.';
              });

              // Log in local DB
              final localTx = LocalMobileMoneyTxData(
                id: 'momo_${DateTime.now().millisecondsSinceEpoch}',
                businessId: session?.businessId ?? 'biz_default',
                saleId: widget.saleId,
                provider: _selectedProvider,
                phone: normalizedPhone,
                amount: amt,
                reference: refUuid,
                externalReference: refUuid,
                status: 'successful',
                createdAt: DateTime.now().millisecondsSinceEpoch,
              );
              ref.read(mobileMoneyProvider.notifier).recordTransaction(localTx);

              if (widget.onPaymentSuccess != null) {
                widget.onPaymentSuccess!(refUuid, _selectedProvider);
              }
            }
          }
        } catch (_) {}
      });
    } catch (e) {
      setState(() {
        _state = PaymentState.failed;
        _statusMessage = 'Could not request payment: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amt = double.tryParse(_amountController.text.trim()) ?? widget.amount;
    final paymentUrl = 'https://duka.ug/pay/${widget.saleId ?? 'pay_generic'}';

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Receive Mobile Money',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Provider Selection Cards
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _state == PaymentState.waitingForPin ||
                            _state == PaymentState.requesting
                        ? null
                        : () => setState(() =>
                            _selectedProvider = UgandaPresets.paymentMtnMomo),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedProvider == UgandaPresets.paymentMtnMomo
                            ? AppColors.mtnYellow
                            : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              _selectedProvider == UgandaPresets.paymentMtnMomo
                                  ? Colors.amber.shade800
                                  : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text('MTN MoMo',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: Colors.black)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _state == PaymentState.waitingForPin ||
                            _state == PaymentState.requesting
                        ? null
                        : () => setState(() => _selectedProvider =
                            UgandaPresets.paymentAirtelMoney),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedProvider ==
                                UgandaPresets.paymentAirtelMoney
                            ? AppColors.airtelRed
                            : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedProvider ==
                                  UgandaPresets.paymentAirtelMoney
                              ? Colors.red.shade900
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Airtel Money',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: _selectedProvider ==
                                  UgandaPresets.paymentAirtelMoney
                              ? Colors.white
                              : AppColors.textMain,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              enabled: _state == PaymentState.initial ||
                  _state == PaymentState.failed,
              decoration: const InputDecoration(
                labelText: 'Amount (UGX) *',
                prefixIcon: Icon(Icons.payments_rounded),
              ),
            ),
            const SizedBox(height: 10),

            // Phone Input
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              enabled: _state == PaymentState.initial ||
                  _state == PaymentState.failed,
              decoration: InputDecoration(
                labelText: 'Customer Phone (e.g. 0772123456) *',
                prefixIcon: const Icon(Icons.phone_android_rounded),
                suffixText: PhoneFormatter.getCarrier(_phoneController.text),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Dynamic State Display
            if (_state == PaymentState.requesting ||
                _state == PaymentState.waitingForPin) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Sonar radar wave 1
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.amber.withValues(alpha: 0.2),
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat())
                            .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.6, 1.6),
                                duration: 1200.ms)
                            .fadeOut(duration: 1200.ms),

                        // Center Icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _selectedProvider ==
                                    UgandaPresets.paymentMtnMomo
                                ? AppColors.mtnYellow
                                : AppColors.airtelRed,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.phonelink_ring_rounded,
                            color: _selectedProvider ==
                                    UgandaPresets.paymentMtnMomo
                                ? Colors.black
                                : Colors.white,
                            size: 22,
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                            begin: const Offset(0.95, 0.95),
                            end: const Offset(1.05, 1.05),
                            duration: 800.ms),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF92400E)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Awaiting customer PIN entry on mobile phone...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 16),
            ] else if (_state == PaymentState.successful) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade400, width: 1.5),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 30),
                    )
                        .animate()
                        .scale(duration: 400.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 10),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.success),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 250.ms),
              const SizedBox(height: 16),
            ] else if (_state == PaymentState.failed) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.danger, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Button
            if (_state != PaymentState.successful)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _state == PaymentState.requesting ||
                          _state == PaymentState.waitingForPin
                      ? null
                      : _initiatePayment,
                  icon: const Icon(Icons.send_to_mobile_rounded),
                  label: Text(
                    'Request ${CurrencyFormatter.format(amt)} Payment',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),

            const SizedBox(height: 16),
            const Divider(),

            // DUKA QR Code / Payment Link Section
            Center(
              child: ExpansionTile(
                title: const Text('Or Show DUKA Payment QR Code',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        QrImageView(
                          data: paymentUrl,
                          version: QrVersions.auto,
                          size: 150,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 6),
                        Text(paymentUrl,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
