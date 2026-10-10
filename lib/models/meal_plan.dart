import 'recipe.dart';

class DailyMealPlan {
  final String day; // 'Pazartesi', 'Salı', etc.
  Recipe? breakfastMeal;
  Recipe? lunchMeal;
  Recipe? dinnerMeal;
  bool breakfastCooked;
  bool lunchCooked;
  bool dinnerCooked;

  DailyMealPlan({
    required this.day,
    this.breakfastMeal,
    this.lunchMeal,
    this.dinnerMeal,
    this.breakfastCooked = false,
    this.lunchCooked = false,
    this.dinnerCooked = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'breakfastMeal': breakfastMeal?.toJson(),
      'lunchMeal': lunchMeal?.toJson(),
      'dinnerMeal': dinnerMeal?.toJson(),
      'breakfastCooked': breakfastCooked,
      'lunchCooked': lunchCooked,
      'dinnerCooked': dinnerCooked,
    };
  }

  factory DailyMealPlan.fromJson(Map<String, dynamic> json, List<Recipe> availableRecipes) {
    Recipe? getRecipe(Map<String, dynamic>? recipeJson) {
      if (recipeJson == null) return null;
      String id = recipeJson['id'] as String;
      // Try to find the matching recipe in our official database first to ensure sync,
      // otherwise recreate it.
      return availableRecipes.firstWhere(
        (r) => r.id == id,
        orElse: () => Recipe.fromJson(recipeJson),
      );
    }

    return DailyMealPlan(
      day: json['day'] as String,
      breakfastMeal: getRecipe(json['breakfastMeal'] as Map<String, dynamic>?),
      lunchMeal: getRecipe(json['lunchMeal'] as Map<String, dynamic>?),
      dinnerMeal: getRecipe(json['dinnerMeal'] as Map<String, dynamic>?),
      breakfastCooked: json['breakfastCooked'] as bool? ?? false,
      lunchCooked: json['lunchCooked'] as bool? ?? false,
      dinnerCooked: json['dinnerCooked'] as bool? ?? false,
    );
  }
}
