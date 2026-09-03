import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Helper utility for generating sector-specific visual assets, fallback avatars,
/// warm placeholders, and category icons across all 14 DUKA business sectors.
class SectorImageGenerator {
  /// Map of sector IDs to iconic Material Symbols / Icons
  static const Map<String, IconData> sectorIcons = {
    'wholesale_retail': Icons.shopping_bag_rounded,
    'food_hospitality': Icons.restaurant_rounded,
    'agriculture_agribusiness': Icons.agriculture_rounded,
    'manufacturing': Icons.precision_manufacturing_rounded,
    'automotive': Icons.directions_car_rounded,
    'personal_services': Icons.content_cut_rounded,
    'construction_building': Icons.construction_rounded,
    'transport_logistics': Icons.local_shipping_rounded,
    'ict_digital': Icons.devices_other_rounded,
    'real_estate': Icons.home_work_rounded,
    'financial_services': Icons.account_balance_wallet_rounded,
    'health': Icons.local_hospital_rounded,
    'education': Icons.school_rounded,
    'arts_entertainment': Icons.camera_alt_rounded,
  };

  /// Map of sector IDs to warm Uganda-inspired color accents
  static const Map<String, Color> sectorColors = {
    'wholesale_retail': Color(0xFF1B4332),
    'food_hospitality': Color(0xFFD4A017),
    'agriculture_agribusiness': Color(0xFF2D6A4F),
    'manufacturing': Color(0xFF475569),
    'automotive': Color(0xFFDC2626),
    'personal_services': Color(0xFFDB2777),
    'construction_building': Color(0xFFD97706),
    'transport_logistics': Color(0xFF2563EB),
    'ict_digital': Color(0xFF0284C7),
    'real_estate': Color(0xFF0D9488),
    'financial_services': Color(0xFF059669),
    'health': Color(0xFFE11D48),
    'education': Color(0xFF4338CA),
    'arts_entertainment': Color(0xFF7C3AED),
  };

  /// Returns the corresponding IconData for a sector ID
  static IconData getIconForSector(String? sectorId) {
    if (sectorId == null) return Icons.storefront_rounded;
    return sectorIcons[sectorId] ?? Icons.storefront_rounded;
  }

  /// Returns the primary color accent for a sector ID
  static Color getColorForSector(String? sectorId) {
    if (sectorId == null) return AppColors.forestGreen;
    return sectorColors[sectorId] ?? AppColors.forestGreen;
  }

  /// Builds a warm, branded placeholder card for product thumbnails or sector cards
  static Widget buildSectorPlaceholder({
    required String title,
    String? sectorId,
    double width = 80,
    double height = 80,
    double iconSize = 32,
    BorderRadius? borderRadius,
  }) {
    final accentColor = getColorForSector(sectorId);
    final icon = getIconForSector(sectorId);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.18), width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: accentColor,
            ),
            if (height >= 90) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
