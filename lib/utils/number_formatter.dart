class NumberFormatter {
  /// Format large numbers with abbreviations
  static String format(num number) { // ← Changed from int to num (accepts int or double)
    if (number < 1000) {
      return number.round().toString();
    } else if (number < 1000000) {
      // Thousands (K)
      double value = number / 1000;
      return '${_formatDecimal(value)}K';
    } else if (number < 1000000000) {
      // Millions (M)
      double value = number / 1000000;
      return '${_formatDecimal(value)}M';
    } else if (number < 1000000000000) {
      // Billions (B)
      double value = number / 1000000000;
      return '${_formatDecimal(value)}B';
    } else if (number < 1000000000000000) {
      // Trillions (T)
      double value = number / 1000000000000;
      return '${_formatDecimal(value)}T';
    } else if (number < 1e18) {
      // Quadrillions (Qd)
      double value = number / 1e15;
      return '${_formatDecimal(value)}Qd';
    } else if (number < 1e21) {
      // Quintillions (Qt)
      double value = number / 1e18;
      return '${_formatDecimal(value)}Qt';
    } else if (number < 1e24) {
      // Sextillions (Sx)
      double value = number / 1e21;
      return '${_formatDecimal(value)}Sx';
    } else if (number < 1e27) {
      // Septillions (Sp)
      double value = number / 1e24;
      return '${_formatDecimal(value)}Sp';
    } else {
      // Octillions+ (Oc)
      double value = number / 1e27;
      return '${_formatDecimal(value)}Oc';
    }
  }

  static String _formatDecimal(double value) {
    if (value >= 100) {
      return value.round().toString();
    } else if (value >= 10) {
      String result = value.toStringAsFixed(1);
      if (result.endsWith('.0')) {
        return value.round().toString();
      }
      return result;
    } else {
      String result = value.toStringAsFixed(2);
      result = result.replaceAll(RegExp(r'\.?0+$'), '');
      return result;
    }
  }
}
