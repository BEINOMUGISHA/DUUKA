import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../network/convex_client.dart';
import '../theme/app_theme.dart';

class AppUpdateInfo {
  final String version;
  final int buildNumber;
  final String minSupportedVersion;
  final String releaseNotes;
  final String downloadUrl;
  final String? apkDirectUrl;
  final String? playStoreUrl;
  final bool isMandatory;

  AppUpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.minSupportedVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    this.apkDirectUrl,
    this.playStoreUrl,
    required this.isMandatory,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) => AppUpdateInfo(
        version: json['version'] as String? ?? '1.0.0',
        buildNumber: (json['buildNumber'] as num?)?.toInt() ?? 1,
        minSupportedVersion: json['minSupportedVersion'] as String? ?? '1.0.0',
        releaseNotes: json['releaseNotes'] as String? ?? 'Bug fixes and performance improvements.',
        downloadUrl: json['downloadUrl'] as String? ?? 'https://github.com/BEINOMUGISHA/DUUKA/releases',
        apkDirectUrl: json['apkDirectUrl'] as String?,
        playStoreUrl: json['playStoreUrl'] as String?,
        isMandatory: json['isMandatory'] as bool? ?? false,
      );
}

class AppUpdateService {
  static const String currentAppVersion = '1.0.0';
  static const int currentBuildNumber = 1;

  /// Quick connectivity probe — tries DNS lookup to check if online.
  static Future<bool> _isOnline() async {
    try {
      final result = await InternetAddress.lookup('convex.cloud')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Check remote version from backend.
  /// Returns null when:
  ///   - device is offline (safe — never blocks mandatory update when unreachable)
  ///   - backend query fails
  ///   - app is already on latest version
  static Future<AppUpdateInfo?> checkForUpdate(ConvexClient client) async {
    // Do not enforce mandatory update when offline — degrade gracefully
    final online = await _isOnline();
    if (!online) return null;

    try {
      final res = await client.query('system:getLatestAppVersion', {});
      if (res != null) {
        final info = AppUpdateInfo.fromJson(Map<String, dynamic>.from(res as Map));
        if (_isNewerVersion(info.version, currentAppVersion)) {
          return info;
        }
      }
    } catch (_) {}
    return null;
  }

  static bool _isNewerVersion(String remote, String current) {
    try {
      final rParts = remote.split('.').map(int.parse).toList();
      final cParts = current.split('.').map(int.parse).toList();
      for (int i = 0; i < rParts.length && i < cParts.length; i++) {
        if (rParts[i] > cParts[i]) return true;
        if (rParts[i] < cParts[i]) return false;
      }
      return rParts.length > cParts.length;
    } catch (_) {
      return remote != current;
    }
  }

  /// Launch update download URL
  static Future<void> launchUpdateUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Show In-App Update Dialog / Bottom Sheet
  static void showUpdatePrompt(BuildContext context, AppUpdateInfo info) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isDismissible: !info.isMandatory,
      enableDrag: !info.isMandatory,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PopScope(
        canPop: !info.isMandatory,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryForest.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.system_update_rounded, color: AppColors.primaryForest, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.isMandatory ? 'Mandatory Update Required ⚠️' : 'New Update Available! 🚀',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        Text(
                          'Version ${info.version} is now available (Current: $currentAppVersion)',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('What\'s New in this update:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  info.releaseNotes,
                  style: const TextStyle(fontSize: 12, height: 1.4),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (!info.isMandatory)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Later'),
                      ),
                    ),
                  if (!info.isMandatory) const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        launchUpdateUrl(info.apkDirectUrl ?? info.downloadUrl);
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Update Now', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
