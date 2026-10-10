import '../../core/constants/app_constants.dart';
import '../../models/ingredient.dart';
import '../../models/recipe.dart';

class RecipeMatchingEngine {
  /// Calculates compatibility score (0.0 to 1.0) based on how many ingredients exist in the pantry in sufficient quantity
  static double calculateMatchScore(Recipe recipe, List<Ingredient> pantry, int servings) {
    final scaledIngredients = recipe.getScaledIngredients(servings);
    if (scaledIngredients.isEmpty) return 1.0;

    int matchedCount = 0;
    for (var reqIng in scaledIngredients) {
      final pantryItem = pantry.firstWhere(
        (pi) => pi.name.trim().toLowerCase() == reqIng.name.trim().toLowerCase(),
        orElse: () => Ingredient(name: '', amount: 0, unit: ''),
      );

      if (pantryItem.name.isNotEmpty && pantryItem.amount >= reqIng.amount) {
        matchedCount++;
      }
    }

    return matchedCount / scaledIngredients.length;
  }

  /// Returns list of missing ingredients for a recipe given the pantry stock
  static List<Ingredient> calculateMissingIngredients(Recipe recipe, List<Ingredient> pantry, int servings) {
    final scaledIngredients = recipe.getScaledIngredients(servings);
    List<Ingredient> missing = [];

    for (var reqIng in scaledIngredients) {
      final pantryItem = pantry.firstWhere(
        (pi) => pi.name.trim().toLowerCase() == reqIng.name.trim().toLowerCase(),
        orElse: () => Ingredient(name: '', amount: 0, unit: ''),
      );

      if (pantryItem.name.isEmpty) {
        missing.add(reqIng);
      } else if (pantryItem.amount < reqIng.amount) {
        missing.add(Ingredient(
          name: reqIng.name,
          amount: reqIng.amount - pantryItem.amount,
          unit: reqIng.unit,
        ));
      }
    }

    return missing;
  }

  /// Returns list of pantry items expiring in <= daysThreshold days
  static List<Ingredient> getExpiringPantryIngredients(
    List<Ingredient> pantry, {
    int daysThreshold = AppConstants.expiryWarningDaysThreshold,
  }) {
    final now = DateTime.now();
    return pantry.where((item) {
      if (item.expiryDate == null || item.amount <= 0) return false;
      final difference = item.expiryDate!.difference(now).inDays;
      return difference >= 0 && difference <= daysThreshold;
    }).toList();
  }

  /// Returns ingredients of a recipe that are expiring soon in the pantry
  static List<Ingredient> getExpiringIngredientsInRecipe(
    Recipe recipe,
    List<Ingredient> pantry, {
    int daysThreshold = AppConstants.expiryWarningDaysThreshold,
  }) {
    final now = DateTime.now();
    List<Ingredient> expiring = [];
    for (var reqIng in recipe.ingredients) {
      final pantryItem = pantry.firstWhere(
        (pi) => pi.name.trim().toLowerCase() == reqIng.name.trim().toLowerCase(),
        orElse: () => Ingredient(name: '', amount: 0, unit: ''),
      );
      if (pantryItem.name.isNotEmpty && pantryItem.expiryDate != null) {
        final difference = pantryItem.expiryDate!.difference(now).inDays;
        if (difference >= 0 && difference <= daysThreshold) {
          expiring.add(pantryItem);
        }
      }
    }
    return expiring;
  }

  /// Evaluates dietary and lifestyle filter conditions
  static bool matchesDietaryFilter(
    Recipe recipe,
    String filter, {
    Set<String> favoriteIds = const {},
  }) {
    if (filter == 'Hepsi') return true;
    if (filter == 'Favorilerim ❤️') {
      return favoriteIds.contains(recipe.id);
    }
    if (filter == '⚡ 15 Dk Altı') {
      return recipe.durationMinutes <= 15;
    }
    if (filter == '🌱 Vejetaryen') {
      const nonVeg = [
        'kıyma',
        'tavuk',
        'et',
        'sucuk',
        'pastırma',
        'balık',
        'köfte',
        'bonfile',
        'kuşbaşı',
        'jambon',
        'hindi',
        'ton balığı',
      ];
      return !recipe.ingredients.any((i) => nonVeg.any((nv) => i.name.toLowerCase().contains(nv)));
    }
    if (filter == '🌾 Glutensiz') {
      const gluten = [
        'un',
        'makarna',
        'bulgur',
        'şehriye',
        'irmik',
        'ekmek',
        'yufka',
        'galeta',
        'bisküvi',
        'erişte',
        'kadayıf',
        'kemalpaşa',
      ];
      return !recipe.ingredients.any((i) => gluten.any((g) => i.name.toLowerCase().contains(g)));
    }
    if (filter == '🥛 Laktozsuz') {
      const dairy = [
        'süt',
        'yoğurt',
        'peynir',
        'kaşar',
        'tereyağı',
        'kaymak',
        'krema',
        'labne',
        'lor',
      ];
      return !recipe.ingredients.any((i) => dairy.any((d) => i.name.toLowerCase().contains(d)));
    }
    if (filter == '🥗 Diyet/Hafif') {
      const lightKeywords = ['salata', 'çorba', 'fit', 'diyet', 'hafif', 'yoğurtlu', 'sebze'];
      return recipe.category == 'Salata' ||
          recipe.category == 'Çorba' ||
          lightKeywords.any((k) => recipe.name.toLowerCase().contains(k)) ||
          (recipe.durationMinutes <= 20 && !recipe.name.toLowerCase().contains('şerbet'));
    }
    return recipe.category == filter;
  }
}
