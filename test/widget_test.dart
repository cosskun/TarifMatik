import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarif_matik/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('TarifMatik app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TarifMatikRoot());
    await tester.pumpAndSettle();

    // Verify that our app header starts with the name 'TarifMatik' on LoginPage.
    expect(find.text('TarifMatik'), findsWidgets);

    // Find the login inputs
    final usernameFinder = find.widgetWithText(TextFormField, 'Kullanıcı Adı');
    final passwordFinder = find.widgetWithText(TextFormField, 'Şifre');
    final buttonFinder = find.text('GİRİŞ YAP');

    expect(usernameFinder, findsOneWidget);
    expect(passwordFinder, findsOneWidget);
    expect(buttonFinder, findsOneWidget);

    // Enter login info
    await tester.enterText(usernameFinder, 'uye');
    await tester.enterText(passwordFinder, 'uye');
    await tester.tap(buttonFinder);

    // Pump multiple times to allow SharedPreferences and async loadUserData to complete
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();



    expect(find.text('Ana Sayfa'), findsOneWidget);
    expect(find.text('Kilerim'), findsOneWidget);
    expect(find.text('Öneriler'), findsOneWidget);
  });
}
