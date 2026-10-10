import '../../core/constants/storage_keys.dart';
import '../../models/recipe.dart';
import '../datasources/local_storage_datasource.dart';
import '../recipe_data.dart';

class RecipeRepository {
  final LocalStorageDatasource _storage;

  RecipeRepository({LocalStorageDatasource? storage})
      : _storage = storage ?? LocalStorageDatasource();

  Future<List<Recipe>> loadRecipes() async {
    final dynamic decoded = await _storage.getJson(StorageKeys.recipesData);
    if (decoded != null && decoded is List) {
      try {
        return decoded.map((item) => Recipe.fromJson(item as Map<String, dynamic>)).toList();
      } catch (_) {
        return RecipeData.getAuthenticRecipes();
      }
    }
    final initial = RecipeData.getAuthenticRecipes();
    await saveRecipes(initial);
    return initial;
  }

  Future<void> saveRecipes(List<Recipe> recipes) async {
    final list = recipes.map((r) => r.toJson()).toList();
    await _storage.setJson(StorageKeys.recipesData, list);
  }

  Future<Set<String>> loadFavorites(String username) async {
    final list = await _storage.getStringList(StorageKeys.favorites(username));
    return (list ?? []).toSet();
  }

  Future<void> saveFavorites(String username, Set<String> favorites) async {
    await _storage.setStringList(StorageKeys.favorites(username), favorites.toList());
  }
}
