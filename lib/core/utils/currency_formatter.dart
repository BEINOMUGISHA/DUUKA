import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _ugxFormat = NumberFormat.currency(
    locale: 'en_UG',
    symbol: 'UGX ',
    decimalDigits: 0,
  );

  static final NumberFormat _compactFormat = NumberFormat.compactCurrency(
    locale: 'en_UG',
    symbol: 'UGX ',
    decimalDigits: 0,
  );

  static String format(num? amount) {
    if (amount == null) return 'UGX 0';
    return _ugxFormat.format(amount);
  }

  static String formatCompact(num? amount) {
    if (amount == null) return 'UGX 0';
    return _compactFormat.format(amount);
  }

  static String formatPlain(num? amount) {
    if (amount == null) return '0';
    final formatter = NumberFormat('#,###', 'en_UG');
    return formatter.format(amount);
  }
}
