import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/business_categories.dart';
import '../constants/business_presets.dart';
import '../constants/business_verticals.dart';
import 'app_providers.dart';

/// The business vertical selected for the authenticated business.
///
/// Legacy sessions use `retail`, `clinic`, `restaurant`, `salon`, `services`,
/// or `wholesale`; these are normalized to the new sector IDs at this boundary.
final businessVerticalIdProvider = Provider<String>((ref) {
  final session = ref.watch(authProvider);
  return canonicalBusinessVerticalId(session?.businessVertical);
});

/// Full configuration for the authenticated business vertical.
final businessVerticalProvider = Provider<BusinessVertical>((ref) {
  return businessVerticalFor(ref.watch(businessVerticalIdProvider));
});

/// Labels used by shared screens such as sales, inventory, and customers.
final businessLabelsProvider = Provider<BusinessLabels>((ref) {
  final vertical = ref.watch(businessVerticalProvider);
  return BusinessLabels(
    sales: vertical.salesLabel,
    stock: vertical.stockLabel,
    customers: vertical.customerLabel,
  );
});

/// Feature flags for the authenticated business vertical.
final enabledBusinessFeaturesProvider = Provider<Set<String>>((ref) {
  return ref.watch(businessVerticalProvider).enabledFeatures;
});

final businessFeatureAvailableProvider = Provider.family<bool, String>(
  (ref, feature) =>
      ref.watch(enabledBusinessFeaturesProvider).contains(feature),
);

/// Main product or service categories for the current vertical.
final productCategoriesProvider = Provider<List<String>>((ref) {
  final hierarchy = getCategoryHierarchyFor(
    ref.watch(businessVerticalIdProvider),
  );
  return hierarchy?.mainCategories ?? const [];
});

/// Subcategories for a main category in the current vertical.
final productSubcategoriesProvider =
    Provider.family<List<String>, String>((ref, category) {
  final subcategories = getSubcategoriesFor(
    ref.watch(businessVerticalIdProvider),
    category,
  );
  return subcategories ?? const [];
});

/// A session-scoped category selection for screens such as POS.
final selectedProductCategoryProvider =
    StateProvider.family<String, String>((ref, verticalId) => 'All');

/// Income categories for the current vertical.
final incomeCategoriesProvider = Provider<List<String>>((ref) {
  return getIncomeCategories(ref.watch(businessVerticalIdProvider));
});

/// Expense categories for the current vertical.
final expenseCategoriesProvider = Provider<List<String>>((ref) {
  return getExpenseCategories(ref.watch(businessVerticalIdProvider));
});

/// Recurring expense suggestions and their expected frequency.
final recurringExpensesProvider = Provider<Map<String, String>>((ref) {
  return getRecurringExpenses(ref.watch(businessVerticalIdProvider));
});

/// Read-only labels shared by vertical-aware screens.
class BusinessLabels {
  final String sales;
  final String stock;
  final String customers;

  const BusinessLabels({
    required this.sales,
    required this.stock,
    required this.customers,
  });
}
