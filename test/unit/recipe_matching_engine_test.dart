import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_matik/domain/services/recipe_matching_engine.dart';
import 'package:tarif_matik/models/ingredient.dart';
import 'package:tarif_matik/models/recipe.dart';

void main() {
  group('RecipeMatchingEngine Tests', () {
    final testRecipe = Recipe(
      id: 'test_menemen',
      name: 'Menemen',
      category: 'Kahvaltı',
      durationMinutes: 15,
      baseServings: 2,
      emoji: '🍳',
      ingredients: [
        Ingredient(name: 'Yumurta', amount: 3, unit: 'adet'),
        Ingredient(name: 'Domates', amount: 2, unit: 'adet'),
        Ingredient(name: 'Yeşil Biber', amount: 2, unit: 'adet'),
      ],
      instructions: ['Biberleri kavurun', 'Domatesleri ekleyin', 'Yumurtaları kırın'],
    );

    test('calculateMatchScore returns 1.0 when all ingredients are in stock', () {
      final pantry = [
        Ingredient(name: 'Yumurta', amount: 10, unit: 'adet'),
        Ingredient(name: 'Domates', amount: 5, unit: 'adet'),
        Ingredient(name: 'Yeşil Biber', amount: 4, unit: 'adet'),
      ];

      final score = RecipeMatchingEngine.calculateMatchScore(testRecipe, pantry, 2);
      expect(score, 1.0);
    });

    test('calculateMatchScore returns partial score when some ingredients are missing', () {
      final pantry = [
        Ingredient(name: 'Yumurta', amount: 10, unit: 'adet'),
      ];

      final score = RecipeMatchingEngine.calculateMatchScore(testRecipe, pantry, 2);
      expect(score, closeTo(0.333, 0.01));
    });

    test('calculateMissingIngredients accurately identifies missing items', () {
      final pantry = [
        Ingredient(name: 'Yumurta', amount: 10, unit: 'adet'),
        Ingredient(name: 'Domates', amount: 1, unit: 'adet'), // needs 2 for 2 servings
      ];

      final missing = RecipeMatchingEngine.calculateMissingIngredients(testRecipe, pantry, 2);
      expect(missing.length, 2);
      expect(missing.any((m) => m.name == 'Domates' && m.amount == 1.0), isTrue);
      expect(missing.any((m) => m.name == 'Yeşil Biber' && m.amount == 2.0), isTrue);
    });

    test('matchesDietaryFilter correctly filters vegetarian, gluten-free, lactose-free, quick', () {
      expect(
        RecipeMatchingEngine.matchesDietaryFilter(testRecipe, '🌱 Vejetaryen'),
        isTrue,
      );
      expect(
        RecipeMatchingEngine.matchesDietaryFilter(testRecipe, '🌾 Glutensiz'),
        isTrue,
      );
      expect(
        RecipeMatchingEngine.matchesDietaryFilter(testRecipe, '🥛 Laktozsuz'),
        isTrue,
      );
      expect(
        RecipeMatchingEngine.matchesDietaryFilter(testRecipe, '⚡ 15 Dk Altı'),
        isTrue,
      );
      expect(
        RecipeMatchingEngine.matchesDietaryFilter(testRecipe, 'Favorilerim ❤️', favoriteIds: {'test_menemen'}),
        isTrue,
      );
    });

    test('getExpiringPantryIngredients filters items expiring within threshold', () {
      final now = DateTime.now();
      final pantry = [
        Ingredient(name: 'Tavuk Göğsü', amount: 500, unit: 'g', expiryDate: now.add(const Duration(days: 1))),
        Ingredient(name: 'Pirinç', amount: 1000, unit: 'g', expiryDate: now.add(const Duration(days: 100))),
      ];

      final expiring = RecipeMatchingEngine.getExpiringPantryIngredients(pantry, daysThreshold: 3);
      expect(expiring.length, 1);
      expect(expiring.first.name, 'Tavuk Göğsü');
    });
  });
}
