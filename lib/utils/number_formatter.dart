class NumberFormatter {
  /// Format large numbers with abbreviations
  static String format(num number) {
    // ✅ Guard against NaN and Infinity which can crash the formatter
    if (number.isNaN || number.isInfinite) return '0';

    if (number < 1000) {
      return number.round().toString();
    } else if (number < 1000000) {
      double value = number / 1000;
      return '${_formatDecimal(value)}K';
    } else if (number < 1000000000) {
      double value = number / 1000000;
      return '${_formatDecimal(value)}M';
    } else if (number < 1000000000000) {
      double value = number / 1000000000;
      return '${_formatDecimal(value)}B';
    } else if (number < 1000000000000000) {
      double value = number / 1000000000000;
      return '${_formatDecimal(value)}T';
    } else if (number < 1e18) {
      double value = number / 1e15;
      return '${_formatDecimal(value)}Qd';
    } else if (number < 1e21) {
      double value = number / 1e18;
      return '${_formatDecimal(value)}Qt';
    } else if (number < 1e24) {
      double value = number / 1e21;
      return '${_formatDecimal(value)}Sx';
    } else if (number < 1e27) {
      double value = number / 1e24;
      return '${_formatDecimal(value)}Sp';
    } else {
      double value = number / 1e27;
      return '${_formatDecimal(value)}Oc';
    }
  }

  static String _formatDecimal(double value) {
    // ✅ Guard against NaN and Infinity before any string operations
    if (value.isNaN || value.isInfinite) return '0';

    String result;

    if (value >= 100) {
      result = value.round().toString();
    } else if (value >= 10) {
      result = value.toStringAsFixed(1);
      if (result.endsWith('.0')) {
        result = value.round().toString();
      }
    } else {
      result = value.toStringAsFixed(2);
      result = result.replaceAll(RegExp(r'\.?0+$'), '');
    }

    // ✅ If regex stripping left us with an empty string,
    // a bare minus sign, or just a dot — fall back to '0'
    if (result.isEmpty || result == '-' || result == '.') return '0';

    return result;
  }
}