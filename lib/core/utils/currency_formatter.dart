class CurrencyFormatter {
  static const String usd = 'USD';
  static const String pkr = 'PKR';

  static String normalizeCode(String? currencyCode) {
    final code = (currencyCode ?? usd).trim().toUpperCase();
    if (code == pkr) return pkr;
    return usd;
  }

  static String symbolFor(String? currencyCode) {
    switch (normalizeCode(currencyCode)) {
      case pkr:
        return 'PKR';
      case usd:
      default:
        return r'$';
    }
  }

  static String formatAmount(
    double amount, {
    String? currencyCode,
    int decimalDigits = 2,
  }) {
    final symbol = symbolFor(currencyCode);
    final value = amount.toStringAsFixed(decimalDigits);
    if (symbol == r'$') {
      return '$symbol$value';
    }
    return '$symbol $value';
  }

  static String format(double value, {String? currencyCode}) =>
      formatAmount(value, currencyCode: currencyCode);
}
