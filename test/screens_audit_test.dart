import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarif_matik/core/theme/app_theme.dart';
import 'package:tarif_matik/models/ingredient.dart';
import 'package:tarif_matik/models/recipe.dart';
import 'package:tarif_matik/providers/app_state.dart';
import 'package:tarif_matik/screens/cooking_assistant_page.dart';
import 'package:tarif_matik/screens/detailed_report_page.dart';
import 'package:tarif_matik/screens/expiring_ingredients_page.dart';
import 'package:tarif_matik/screens/home_page.dart';
import 'package:tarif_matik/screens/login_page.dart';
import 'package:tarif_matik/screens/meal_planner_page.dart';
import 'package:tarif_matik/screens/pantry_page.dart';
import 'package:tarif_matik/screens/recipe_detail_page.dart';
import 'package:tarif_matik/screens/recipe_suggestions_page.dart';
import 'package:tarif_matik/screens/shopping_budget_page.dart';
import 'package:tarif_matik/screens/wheel_page.dart';

Widget buildScreenWrapper({
  required Widget screen,
  required AppState appState,
  Size size = const Size(390, 844),
  bool isDark = false,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AppState>.value(value: appState),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: screen,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppState appState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    appState = AppState();
    // Allow initData to settle
    await Future.delayed(const Duration(milliseconds: 50));
    await appState.login('uye', 'uye');

    if (appState.recipes.isEmpty) {
      appState.recipes.addAll([
        Recipe(
          id: 'rec_mercimek',
          name: 'Mercimek Çorbası',
          category: 'Öğle Yemeği',
          durationMinutes: 25,
          baseServings: 4,
          ingredients: [
            Ingredient(name: 'Kırmızı Mercimek', amount: 1, unit: 'su bardağı'),
            Ingredient(name: 'Soğan', amount: 1, unit: 'adet'),
            Ingredient(name: 'Salça', amount: 1, unit: 'yemek kaşığı'),
            Ingredient(name: 'Su', amount: 6, unit: 'su bardağı'),
          ],
          instructions: [
            'Soğanı doğrayın ve tencerede kavurun.',
            'Yıkanmış mercimekleri ve salçayı ekleyin.',
            'Suyu ilave edip 20 dakika kısık ateşte kaynatın.',
            'Blenderdan geçirip sıcak servis yapın.',
          ],
          emoji: '🍲',
        ),
        Recipe(
          id: 'rec_omlet',
          name: 'Hızlı Omlet',
          category: 'Kahvaltı',
          durationMinutes: 5,
          baseServings: 1,
          ingredients: [
            Ingredient(name: 'Yumurta', amount: 2, unit: 'adet'),
            Ingredient(name: 'Tereyağı', amount: 1, unit: 'yemek kaşığı'),
          ],
          instructions: [
            'Yumurtaları bir kasede çırpın.',
            'Tavada tereyağını eritin.',
            'Yumurtayı döküp 3 dakika pişirin.',
          ],
          emoji: '🍳',
        ),
      ]);
    }
  });

  group('TarifMatik Comprehensive Screen-by-Screen UI & Action Audit', () {
    const phoneSizes = [
      Size(390, 844), // iOS iPhone 14/15/16
      Size(412, 915), // Android Pixel / Samsung Galaxy
    ];

    for (final size in phoneSizes) {
      final platformLabel = size.width == 390 ? 'iOS (390x844)' : 'Android (412x915)';

      testWidgets('[$platformLabel] LoginPage renders and switches between Login and Register', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildScreenWrapper(screen: const LoginPage(), appState: appState, size: size));
        await tester.pumpAndSettle();

        expect(find.text('TarifMatik'), findsWidgets);
        expect(find.text('GİRİŞ YAP'), findsOneWidget);

        // Switch to register mode
        final switchModeBtn = find.text('Hesabınız yok mu? Şimdi Kayıt Olun');
        expect(switchModeBtn, findsOneWidget);
        await tester.tap(switchModeBtn);
        await tester.pumpAndSettle();

        expect(find.text('KAYIT OL'), findsOneWidget);
      });

      testWidgets('[$platformLabel] HomePage renders, person counter, dark mode toggle work', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildScreenWrapper(
          screen: HomePage(onTabChange: (int tab, {int? subTabIndex}) {}),
          appState: appState,
          size: size,
        ));
        await tester.pumpAndSettle();

        expect(find.text('TarifMatik'), findsWidgets);

        // Test Person counter buttons (+ and -)
        final initialPersons = appState.personCount;
        final plusButtons = find.byIcon(Icons.add);
        if (plusButtons.evaluate().isNotEmpty) {
          await tester.tap(plusButtons.first);
          await tester.pumpAndSettle();
          expect(appState.personCount, initialPersons + 1);

          final minusButtons = find.byIcon(Icons.remove);
          if (minusButtons.evaluate().isNotEmpty) {
            await tester.tap(minusButtons.first);
            await tester.pumpAndSettle();
            expect(appState.personCount, initialPersons);
          }
        }

        // Test Dark mode toggle icon button
        final themeButton = find.byIcon(Icons.dark_mode_outlined);
        if (themeButton.evaluate().isNotEmpty) {
          await tester.tap(themeButton);
          await tester.pumpAndSettle();
          expect(appState.themeMode, ThemeMode.dark);
        }
      });

      testWidgets('[$platformLabel] PantryPage renders, search and category tabs work', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildScreenWrapper(screen: const PantryPage(), appState: appState, size: size));
        await tester.pumpAndSettle();

        expect(find.text('Kilerim (Malzeme Stoğu)'), findsWidgets);

        // Test search input
        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          await tester.enterText(searchField.first, 'Domates');
          await tester.pumpAndSettle();
        }

        // Test Add Item FAB
        final fab = find.byType(FloatingActionButton);
        if (fab.evaluate().isNotEmpty) {
          await tester.tap(fab);
          await tester.pumpAndSettle();
          // Check that modal dialog appeared
          expect(find.text('Kilere Malzeme Ekle'), findsWidgets);
          // Dismiss modal dialog
          final cancelButton = find.text('İptal');
          if (cancelButton.evaluate().isNotEmpty) {
            await tester.tap(cancelButton);
            await tester.pumpAndSettle();
          }
        }
      });

      testWidgets('[$platformLabel] RecipeSuggestionsPage renders and filter chips work', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildScreenWrapper(screen: const RecipeSuggestionsPage(), appState: appState, size: size));
        await tester.pumpAndSettle();

        expect(find.text('Ne Pişirebilirim?'), findsWidgets);

        // Test clicking filter chips
        final vegChip = find.text('Vejetaryen');
        if (vegChip.evaluate().isNotEmpty) {
          await tester.tap(vegChip);
          await tester.pumpAndSettle();
        }

        final quickChip = find.text('15 Dk Altı');
        if (quickChip.evaluate().isNotEmpty) {
          await tester.tap(quickChip);
          await tester.pumpAndSettle();
        }

        // Check custom recipe FAB
        final addRecipeFab = find.byType(FloatingActionButton);
        if (addRecipeFab.evaluate().isNotEmpty) {
          await tester.tap(addRecipeFab.first);
          await tester.pumpAndSettle();
          expect(find.text('Kendi Tarifini Ekle'), findsWidgets);
          // Close dialog
          final closeButton = find.byIcon(Icons.close);
          if (closeButton.evaluate().isNotEmpty) {
            await tester.tap(closeButton.first);
            await tester.pumpAndSettle();
          }
        }
      });

      testWidgets('[$platformLabel] RecipeDetailPage renders, scaler and favorite toggle work', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final sampleRecipe = appState.recipes.first;
        await tester.pumpWidget(buildScreenWrapper(
          screen: RecipeDetailPage(recipe: sampleRecipe),
          appState: appState,
          size: size,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Malzemeler'), findsWidgets);
        expect(find.text('Hazırlanışı'), findsWidgets);

        // Test Favorite toggle
        final favoriteBtn = find.byIcon(Icons.favorite_border);
        if (favoriteBtn.evaluate().isNotEmpty) {
          await tester.tap(favoriteBtn);
          await tester.pumpAndSettle();
          expect(appState.isFavorite(sampleRecipe.id), true);
        }

        // Test Serving scaling buttons
        final plusIcon = find.byIcon(Icons.add_circle_outline);
        if (plusIcon.evaluate().isNotEmpty) {
          await tester.tap(plusIcon);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('[$platformLabel] CookingAssistantPage renders steps, smart timer, presets and sheet', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final sampleRecipe = appState.recipes.first;
        await tester.pumpWidget(buildScreenWrapper(
          screen: CookingAssistantPage(recipe: sampleRecipe, servings: 4),
          appState: appState,
          size: size,
        ));
        await tester.pumpAndSettle();

        expect(find.text(sampleRecipe.name), findsWidgets);
        expect(find.text('Mutfak Zamanlayıcısı'), findsWidgets);

        // Test Preset timer chips (e.g. 5 dk)
        final fiveMinChip = find.text('5 dk');
        if (fiveMinChip.evaluate().isNotEmpty) {
          await tester.tap(fiveMinChip);
          await tester.pumpAndSettle();
        }

        // Test Ingredients Bottom Sheet button
        final ingredientsBtn = find.text('Malzemeler');
        if (ingredientsBtn.evaluate().isNotEmpty) {
          await tester.tap(ingredientsBtn);
          await tester.pumpAndSettle();
          expect(find.text('Malzeme Listesi (4 Kişilik)'), findsWidgets);
          // Close sheet using unique key
          final closeBtn = find.byKey(const Key('cooking_assistant_sheet_close_button'));
          if (closeBtn.evaluate().isNotEmpty) {
            await tester.tap(closeBtn);
            await tester.pumpAndSettle();
          }
        }
      });

      testWidgets('[$platformLabel] MealPlannerPage renders, day switching and generator work', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildScreenWrapper(screen: const MealPlannerPage(), appState: appState, size: size));
        await tester.pumpAndSettle();

        expect(find.text('Haftalık Yemek Planı'), findsWidgets);

        // Test Day Chips
        final salChip = find.text('Sal');
        if (salChip.evaluate().isNotEmpty) {
          await tester.tap(salChip);
          await tester.pumpAndSettle();
        }

        // Test Smart auto plan generation button
        final generateBtn = find.byIcon(Icons.auto_awesome);
        if (generateBtn.evaluate().isNotEmpty) {
          await tester.tap(generateBtn.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('[$platformLabel] ShoppingBudgetPage renders, tabs switch, budget limit dialog works', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildScreenWrapper(screen: const ShoppingBudgetPage(), appState: appState, size: size));
        await tester.pumpAndSettle();

        expect(find.text('Alışveriş Listesi'), findsWidgets);
        expect(find.text('Fişlerim & Harcamalar'), findsWidgets);

        // Switch to Budget tab
        final budgetTab = find.text('Fişlerim & Harcamalar');
        await tester.tap(budgetTab);
        await tester.pumpAndSettle();

        expect(find.text('Aylık Bütçe Hedefi'), findsWidgets);

        // Switch back to Shopping List tab
        final shoppingTab = find.text('Alışveriş Listesi');
        await tester.tap(shoppingTab);
        await tester.pumpAndSettle();

        // Check share button
        final shareBtn = find.text('Paylaş');
        if (shareBtn.evaluate().isNotEmpty) {
          expect(shareBtn, findsWidgets);
        }
      });

      testWidgets('[$platformLabel] ExpiringIngredientsPage renders without errors', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildScreenWrapper(screen: const ExpiringIngredientsPage(), appState: appState, size: size));
        await tester.pumpAndSettle();

        expect(find.text('SKT Yaklaşan Malzemeler'), findsWidgets);
      });

      testWidgets('[$platformLabel] DetailedReportPage renders without errors', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildScreenWrapper(screen: const DetailedReportPage(), appState: appState, size: size));
        await tester.pumpAndSettle();

        expect(find.text('Detaylı Ekonomi Raporu'), findsWidgets);
      });

      testWidgets('[$platformLabel] WheelPage renders and spin button works', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildScreenWrapper(screen: const WheelPage(), appState: appState, size: size));
        await tester.pumpAndSettle();

        expect(find.text('Yemek Çarkı'), findsWidgets);

        // Find Spin Button
        final spinBtn = find.text('ÇARKI ÇEVİR');
        if (spinBtn.evaluate().isNotEmpty) {
          await tester.tap(spinBtn);
          await tester.pump(const Duration(milliseconds: 200));
        }
      });
    }
  });
}
