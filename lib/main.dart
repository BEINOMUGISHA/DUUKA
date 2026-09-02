import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_providers.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/pos/presentation/pos_quick_sale_screen.dart';
import 'features/inventory/presentation/inventory_screen.dart';
import 'features/customers/presentation/customers_screen.dart';
import 'features/settings/presentation/more_hub_screen.dart';

import 'core/services/app_update_service.dart';

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
    final customColor = ref.watch(customThemeColorProvider);

    return MaterialApp(
      title: 'DUKA - Uganda SME OS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(customColor, isDark: false),
      darkTheme: AppTheme.buildTheme(customColor, isDark: true),
      themeMode: themeMode,
      home: session != null ? const MainNavigationShell() : const AuthScreen(),
    );
  }
}

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _currentIndex = 0;
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    // Non-blocking background remote update check after launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () async {
        if (!mounted) return;
        final convex = ref.read(convexClientProvider);
        final updateInfo = await AppUpdateService.checkForUpdate(convex);
        if (updateInfo != null && mounted) {
          AppUpdateService.showUpdatePrompt(context, updateInfo);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = List<Widget>.generate(5, _buildScreen);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
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
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(index: 0, icon: Icons.home_rounded, label: 'Home'),
              _buildNavItem(
                  index: 1, icon: Icons.point_of_sale_rounded, label: 'Sales'),
              _buildNavItem(
                  index: 2, icon: Icons.inventory_2_rounded, label: 'Stock'),
              _buildNavItem(
                  index: 3, icon: Icons.people_alt_rounded, label: 'Customers'),
              _buildNavItem(
                  index: 4, icon: Icons.grid_view_rounded, label: 'More'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(int index) {
    if (!_visitedTabs.contains(index)) {
      return const SizedBox.shrink();
    }

    switch (index) {
      case 0:
        return DashboardScreen(
          onNavigateTab: (index) => setState(() {
            _visitedTabs.add(index);
            _currentIndex = index;
          }),
        );
      case 1:
        return const PosQuickSaleScreen();
      case 2:
        return const InventoryScreen();
      case 3:
        return const CustomersScreen();
      case 4:
        return const MoreHubScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor =
        isDark ? AppColors.emeraldNeon : AppColors.primaryForest;
    final inactiveColor =
        isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8);

    return InkWell(
      onTap: () => setState(() {
        _visitedTabs.add(index);
        _currentIndex = index;
      }),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
