import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/phone_formatter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/database/app_database.dart';

class SmsScreen extends ConsumerStatefulWidget {
  const SmsScreen({super.key});

  @override
  ConsumerState<SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends ConsumerState<SmsScreen> {
  void _showComposeSmsDialog() {
    final phoneCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String selectedTemplate = 'Custom';
    final customers = ref.read(customersProvider);
    final session = ref.read(authProvider);
    final bName = session?.businessName ?? 'DUUKA';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
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
                    const Text('Compose SMS',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900)),
                    IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                // Template dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedTemplate,
                  decoration:
                      const InputDecoration(labelText: 'Template Preset'),
                  items: const [
                    DropdownMenuItem(
                        value: 'Custom', child: Text('Custom Message')),
                    DropdownMenuItem(
                        value: 'Payment Received',
                        child: Text('Payment Received Template')),
                    DropdownMenuItem(
                        value: 'Debt Reminder',
                        child: Text('Debt Reminder Template')),
                    DropdownMenuItem(
                        value: 'Welcome Customer',
                        child: Text('Welcome Customer Template')),
                  ],
                  onChanged: (val) {
                    setModalState(() {
                      selectedTemplate = val!;
                      if (val == 'Payment Received') {
                        messageCtrl.text =
                            'Thank you for your payment to $bName. We appreciate your business!';
                      } else if (val == 'Debt Reminder') {
                        messageCtrl.text =
                            'Friendly reminder from $bName regarding your outstanding balance. Thank you!';
                      } else if (val == 'Welcome Customer') {
                        messageCtrl.text =
                            'Welcome to $bName! We look forward to serving you with quality goods.';
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Customer quick pick
                if (customers.isNotEmpty)
                  DropdownButtonFormField<LocalCustomerData>(
                    decoration: const InputDecoration(
                        labelText: 'Or Select Existing Customer'),
                    items: customers
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.name} (${c.phone})',
                                style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (c) {
                      if (c != null) {
                        setModalState(() {
                          phoneCtrl.text =
                              PhoneFormatter.formatDisplay(c.phone);
                        });
                      }
                    },
                  ),
                const SizedBox(height: 10),

                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Phone *',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: messageCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'SMS Content *',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final rawPhone = phoneCtrl.text.trim();
                      final msg = messageCtrl.text.trim();

                      if (rawPhone.isEmpty || msg.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please enter phone and message')),
                        );
                        return;
                      }

                      final normalized = PhoneFormatter.normalize(rawPhone);
                      final smsId =
                          'sms_${DateTime.now().millisecondsSinceEpoch}';
                      final sms = LocalSmsData(
                        id: smsId,
                        businessId: session?.businessId ?? 'biz_default',
                        phone: normalized,
                        message: msg,
                        type:
                            selectedTemplate.toLowerCase().replaceAll(' ', '_'),
                        status: 'sent',
                        createdAt: DateTime.now().millisecondsSinceEpoch,
                      );
                      ref.read(smsProvider.notifier).logSms(sms);
                      Navigator.pop(ctx);

                      // Try sending via Convex backend
                      bool backendSent = false;
                      try {
                        final convex = ref.read(convexClientProvider);
                        if (session != null) {
                          await convex.mutation('sms:sendCustomerSms', {
                            'businessId': session.businessId,
                            'userId': session.userId,
                            'recipientPhone': normalized,
                            'message': msg,
                            'template': selectedTemplate
                                .toLowerCase()
                                .replaceAll(' ', '_'),
                            'idempotencyKey': smsId,
                          });
                          backendSent = true;
                        }
                      } catch (_) {}

                      if (!backendSent) {
                        Share.share(msg, subject: 'SMS from $bName');
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(backendSent
                                ? '✅ SMS dispatched via gateway (1 Credit used)'
                                : 'SMS prepared & shared via SMS/WhatsApp app'),
                            backgroundColor:
                                backendSent ? AppColors.success : null,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Send SMS (1 Credit)',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final smsList = ref.watch(smsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('SMS & Reminders'),
      ),
      body: Column(
        children: [
          // SMS Credits Card
          Container(
            margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SMS Credits Balance',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('20 Credits',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3A8A),
                  ),
                  onPressed: _showComposeSmsDialog,
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text('Compose',
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('SMS Dispatch Log',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ),
          ),

          // SMS Log
          Expanded(
            child: smsList.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sms_outlined,
                            size: 48, color: AppColors.textMuted),
                        SizedBox(height: 8),
                        Text('No SMS messages logged yet',
                            style: TextStyle(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                    itemCount: smsList.length,
                    itemBuilder: (ctx, index) {
                      final sms = smsList[index];
                      final date =
                          DateTime.fromMillisecondsSinceEpoch(sms.createdAt);
                      final timeStr =
                          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} · ${date.day}/${date.month}';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '+${PhoneFormatter.normalize(sms.phone)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('DELIVERED',
                                        style: TextStyle(
                                            color: AppColors.success,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(sms.message,
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 6),
                              Text(timeStr,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted)),
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
