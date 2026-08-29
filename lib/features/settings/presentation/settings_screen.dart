import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/app_update_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _showChangePinDialog() {
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    String? pinError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: AppColors.primaryForest),
              SizedBox(width: 10),
              Text('Change Security PIN', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
                  child: Text(pinError!, style: const TextStyle(color: AppColors.danger, fontSize: 11)),
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
                  setDialogState(() => pinError = 'New PIN must be exactly 4 digits');
                  return;
                }

                // Update session PIN
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

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider);
    final lang = ref.watch(languageProvider);
    final syncEngine = ref.watch(syncEngineProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.tr('settings_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Business Profile Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.primaryForest,
                        radius: 24,
                        child: Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session?.businessName ?? ref.tr('app_name'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '${ref.tr('role_owner')}: ${session?.fullName ?? "Owner"} • ${session?.phone}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildSettingRow(ref.tr('default_currency'), session?.currency ?? 'UGX'),
                  _buildSettingRow(ref.tr('subscription_tier'), (session?.subscriptionTier ?? 'PRO').toUpperCase()),
                  _buildSettingRow(
                    ref.tr('efris_integration'),
                    session?.isEfrisEnrolled == true ? 'Active (TIN: 1004928374)' : 'Not Configured',
                    isBadge: true,
                    badgeColor: session?.isEfrisEnrolled == true ? AppColors.success : AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // --- COLOR MODES & APPEARANCE ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.palette_rounded, color: AppColors.primaryForest, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Color Mode & Appearance',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                          onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildThemeOption(
                          title: 'Dark Mode',
                          icon: Icons.dark_mode_rounded,
                          isSelected: themeMode == ThemeMode.dark,
                          onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildThemeOption(
                          title: 'System',
                          icon: Icons.brightness_auto_rounded,
                          isSelected: themeMode == ThemeMode.system,
                          onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.palette_rounded, size: 17, color: AppColors.accentGold),
                      SizedBox(width: 8),
                      Text(
                        'Favorite App & Brand Color',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                      final currentBrandColor = ref.watch(customThemeColorProvider);
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: CustomerFavoriteColors.presets.map((preset) {
                          final isSelected = currentBrandColor.value == preset.color.value;
                          return InkWell(
                            onTap: () => ref.read(customThemeColorProvider.notifier).setColor(preset.color),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected ? preset.color.withValues(alpha: 0.15) : (isDark ? AppColors.darkCard : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? preset.color : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
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
                                    child: isSelected ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    preset.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? preset.color : (isDark ? AppColors.darkTextMain : const Color(0xFF334155)),
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

          // --- SECURITY & AUTHENTICATION (PARAMOUNT) ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.security_rounded, color: AppColors.primaryForest, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Security & Access Control',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                  _buildSettingRow('Active Phone', session?.phone ?? '0772123456'),
                  _buildSettingRow('Device ID', session?.deviceId ?? 'device-sme-001'),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (syncEngine?.state.pendingCount ?? 0) > 0 ? AppColors.creditAmber : AppColors.success,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (syncEngine?.state.pendingCount ?? 0) > 0
                              ? '${syncEngine?.state.pendingCount} ${ref.tr('pending')}'
                              : ref.tr('all_synced'),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ref.tr('offline_sync_desc'),
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        syncEngine?.syncNow();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Syncing with Convex Cloud backend...')),
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

          // Language Selector
          Card(
            child: ListTile(
              leading: const Icon(Icons.language, color: AppColors.primaryForest),
              title: Text(ref.tr('app_language'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                lang == 'lg' ? '🇺🇬 Oluganda (Main)' : lang == 'rn' ? '🇺🇬 Orunyankore' : '🇬🇧 English (Default)',
                style: const TextStyle(fontSize: 12, color: AppColors.primaryForest, fontWeight: FontWeight.bold),
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.chevron_right),
                onSelected: (val) => ref.read(languageProvider.notifier).setLanguage(val),
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'en', child: Text('🇬🇧 English (Default)')),
                  PopupMenuItem(value: 'lg', child: Text('🇺🇬 Oluganda (Main)')),
                  PopupMenuItem(value: 'rn', child: Text('🇺🇬 Orunyankore')),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // WhatsApp Support
          Card(
            child: ListTile(
              leading: const Icon(Icons.help_outline, color: Color(0xFF25D366)),
              title: Text(ref.tr('whatsapp_support'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(ref.tr('whatsapp_desc'), style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connecting to DUKA WhatsApp Support (+256700000000)...')),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Software & Remote Updates Card
          Card(
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
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryForest.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'v1.0.0 (Latest)',
                          style: TextStyle(color: AppColors.primaryForest, fontWeight: FontWeight.bold, fontSize: 11),
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
                          const SnackBar(content: Text('Checking for remote updates...')),
                        );
                        final convex = ref.read(convexClientProvider);
                        final updateInfo = await AppUpdateService.checkForUpdate(convex);
                        if (!context.mounted) return;
                        if (updateInfo != null) {
                          AppUpdateService.showUpdatePrompt(context, updateInfo);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ DUKA is up to date (Version 1.0.0)'),
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
              icon: const Icon(Icons.lock_rounded, color: AppColors.danger, size: 18),
              label: Text(
                lang == 'lg' ? 'Siba / Vaamu (Lock & Sign Out)' : 'Lock & Sign Out of Business',
                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          color: isSelected ? AppColors.primaryForest.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryForest : AppColors.borderLight,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppColors.primaryForest : AppColors.textMuted),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primaryForest : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(String label, String value, {bool isBadge = false, Color? badgeColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          if (isBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.primaryForest).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: TextStyle(color: badgeColor ?? AppColors.primaryForest, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            )
          else
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
