/// Utility class to format and normalize Ugandan Phone numbers
class PhoneFormatter {
  /// Normalizes any Ugandan phone string to "2567XXXXXXXX"
  /// Handles inputs like:
  /// - 0772123456 -> 256772123456
  /// - +256772123456 -> 256772123456
  /// - 772123456 -> 256772123456
  static String normalize(String raw) {
    String cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('0') && cleaned.length == 10) {
      return '256${cleaned.substring(1)}';
    } else if (cleaned.startsWith('256') && cleaned.length == 12) {
      return cleaned;
    } else if (cleaned.length == 9) {
      return '256$cleaned';
    }
    return cleaned;
  }

  /// Formats for local user display (e.g. "0772 123 456" or "+256 772 123456")
  static String formatDisplay(String raw) {
    final normalized = normalize(raw);
    if (normalized.startsWith('256') && normalized.length == 12) {
      final prefix = '0${normalized.substring(3, 5)}';
      final mid = normalized.substring(5, 8);
      final rest = normalized.substring(8);
      return '$prefix$mid $rest';
    }
    return raw;
  }

  /// Determines carrier based on Ugandan prefixes (MTN, Airtel)
  static String getCarrier(String raw) {
    final normalized = normalize(raw);
    if (normalized.length < 5) return 'Unknown';
    final prefix = normalized.substring(3, 5); // e.g. "77", "78", "75", "70", "74"
    if (['77', '78', '76', '39'].contains(prefix)) {
      return 'MTN';
    } else if (['75', '70', '74'].contains(prefix)) {
      return 'Airtel';
    }
    return 'Other';
  }
}
