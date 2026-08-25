import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider);
    final lang = ref.watch(languageProvider);
    final syncEngine = ref.watch(syncEngineProvider);

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
                        child: Icon(Icons.store, color: Colors.white, size: 24),
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

          const SizedBox(height: 16),

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

          const SizedBox(height: 16),

          // Staff Management Tile
          Card(
            child: ListTile(
              leading: const Icon(Icons.people, color: AppColors.primaryForest),
              title: Text(ref.tr('staff_permissions'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(ref.tr('staff_desc'), style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Staff Manager: 3 active cashiers configured')),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

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

          const SizedBox(height: 10),

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
        ],
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
                color: (badgeColor ?? AppColors.primaryForest).withOpacity(0.12),
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
