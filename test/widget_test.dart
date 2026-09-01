import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duka/core/utils/export_service.dart';
import 'package:duka/main.dart';

void main() {
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
}
