import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/app_update_service.dart';
import '../../../core/database/app_database.dart';
import '../../branches/presentation/branches_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Receipt preferences state
  String _receiptFooter = 'Thank you for your business! Webale nnyo.';
  String _printerPaperSize = '80mm (Standard)';
  bool _printVatBreakdown = true;

  void _showEditBusinessProfileDialog() {
    final session = ref.read(authProvider);
    final bizNameCtrl =
        TextEditingController(text: session?.businessName ?? '');
    final ownerNameCtrl = TextEditingController(text: session?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: session?.phone ?? '');
    final tinCtrl = TextEditingController(text: session?.tin ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.storefront_rounded, color: AppColors.primaryForest),
            SizedBox(width: 10),
            Text('Edit Business Profile',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bizNameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Business / Shop Name *',
                    prefixIcon: Icon(Icons.store)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ownerNameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Owner / Manager Full Name *',
                    prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Contact Phone Number',
                    prefixIcon: Icon(Icons.phone)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tinCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'URA Tax TIN',
                    prefixIcon: Icon(Icons.account_balance)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (bizNameCtrl.text.trim().isEmpty) return;
              ref.read(authProvider.notifier).updateProfile(
                    businessName: bizNameCtrl.text.trim(),
                    fullName: ownerNameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    tin: tinCtrl.text.trim().isNotEmpty
                        ? tinCtrl.text.trim()
                        : null,
                  );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('✅ Business profile updated successfully!')),
              );
            },
            child: const Text('Save Profile',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog() {
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    String? pinError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: AppColors.primaryForest),
              SizedBox(width: 10),
              Text('Change Security PIN',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pinError != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(pinError!,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 11)),
                ),
              ],
              TextField(
                controller: currentPinController,
                obscureText: true,
                maxLength: 4,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current 4-Digit PIN',
                  counterText: '',
                  prefixIcon: Icon(Icons.lock_outline, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPinController,
                obscureText: true,
                maxLength: 4,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'New 4-Digit PIN',
                  counterText: '',
                  prefixIcon: Icon(Icons.pin_rounded, size: 18),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final currentPin = currentPinController.text.trim();
                final newPin = newPinController.text.trim();

                final session = ref.read(authProvider);
                if (session == null || currentPin != session.userPin) {
                  setDialogState(() => pinError = 'Current PIN is incorrect');
                  return;
                }

                if (newPin.length != 4) {
                  setDialogState(
                      () => pinError = 'New PIN must be exactly 4 digits');
                  return;
                }

                ref.read(authProvider.notifier).updatePin(newPin);

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Security PIN updated successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Save PIN'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReceiptSettingsDialog() {
    final footerCtrl = TextEditingController(text: _receiptFooter);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: AppColors.primaryForest),
              SizedBox(width: 10),
              Text('Thermal Receipt Settings',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: footerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Receipt Footer Note / Greeting',
                  hintText: 'e.g. Webale Nnyo! No returns after 3 days.',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _printerPaperSize,
                decoration: const InputDecoration(
                    labelText: 'Thermal Paper Roll Width'),
                items: const [
                  DropdownMenuItem(
                      value: '58mm (Compact Portable)',
                      child: Text('58mm (Compact Portable)')),
                  DropdownMenuItem(
                      value: '80mm (Standard Countertop)',
                      child: Text('80mm (Standard Countertop)')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => _printerPaperSize = val);
                },
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Print 18% VAT Breakdown',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Show URA EFRIS tax details on receipt',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                value: _printVatBreakdown,
                activeThumbColor: AppColors.primaryForest,
                onChanged: (val) =>
                    setModalState(() => _printVatBreakdown = val),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _receiptFooter = footerCtrl.text.trim();
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('✅ Thermal receipt settings saved!')),
                );
              },
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }

  void _exportFullDatabaseBackup() async {
    final db = ref.read(databaseProvider);
    final products = await db.getProducts();
    final sales = await db.getSales();
    final debtors = await db.getDebtors();
    final expenses = await db.getExpenses();

    final backup = {
      'app': 'DUUKA SME OS',
      'version': '2.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'productsCount': products.length,
      'salesCount': sales.length,
      'debtorsCount': debtors.length,
      'expensesCount': expenses.length,
      'products': products.map((p) => p.toJson()).toList(),
      'sales': sales.map((s) => s.toJson()).toList(),
      'debtors': debtors.map((d) => d.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);
    Share.share(jsonStr,
        subject: 'DUUKA_Backup_${DateTime.now().millisecondsSinceEpoch}.json');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider);
    final lang = ref.watch(languageProvider);
    final syncEngine = ref.watch(syncEngineProvider);
    final themeMode = ref.watch(themeModeProvider);
    final branches = ref.watch(branchesProvider);
    final selectedBranchId = ref.watch(selectedBranchIdProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentBranch = branches.firstWhere((b) => b.id == selectedBranchId,
        orElse: () => branches.first);

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.tr('settings_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Business Profile Card
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryForest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.storefront_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session?.businessName ??
                                  'Kisekka Agro & Hardware',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            Text(
                              '${session?.fullName ?? "Owner"} • ${session?.phone ?? "0772123456"}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded,
                            color: AppColors.primaryForest),
                        tooltip: 'Edit Business Profile',
                        onPressed: _showEditBusinessProfileDialog,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildSettingRow(
                      ref.tr('default_currency'), session?.currency ?? 'UGX'),
                  _buildSettingRow(ref.tr('subscription_tier'),
                      (session?.subscriptionTier ?? 'PRO').toUpperCase()),
                  _buildSettingRow(
                    ref.tr('efris_integration'),
                    session?.isEfrisEnrolled == true
                        ? 'Active (TIN: ${session?.tin ?? '1004928374'})'
                        : 'Ready (TIN: 1004928374)',
                    isBadge: true,
                    badgeColor: AppColors.success,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Multi-Branch & Store Location Selector
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.store_rounded,
                    color: Color(0xFF0284C7), size: 22),
              ),
              title: const Text('Active Store Branch',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                '${currentBranch.name} (${currentBranch.location})',
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0284C7),
                    fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const BranchesScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Thermal Receipt & Printing Setup
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.print_rounded,
                    color: Color(0xFF059669), size: 22),
              ),
              title: const Text('Receipt & Thermal Printer Setup',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                '$_printerPaperSize • Bluetooth/USB ready',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _showReceiptSettingsDialog,
            ),
          ),
          const SizedBox(height: 14),

          // COLOR MODES & APPEARANCE
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.palette_rounded,
                          color: AppColors.primaryForest, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Color Mode & Appearance',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose your preferred theme style for daylight or night shop hours.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildThemeOption(
                          title: 'Light Mode',
                          icon: Icons.light_mode_rounded,
                          isSelected: themeMode == ThemeMode.light,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.light),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildThemeOption(
                          title: 'Dark Mode',
                          icon: Icons.dark_mode_rounded,
                          isSelected: themeMode == ThemeMode.dark,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.dark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildThemeOption(
                          title: 'System',
                          icon: Icons.brightness_auto_rounded,
                          isSelected: themeMode == ThemeMode.system,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.system),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.palette_rounded,
                          size: 17, color: AppColors.accentGold),
                      SizedBox(width: 8),
                      Text(
                        'Favorite App & Brand Color',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select your signature business theme color across the app.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, _) {
                      final currentBrandColor =
                          ref.watch(customThemeColorProvider);
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: CustomerFavoriteColors.presets.map((preset) {
                          final isSelected =
                              currentBrandColor.value == preset.color.value;
                          return InkWell(
                            onTap: () => ref
                                .read(customThemeColorProvider.notifier)
                                .setColor(preset.color),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? preset.color.withValues(alpha: 0.15)
                                    : (isDark
                                        ? AppColors.darkCard
                                        : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? preset.color
                                      : (isDark
                                          ? AppColors.darkBorder
                                          : const Color(0xFFE2E8F0)),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: preset.color,
                                      shape: BoxShape.circle,
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check,
                                            size: 11, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    preset.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? preset.color
                                          : (isDark
                                              ? AppColors.darkTextMain
                                              : const Color(0xFF334155)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // SECURITY & ACCESS CONTROL
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.security_rounded,
                          color: AppColors.primaryForest, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Security & Staff Access Control',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSettingRow(
                    'Auth Lock Status',
                    '🔒 PIN Protected',
                    isBadge: true,
                    badgeColor: AppColors.success,
                  ),
                  _buildSettingRow(
                      'Active Phone', session?.phone ?? '0772123456'),
                  _buildSettingRow(
                      'Staff Role', (session?.role ?? 'Owner').toUpperCase()),
                  _buildSettingRow(
                      'Device ID', session?.deviceId ?? 'device-sme-001'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showChangePinDialog,
                      icon: const Icon(Icons.pin_rounded, size: 16),
                      label: const Text('Change 4-Digit Security PIN'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryForest,
                        side: const BorderSide(color: AppColors.primaryForest),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Offline Sync Manager Card
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ref.tr('offline_sync_engine'),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (syncEngine?.state.pendingCount ?? 0) > 0
                              ? AppColors.creditAmber
                              : AppColors.success,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (syncEngine?.state.pendingCount ?? 0) > 0
                              ? '${syncEngine?.state.pendingCount} ${ref.tr('pending')}'
                              : ref.tr('all_synced'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ref.tr('offline_sync_desc'),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        syncEngine?.syncNow();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Syncing with Convex Cloud backend...')),
                        );
                      },
                      icon: const Icon(Icons.sync, size: 18),
                      label: Text(ref.tr('sync_now')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryForest,
                        side: const BorderSide(color: AppColors.primaryForest),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Database & Backup Manager Card
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.save_rounded,
                          color: Color(0xFF0F766E), size: 20),
                      SizedBox(width: 10),
                      Text('Database Backup & Export',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Export complete store inventory, transactions, credit ledger, and production data.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _exportFullDatabaseBackup,
                      icon: const Icon(Icons.file_download_rounded, size: 18),
                      label: const Text('Export JSON Database Backup'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F766E),
                        side: const BorderSide(color: Color(0xFF0F766E)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Language Selector
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: ListTile(
              leading:
                  const Icon(Icons.language, color: AppColors.primaryForest),
              title: Text(ref.tr('app_language'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                lang == 'lg'
                    ? '🇺🇬 Oluganda (Main)'
                    : lang == 'rn'
                        ? '🇺🇬 Orunyankore'
                        : '🇬🇧 English (Default)',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryForest,
                    fontWeight: FontWeight.bold),
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.chevron_right),
                onSelected: (val) =>
                    ref.read(languageProvider.notifier).setLanguage(val),
                itemBuilder: (ctx) => const [
                  PopupMenuItem(
                      value: 'en', child: Text('🇬🇧 English (Default)')),
                  PopupMenuItem(
                      value: 'lg', child: Text('🇺🇬 Oluganda (Main)')),
                  PopupMenuItem(value: 'rn', child: Text('🇺🇬 Orunyankore')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // WhatsApp Support
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: ListTile(
              leading: const Icon(Icons.help_outline, color: Color(0xFF25D366)),
              title: Text(ref.tr('whatsapp_support'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(ref.tr('whatsapp_desc'),
                  style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Connecting to DUUKA WhatsApp Support (+256700000000)...')),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Software & Remote Updates Card
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Remote App Updates',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryForest.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'v2.0.0 (Latest)',
                          style: TextStyle(
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.bold,
                              fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'OTA and backend version manager. Checks for latest security patches and SME features.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Checking for remote updates...')),
                        );
                        final convex = ref.read(convexClientProvider);
                        final updateInfo =
                            await AppUpdateService.checkForUpdate(convex);
                        if (!context.mounted) return;
                        if (updateInfo != null) {
                          AppUpdateService.showUpdatePrompt(
                              context, updateInfo);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('✅ DUUKA is up to date (Version 2.0.0)'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.system_update_rounded, size: 18),
                      label: const Text('Check for Updates Now'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryForest,
                        side: const BorderSide(color: AppColors.primaryForest),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Lock & Sign out button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
              icon: const Icon(Icons.lock_rounded,
                  color: AppColors.danger, size: 18),
              label: Text(
                lang == 'lg'
                    ? 'Siba / Vaamu (Lock & Sign Out)'
                    : 'Lock & Sign Out of Business',
                style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w800,
                    fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                side:
                    BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryForest.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryForest : AppColors.borderLight,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 20,
                color:
                    isSelected ? AppColors.primaryForest : AppColors.textMuted),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color:
                    isSelected ? AppColors.primaryForest : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(String label, String value,
      {bool isBadge = false, Color? badgeColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          if (isBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.primaryForest)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: TextStyle(
                    color: badgeColor ?? AppColors.primaryForest,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            )
          else
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
