import 'ingredient.dart';

class Recipe {
  final String id;
  final String name;
  final String category; // 'Kahvaltı', 'Öğle Yemeği', 'Akşam Yemeği'
  final int durationMinutes;
  final int baseServings;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final String emoji; // We can use emojis as clean indicators (e.g. 🍳, 🍲, 🥗)

  Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.durationMinutes,
    required this.baseServings,
    required this.ingredients,
    required this.instructions,
    required this.emoji,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'durationMinutes': durationMinutes,
      'baseServings': baseServings,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'instructions': instructions,
      'emoji': emoji,
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      durationMinutes: json['durationMinutes'] as int,
      baseServings: json['baseServings'] as int,
      ingredients: (json['ingredients'] as List)
          .map((i) => Ingredient.fromJson(i as Map<String, dynamic>))
          .toList(),
      instructions: List<String>.from(json['instructions'] as List),
      emoji: json['emoji'] as String,
    );
  }

  // Returns ingredients scaled to a target serving count
  List<Ingredient> getScaledIngredients(int targetServings) {
    double scaleFactor = targetServings / baseServings;
    return ingredients.map((ing) {
      return ing.copyWith(amount: ing.amount * scaleFactor);
    }).toList();
  }
}
