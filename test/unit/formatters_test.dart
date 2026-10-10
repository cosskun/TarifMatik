import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_matik/core/utils/formatters.dart';

void main() {
  group('Formatters Tests', () {
    test('formatAmount formats whole and decimal numbers correctly', () {
      expect(Formatters.formatAmount(2.0), '2');
      expect(Formatters.formatAmount(1.5), '1.5');
      expect(Formatters.formatAmount(0.75), '0.75');
      expect(Formatters.formatAmount(10.00), '10');
    });

    test('formatPrice formats Turkish Lira currency properly', () {
      expect(Formatters.formatPrice(120.0), '120.00 TL');
      expect(Formatters.formatPrice(120.50), '120.50 TL');
      expect(Formatters.formatPrice(5000.0, showDecimals: false), '5000 TL');
    });

    test('formatTimer formats seconds to mm:ss', () {
      expect(Formatters.formatTimer(0), '00:00');
      expect(Formatters.formatTimer(65), '01:05');
      expect(Formatters.formatTimer(900), '15:00');
    });

    test('capitalize capitalizes the first character', () {
      expect(Formatters.capitalize('domates'), 'Domates');
      expect(Formatters.capitalize('  süt  '), 'Süt');
      expect(Formatters.capitalize(''), '');
    });

    test('getMonthName returns Turkish month names', () {
      expect(Formatters.getMonthName(1), 'Ocak');
      expect(Formatters.getMonthName(5), 'Mayıs');
      expect(Formatters.getMonthName(12), 'Aralık');
      expect(Formatters.getMonthName(13), '');
    });
  });
}
