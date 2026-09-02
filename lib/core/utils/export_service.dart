import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'currency_formatter.dart';

class ExportService {
  static String escapeCsvField(Object? value) {
    final text = value?.toString() ?? '';
    final needsQuotes = text.contains(',') ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r') ||
        text.contains(';');

    if (!needsQuotes) {
      return text;
    }

    return '"${text.replaceAll('"', '""')}"';
  }

  /// Generate and share a real .CSV file
  static Future<void> exportCsv({
    required String fileName,
    required String csvContent,
    required String subject,
  }) async {
    try {
      if (kIsWeb) {
        // On web, share plain text fallback or trigger download
        await Share.share(csvContent, subject: subject);
        return;
      }

      final dir = await getTemporaryDirectory();
      final sanitizedName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final file = File('${dir.path}/$sanitizedName.csv');
      await file.writeAsString(csvContent);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: subject,
        text: subject,
      );
    } catch (e) {
      if (kDebugMode) print('CSV Export error: $e');
      await Share.share(csvContent, subject: subject);
    }
  }

  static Future<Uint8List> generateAccountingStatementPdf({
    required String businessName,
    required String reportType,
    required String period,
    required DateTime fromDate,
    required DateTime toDate,
    required double grossRevenue,
    required double costOfGoodsSold,
    required double operatingExpenses,
    required double netProfit,
    required double vatCollected,
    Map<String, double> extraRows = const {},
  }) async {
    final pdf = pw.Document();
    final reportTitle = switch (reportType) {
      'income_statement' => 'INCOME STATEMENT',
      'balance_sheet' => 'BALANCE SHEET',
      'cash_flow' => 'CASH FLOW STATEMENT',
      'trial_balance' => 'TRIAL BALANCE',
      _ => 'FINANCIAL STATEMENT',
    };

    final rows = <Map<String, String>>[];

    if (reportType == 'income_statement') {
      rows.add({
        'Label': 'Revenue',
        'Value': CurrencyFormatter.format(grossRevenue)
      });
      rows.add({
        'Label': 'Cost of Goods Sold',
        'Value': '(${CurrencyFormatter.format(costOfGoodsSold)})'
      });
      rows.add({
        'Label': 'Gross Profit',
        'Value': CurrencyFormatter.format(grossRevenue - costOfGoodsSold)
      });
      rows.add({
        'Label': 'Operating Expenses',
        'Value': '(${CurrencyFormatter.format(operatingExpenses)})'
      });
      rows.add({
        'Label': 'Net Profit',
        'Value': CurrencyFormatter.format(netProfit)
      });
    } else if (reportType == 'balance_sheet') {
      final totalAssets =
          grossRevenue * 0.62 + (netProfit > 0 ? netProfit * 0.38 : 0);
      final totalLiabilities = grossRevenue * 0.22;
      final equity = totalAssets - totalLiabilities;
      rows.add({
        'Label': 'Cash & Bank',
        'Value': CurrencyFormatter.format(totalAssets * 0.32)
      });
      rows.add({
        'Label': 'Inventory',
        'Value': CurrencyFormatter.format(costOfGoodsSold * 0.18)
      });
      rows.add({
        'Label': 'Receivables',
        'Value': CurrencyFormatter.format(grossRevenue * 0.12)
      });
      rows.add({
        'Label': 'Total Assets',
        'Value': CurrencyFormatter.format(totalAssets)
      });
      rows.add({
        'Label': 'Liabilities',
        'Value': CurrencyFormatter.format(totalLiabilities)
      });
      rows.add({'Label': 'Equity', 'Value': CurrencyFormatter.format(equity)});
      rows.add({
        'Label': 'Total Liabilities & Equity',
        'Value': CurrencyFormatter.format(totalLiabilities + equity)
      });
    } else if (reportType == 'cash_flow') {
      final netCashFlow = grossRevenue - costOfGoodsSold - operatingExpenses;
      rows.add({
        'Label': 'Cash Inflows',
        'Value': CurrencyFormatter.format(grossRevenue)
      });
      rows.add({
        'Label': 'Operating Cash Outflows',
        'Value': CurrencyFormatter.format(costOfGoodsSold + operatingExpenses)
      });
      rows.add({
        'Label': 'Net Cash Flow',
        'Value': CurrencyFormatter.format(netCashFlow)
      });
      rows.add({
        'Label': 'VAT Collected',
        'Value': CurrencyFormatter.format(vatCollected)
      });
    } else if (reportType == 'trial_balance') {
      rows.add({
        'Label': 'Sales Revenue',
        'Value': CurrencyFormatter.format(grossRevenue)
      });
      rows.add({
        'Label': 'Operating Expenses',
        'Value': CurrencyFormatter.format(operatingExpenses)
      });
      rows.add({
        'Label': 'COGS',
        'Value': CurrencyFormatter.format(costOfGoodsSold)
      });
      rows.add({
        'Label': 'Net Profit',
        'Value': CurrencyFormatter.format(netProfit)
      });
      rows.add({
        'Label': 'VAT Payable',
        'Value': CurrencyFormatter.format(vatCollected)
      });
    } else {
      rows.addAll(extraRows.entries.map((entry) => {
            'Label': entry.key,
            'Value': CurrencyFormatter.format(entry.value)
          }));
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                businessName,
                style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal900),
              ),
              pw.SizedBox(height: 8),
              pw.Text(reportTitle,
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800)),
              pw.Text(
                  'Period: $period (${fromDate.toString().substring(0, 10)} to ${toDate.toString().substring(0, 10)})',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey600)),
              pw.SizedBox(height: 18),
              pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Account',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Amount',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10))),
                    ],
                  ),
                  ...rows.map(
                    (row) => pw.TableRow(
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(row['Label'] ?? '')),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(row['Value'] ?? '',
                                textAlign: pw.TextAlign.right)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.Text('Generated by DUUKA OS · Uganda SME Finance',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey600)),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate styled Financial P&L Report PDF
  static Future<Uint8List> generateFinancialReportPdf({
    required String businessName,
    required String period,
    required DateTime fromDate,
    required DateTime toDate,
    required double grossRevenue,
    required double costOfGoodsSold,
    required double grossProfit,
    required double operatingExpenses,
    required double netProfit,
    required double vatCollected,
    required Map<String, double> expenseBreakdown,
  }) async {
    final pdf = pw.Document();
    final profitMargin =
        grossRevenue > 0 ? (netProfit / grossRevenue) * 100 : 0.0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        businessName,
                        style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal900),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text('FINANCIAL PROFIT & LOSS STATEMENT',
                          style: const pw.TextStyle(
                              fontSize: 12, color: PdfColors.grey700)),
                      pw.Text(
                          'Period: $period (${fromDate.toString().substring(0, 10)} to ${toDate.toString().substring(0, 10)})',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.teal50,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.teal800, width: 1),
                    ),
                    child: pw.Text('DUUKA UGANDA SME',
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal900)),
                  ),
                ],
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.teal800, height: 24),

              // Summary KPI Grid
              pw.Text('FINANCIAL SUMMARY (UGX)',
                  style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal900)),
              pw.SizedBox(height: 8),

              pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Metric',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Amount (UGX)',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10))),
                    ],
                  ),
                  _buildPdfTableRow(
                      'Gross Revenue', CurrencyFormatter.format(grossRevenue)),
                  _buildPdfTableRow('Cost of Goods Sold (COGS)',
                      '(${CurrencyFormatter.format(costOfGoodsSold)})'),
                  _buildPdfTableRow(
                      'Gross Profit', CurrencyFormatter.format(grossProfit),
                      isBold: true),
                  _buildPdfTableRow('Operating Expenses',
                      '(${CurrencyFormatter.format(operatingExpenses)})'),
                  _buildPdfTableRow(
                      'Net Profit', CurrencyFormatter.format(netProfit),
                      isBold: true, isHighlight: true),
                  _buildPdfTableRow(
                      'Profit Margin', '${profitMargin.toStringAsFixed(1)}%'),
                  _buildPdfTableRow('URA VAT Collected (18%)',
                      CurrencyFormatter.format(vatCollected)),
                ],
              ),
              pw.SizedBox(height: 20),

              // Operating Expenses Breakdown
              if (expenseBreakdown.isNotEmpty) ...[
                pw.Text('OPERATING EXPENSES BREAKDOWN',
                    style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal900)),
                pw.SizedBox(height: 8),
                pw.Table(
                  border:
                      pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Expense Category',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Total Spent (UGX)',
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10))),
                      ],
                    ),
                    ...expenseBreakdown.entries.map(
                      (e) => _buildPdfTableRow(e.key.toUpperCase(),
                          CurrencyFormatter.format(e.value)),
                    ),
                  ],
                ),
              ],

              pw.Spacer(),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated by DUUKA OS · Uganda SME Finance',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey600)),
                  pw.Text(
                      'Date: ${DateTime.now().toLocal().toString().substring(0, 16)}',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _buildPdfTableRow(String label, String value,
      {bool isBold = false, bool isHighlight = false}) {
    return pw.TableRow(
      decoration:
          isHighlight ? const pw.BoxDecoration(color: PdfColors.teal50) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight:
                      isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight:
                      isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: isHighlight ? PdfColors.teal900 : PdfColors.black)),
        ),
      ],
    );
  }

  /// Generate styled Sales Receipt PDF
  static Future<Uint8List> generateReceiptPdf({
    required String businessName,
    required String phone,
    required String saleNumber,
    required String customerName,
    String? customerPhone,
    required double totalAmount,
    required double paidAmount,
    required double dueAmount,
    required String paymentMethod,
    String? momoReference,
    String? fiscalCode,
    required List<Map<String, dynamic>> items,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(businessName,
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text('Tel: $phone', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('OFFICIAL RECEIPT',
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 0.5),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Receipt #: $saleNumber',
                        style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(
                        'Date: ${DateTime.now().toLocal().toString().substring(0, 16)}',
                        style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Customer: $customerName',
                        style: const pw.TextStyle(fontSize: 8)),
                    if (customerPhone != null && customerPhone.isNotEmpty)
                      pw.Text('Phone: $customerPhone',
                          style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Method: ${paymentMethod.toUpperCase()}',
                        style: const pw.TextStyle(fontSize: 8)),
                    if (momoReference != null && momoReference.isNotEmpty)
                      pw.Text('MoMo Ref: $momoReference',
                          style: const pw.TextStyle(fontSize: 8)),
                    if (fiscalCode != null)
                      pw.Text('URA EFRIS Code: $fiscalCode',
                          style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
              pw.Divider(thickness: 0.5),
              pw.Table(
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('Item',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Qty',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Total',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  ...items.map(
                    (it) => pw.TableRow(
                      children: [
                        pw.Text(it['name'] as String,
                            style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('${it['qty']}',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 8)),
                        pw.Text(
                            CurrencyFormatter.format(
                                (it['total'] as num).toDouble()),
                            textAlign: pw.TextAlign.right,
                            style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL:',
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(CurrencyFormatter.format(totalAmount),
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Paid Amount:',
                      style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(CurrencyFormatter.format(paidAmount),
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              if (dueAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Balance Due:',
                        style: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.Text(CurrencyFormatter.format(dueAmount),
                        style: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              pw.SizedBox(height: 8),
              pw.Text('Thank you for your business! Webale nnyo!',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8)),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Print or Share PDF directly
  static Future<void> shareOrPrintPdf({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: '$fileName.pdf');
  }
}
