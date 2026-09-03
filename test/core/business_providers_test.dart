import 'package:flutter_test/flutter_test.dart';

import 'package:duka/core/constants/business_categories.dart';
import 'package:duka/core/constants/business_presets.dart';
import 'package:duka/core/constants/business_verticals.dart';

void main() {
  test('all business verticals have categories and transaction presets', () {
    expect(businessVerticals, hasLength(14));

    for (final vertical in businessVerticals) {
      final hierarchy = getCategoryHierarchyFor(vertical.id);
      final presets = getPresetsFor(vertical.id);

      expect(hierarchy, isNotNull, reason: vertical.id);
      expect(hierarchy!.mainCategories, isNotEmpty, reason: vertical.id);
      expect(presets, isNotNull, reason: vertical.id);
      expect(presets!.incomeCategories, isNotEmpty, reason: vertical.id);
      expect(presets.expenseCategories, isNotEmpty, reason: vertical.id);
    }
  });

  test('legacy vertical IDs normalize to canonical sectors', () {
    expect(canonicalBusinessVerticalId('retail'), 'wholesale_retail');
    expect(canonicalBusinessVerticalId('wholesale'), 'wholesale_retail');
    expect(canonicalBusinessVerticalId('restaurant'), 'food_hospitality');
    expect(canonicalBusinessVerticalId('salon'), 'personal_services');
    expect(canonicalBusinessVerticalId('clinic'), 'health');
    expect(canonicalBusinessVerticalId('services'), 'personal_services');
    expect(canonicalBusinessVerticalId(null), 'wholesale_retail');
  });
}
