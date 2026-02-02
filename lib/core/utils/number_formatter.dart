/// Utility class for formatting numbers consistently across the app

class NumberFormatter {
  /// Format points with K/M suffix for display
  /// Rules:
  /// - 0-9,999: show as is (e.g., "3000")
  /// - 10,000-999,999: show as K (e.g., "10K", "99.5K")
  /// - 1,000,000+: show as M (e.g., "1M", "1.5M")
  /// - Remove unnecessary decimals (e.g., "10.0K" → "10K")
  static String formatPoints(int points) {
    if (points >= 1000000) {
      final value = points / 1000000;
      if (value == value.truncate()) {
        return '${value.truncate()}M';
      }
      final formatted = value.toStringAsFixed(1);
      // Remove trailing .0
      return formatted.endsWith('.0')
          ? '${value.truncate()}M'
          : '${formatted}M';
    } else if (points >= 10000) {
      final value = points / 1000;
      if (value == value.truncate()) {
        return '${value.truncate()}K';
      }
      final formatted = value.toStringAsFixed(1);
      // Remove trailing .0
      return formatted.endsWith('.0')
          ? '${value.truncate()}K'
          : '${formatted}K';
    }
    return points.toString();
  }

  /// Format amount - show whole number if no decimals, otherwise show decimals
  /// e.g., 10.0 → "10", 10.5 → "10.5", 10.123 → "10.123"
  static String formatAmount(double amount, {int maxDecimals = 3}) {
    if (amount == amount.truncateToDouble()) {
      return amount.toInt().toString();
    }
    // Remove trailing zeros
    String formatted = amount.toStringAsFixed(maxDecimals);
    while (formatted.contains('.') && (formatted.endsWith('0') || formatted.endsWith('.'))) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  }

  /// Format balance value without suffix (for use in split displays)
  /// Rules:
  /// - Under 1000: always show 3 decimals (e.g., "22.000", "999.500")
  /// - 1000+: show decimals only if they exist (e.g., "1000", "1000.001")
  static String formatBalanceValue(double balance) {
    if (balance >= 1000) {
      // For 1000+ show decimals only if they exist
      if (balance == balance.truncateToDouble()) {
        return balance.toInt().toString();
      }
      // Has decimals - show them (remove trailing zeros but keep significant ones)
      String formatted = balance.toStringAsFixed(3);
      while (formatted.endsWith('0')) {
        formatted = formatted.substring(0, formatted.length - 1);
      }
      if (formatted.endsWith('.')) {
        formatted = formatted.substring(0, formatted.length - 1);
      }
      return formatted;
    }
    // Under 1000 - always show 3 decimals
    return balance.toStringAsFixed(3);
  }

  /// Format balance with TND suffix
  /// Rules:
  /// - Under 1000: always show 3 decimals (e.g., "22.000 TND", "999.500 TND")
  /// - 1000+: show decimals only if they exist (e.g., "1000 TND", "1000.001 TND")
  static String formatBalance(double balance) {
    return '${formatBalanceValue(balance)} TND';
  }

  /// Format number with thousand separators
  /// e.g., 1234567 → "1,234,567"
  static String formatWithCommas(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
