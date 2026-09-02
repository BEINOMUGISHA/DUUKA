import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:duka/core/database/app_database.dart';
import 'package:duka/core/constants/business_verticals.dart';
import 'package:duka/core/utils/export_service.dart';
import 'package:duka/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('DUKA app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DukaApp()));
    expect(find.byType(DukaApp), findsOneWidget);
  });

  test('CSV export escapes commas, quotes, and line breaks', () {
    expect(ExportService.escapeCsvField('DUKA, Inc.'), '"DUKA, Inc."');
    expect(
        ExportService.escapeCsvField('He said "hello"'), '"He said ""hello"""');
    expect(ExportService.escapeCsvField('Line 1\nLine 2'), '"Line 1\nLine 2"');
  });

  test('business verticals support non-retail SMEs with a safe fallback', () {
    expect(businessVerticalFor('clinic').customerLabel, 'Patients');
    expect(businessVerticalFor('restaurant').salesLabel, 'Orders');
    expect(businessVerticalFor('salon').customerLabel, 'Clients');
    expect(businessVerticalFor('unknown').id, 'retail');
  });

  test('local products are isolated per business', () async {
    final db = AppDatabase();
    await db.init();
    await db.insertProduct(LocalProductData(
      id: 'product_business_a',
      businessId: 'business_a',
      name: 'Clinic Service',
      category: 'Services',
      costPrice: 100,
      sellPrice: 150,
      currentStock: 1,
      minStockLevel: 1,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    await db.insertProduct(LocalProductData(
      id: 'product_business_b',
      businessId: 'business_b',
      name: 'Restaurant Meal',
      category: 'Food',
      costPrice: 200,
      sellPrice: 300,
      currentStock: 1,
      minStockLevel: 1,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));

    final businessAProducts = await db.getProducts(businessId: 'business_a');
    expect(businessAProducts.map((product) => product.id),
        contains('product_business_a'));
    expect(businessAProducts.map((product) => product.id),
        isNot(contains('product_business_b')));
  });

  test('Accounting foundation exposes chart of accounts and journal entries',
      () async {
    final db = AppDatabase();
    await db.init();

    final accounts = await db.getChartOfAccounts();
    expect(accounts, isNotEmpty);
    expect(accounts.any((a) => a.code == '1000'), isTrue);

    final entities = await db.getBusinessEntities();
    expect(entities, isNotEmpty);
    expect(entities.any((e) => e.isDefault), isTrue);

    final journal = LocalJournalEntryData(
      id: 'je_test_1',
      businessId: 'biz_default',
      reference: 'JE-TEST-001',
      memo: 'Seeded test entry',
      debitAccountId: 'coa_cash',
      creditAccountId: 'coa_sales',
      amount: 250000,
      entryDate: DateTime.now().millisecondsSinceEpoch,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await db.createJournalEntry(journal);
    final entries = await db.getJournalEntries();
    expect(entries.any((e) => e.reference == 'JE-TEST-001'), isTrue);
  });
}
