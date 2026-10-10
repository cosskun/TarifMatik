class Formatters {
  /// Formats numeric amounts like 2.0 -> "2", 1.50 -> "1.5", 0.333 -> "0.33"
  static String formatAmount(double val) {
    if (val == val.roundToDouble()) {
      return val.round().toString();
    }
    return val.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  /// Formats currency to Turkish Lira string e.g. "120.00 TL" or "120 TL"
  static String formatPrice(double price, {bool showDecimals = true}) {
    if (showDecimals) {
      return '${price.toStringAsFixed(2)} TL';
    }
    return '${price.toStringAsFixed(0)} TL';
  }

  /// Formats seconds to mm:ss timer string (e.g. 90 -> "01:30")
  static String formatTimer(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Formats date to Turkish localized format DD.MM.YYYY
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Capitalizes first letter of a string safely
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  /// Turkish Month Names
  static String getMonthName(int month) {
    const months = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    if (month >= 1 && month <= 12) return months[month];
    return '';
  }
}
