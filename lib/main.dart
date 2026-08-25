import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_providers.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/pos/presentation/pos_quick_sale_screen.dart';
import 'features/inventory/presentation/inventory_screen.dart';
import 'features/reports/presentation/reports_screen.dart';
import 'features/settings/presentation/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DukaApp()));
}

class DukaApp extends ConsumerWidget {
  const DukaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'DUKA - Uganda SME Finance & Stock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // Authentication is Paramount: Strict gate to AuthScreen if not authenticated
      home: session != null ? const MainNavigationShell() : const AuthScreen(),
    );
  }
}

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> screens = [
      DashboardScreen(onNavigateTab: (index) => setState(() => _currentIndex = index)),
      const ReportsScreen(),
      const PosQuickSaleScreen(),
      const InventoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Home
              _buildNavIcon(
                index: 0,
                icon: Icons.home_rounded,
                selectedColor: isDark ? AppColors.emeraldNeon : const Color(0xFF0F766E),
              ),

              // 2. Chart / Reports
              _buildNavIcon(
                index: 1,
                icon: Icons.bar_chart_rounded,
                selectedColor: isDark ? AppColors.emeraldNeon : const Color(0xFF0F766E),
              ),

              // 3. Center Elevated Plus (POS / New Sale)
              InkWell(
                onTap: () => setState(() => _currentIndex = 2),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryForest,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryForest.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),

              // 4. Inventory / Boxes
              _buildNavIcon(
                index: 3,
                icon: Icons.inventory_2_outlined,
                selectedColor: isDark ? AppColors.emeraldNeon : const Color(0xFF0F766E),
              ),

              // 5. User / Settings
              _buildNavIcon(
                index: 4,
                icon: Icons.person_outline_rounded,
                selectedColor: isDark ? AppColors.emeraldNeon : const Color(0xFF0F766E),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon({
    required int index,
    required IconData icon,
    required Color selectedColor,
  }) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      onPressed: () => setState(() => _currentIndex = index),
      icon: Icon(
        icon,
        size: 22,
        color: isSelected ? selectedColor : (isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8)),
      ),
    );
  }
}
