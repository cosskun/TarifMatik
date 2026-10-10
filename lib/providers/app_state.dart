import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/storage_keys.dart';
import '../core/utils/formatters.dart';
import '../data/datasources/local_storage_datasource.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/pantry_repository.dart';
import '../data/repositories/recipe_repository.dart';
import '../data/repositories/meal_plan_repository.dart';
import '../data/repositories/shopping_budget_repository.dart';
import '../domain/services/recipe_matching_engine.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/meal_plan.dart';
import '../models/user.dart';
import '../models/shopping_item.dart';
import '../models/receipt.dart';

class AppState extends ChangeNotifier {
  // Repositories & Datasources
  final LocalStorageDatasource _storage;
  final AuthRepository _authRepo;
  final PantryRepository _pantryRepo;
  final RecipeRepository _recipeRepo;
  final MealPlanRepository _mealPlanRepo;
  final ShoppingBudgetRepository _shoppingBudgetRepo;

  // Reactive State
  List<Ingredient> _pantry = [];
  List<Recipe> _recipes = [];
  List<DailyMealPlan> _weeklyPlan = [];
  int _personCount = AppConstants.defaultPersonCount;
  bool _isLoading = false;

  AppUser? _currentUser;
  List<AppUser> _users = [];
  List<ShoppingItem> _shoppingList = [];
  List<Receipt> _receipts = [];

  ThemeMode _themeMode = ThemeMode.light;
  Set<String> _favoriteRecipeIds = {};
  double _monthlyBudgetLimit = AppConstants.defaultMonthlyBudgetLimit;

  // Getters
  List<Ingredient> get pantry => _pantry;
  List<Recipe> get recipes => _recipes;
  List<DailyMealPlan> get weeklyPlan => _weeklyPlan;
  int get personCount => _personCount;
  bool get isLoading => _isLoading;
  AppUser? get currentUser => _currentUser;
  List<AppUser> get users => _users;
  List<ShoppingItem> get shoppingList => _shoppingList;
  List<Receipt> get receipts => _receipts;
  ThemeMode get themeMode => _themeMode;
  Set<String> get favoriteRecipeIds => _favoriteRecipeIds;
  double get monthlyBudgetLimit => _monthlyBudgetLimit;
  bool isFavorite(String recipeId) => _favoriteRecipeIds.contains(recipeId);

  AppState({
    LocalStorageDatasource? storage,
    AuthRepository? authRepo,
    PantryRepository? pantryRepo,
    RecipeRepository? recipeRepo,
    MealPlanRepository? mealPlanRepo,
    ShoppingBudgetRepository? shoppingBudgetRepo,
  })  : _storage = storage ?? LocalStorageDatasource(),
        _authRepo = authRepo ?? AuthRepository(),
        _pantryRepo = pantryRepo ?? PantryRepository(),
        _recipeRepo = recipeRepo ?? RecipeRepository(),
        _mealPlanRepo = mealPlanRepo ?? MealPlanRepository(),
        _shoppingBudgetRepo = shoppingBudgetRepo ?? ShoppingBudgetRepository() {
    _initData();
  }

  String capitalize(String name) => Formatters.capitalize(name);

  // --- INITIALIZATION ---
  Future<void> _initData() async {
    _isLoading = true;
    notifyListeners();

    // 1. Load ThemeMode
    final themeStr = await _storage.getString(StorageKeys.themeMode);
    _themeMode = (themeStr == 'dark') ? ThemeMode.dark : ThemeMode.light;

    // 2. Load Users
    _users = await _authRepo.loadUsers();

    // 3. Load Recipes
    _recipes = await _recipeRepo.loadRecipes();

    // 4. Load Current User Session
    final currentUsername = await _authRepo.getLoggedInUsername();
    if (currentUsername != null) {
      final userIndex = _users.indexWhere((u) => u.username == currentUsername);
      if (userIndex >= 0) {
        _currentUser = _users[userIndex];
        await _loadUserData(_currentUser!.username);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserData(String username) async {
    _personCount = (await _storage.getInt(StorageKeys.personCount(username))) ?? AppConstants.defaultPersonCount;
    _pantry = await _pantryRepo.loadPantry(username);
    _weeklyPlan = await _mealPlanRepo.loadWeeklyPlan(username, _recipes);
    _shoppingList = await _shoppingBudgetRepo.loadShoppingList(username);
    _receipts = await _shoppingBudgetRepo.loadReceipts(username);
    _favoriteRecipeIds = await _recipeRepo.loadFavorites(username);
    _monthlyBudgetLimit = await _shoppingBudgetRepo.loadBudgetLimit(username);
  }

  // --- THEME ACTIONS ---
  Future<void> toggleThemeMode() async {
    _themeMode = (_themeMode == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
    await _storage.setString(StorageKeys.themeMode, _themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  // --- FAVORITES ACTIONS ---
  Future<void> toggleFavorite(String recipeId) async {
    if (_favoriteRecipeIds.contains(recipeId)) {
      _favoriteRecipeIds.remove(recipeId);
    } else {
      _favoriteRecipeIds.add(recipeId);
    }
    notifyListeners();

    if (_currentUser != null) {
      await _recipeRepo.saveFavorites(_currentUser!.username, _favoriteRecipeIds);
    }
  }

  // --- BUDGET LIMIT ACTIONS ---
  Future<void> setMonthlyBudgetLimit(double limit) async {
    _monthlyBudgetLimit = limit;
    notifyListeners();

    if (_currentUser != null) {
      await _shoppingBudgetRepo.saveBudgetLimit(_currentUser!.username, limit);
    }
  }

  // --- AUTH ACTIONS ---
  Future<bool> login(String username, String password) async {
    final userIndex = _users.indexWhere(
      (u) => u.username.trim().toLowerCase() == username.trim().toLowerCase() && u.password == password,
    );
    if (userIndex >= 0) {
      _currentUser = _users[userIndex];
      await _loadUserData(_currentUser!.username);
      await _authRepo.setLoggedInUsername(_currentUser!.username);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String username, String password, {String role = 'member'}) async {
    final exists = _users.any(
      (u) => u.username.trim().toLowerCase() == username.trim().toLowerCase(),
    );
    if (exists) return false;

    final newUser = AppUser(
      username: username.trim(),
      password: password,
      role: role,
    );
    _users.add(newUser);
    await _authRepo.saveUsers(_users);

    _currentUser = newUser;
    await _loadUserData(_currentUser!.username);
    await _authRepo.setLoggedInUsername(_currentUser!.username);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    _pantry = [];
    _weeklyPlan = [];
    _shoppingList = [];
    _receipts = [];
    _favoriteRecipeIds = {};
    _monthlyBudgetLimit = AppConstants.defaultMonthlyBudgetLimit;
    await _authRepo.setLoggedInUsername(null);
    notifyListeners();
  }

  Future<void> updateUserRole(String username, String newRole) async {
    final index = _users.indexWhere((u) => u.username == username);
    if (index >= 0) {
      _users[index].role = newRole;
      await _authRepo.saveUsers(_users);
      if (_currentUser != null && _currentUser!.username == username) {
        _currentUser!.role = newRole;
      }
      notifyListeners();
    }
  }

  // --- GLOBAL RECIPE ACTIONS ---
  Future<void> updateRecipe(Recipe updatedRecipe) async {
    final index = _recipes.indexWhere((r) => r.id == updatedRecipe.id);
    if (index >= 0) {
      _recipes[index] = updatedRecipe;
      await _recipeRepo.saveRecipes(_recipes);
      notifyListeners();
    }
  }

  Future<void> addRecipe(Recipe newRecipe) async {
    _recipes.add(newRecipe);
    await _recipeRepo.saveRecipes(_recipes);
    notifyListeners();
  }

  Future<void> deleteRecipe(String recipeId) async {
    _recipes.removeWhere((r) => r.id == recipeId);
    await _recipeRepo.saveRecipes(_recipes);
    notifyListeners();
  }

  // --- USER SETTINGS ---
  Future<void> savePersonCount(int count) async {
    _personCount = count;
    notifyListeners();
    if (_currentUser == null) return;
    await _storage.setInt(StorageKeys.personCount(_currentUser!.username), count);
  }

  Future<void> _savePantry() async {
    if (_currentUser == null) return;
    await _pantryRepo.savePantry(_currentUser!.username, _pantry);
  }

  Future<void> _saveWeeklyPlan() async {
    if (_currentUser == null) return;
    await _mealPlanRepo.saveWeeklyPlan(_currentUser!.username, _weeklyPlan);
  }

  // --- PANTRY MUTATIONS ---
  void addPantryIngredient(Ingredient ingredient) {
    final cleanName = Formatters.capitalize(ingredient.name);
    final cleanIngredient = Ingredient(
      name: cleanName,
      amount: ingredient.amount,
      unit: ingredient.unit,
      expiryDate: ingredient.expiryDate,
    );

    final existingIndex = _pantry.indexWhere(
      (i) => i.name.trim().toLowerCase() == cleanName.toLowerCase(),
    );

    if (existingIndex >= 0) {
      _pantry[existingIndex].amount += cleanIngredient.amount;
      if (cleanIngredient.expiryDate != null) {
        _pantry[existingIndex].expiryDate = cleanIngredient.expiryDate;
      }
    } else {
      _pantry.add(cleanIngredient);
    }
    _savePantry();
    notifyListeners();
  }

  void updatePantryIngredient(String name, double amount, DateTime? expiryDate) {
    final cleanName = Formatters.capitalize(name);
    final index = _pantry.indexWhere(
      (i) => i.name.trim().toLowerCase() == cleanName.toLowerCase(),
    );
    if (index >= 0) {
      if (amount <= 0) {
        _pantry.removeAt(index);
      } else {
        _pantry[index].amount = amount;
        _pantry[index].expiryDate = expiryDate;
      }
      _savePantry();
      notifyListeners();
    }
  }

  void updatePantryIngredientAmount(String name, double amount) {
    final cleanName = Formatters.capitalize(name);
    final index = _pantry.indexWhere(
      (i) => i.name.trim().toLowerCase() == cleanName.toLowerCase(),
    );
    if (index >= 0) {
      if (amount <= 0) {
        _pantry.removeAt(index);
      } else {
        _pantry[index].amount = amount;
      }
      _savePantry();
      notifyListeners();
    }
  }

  void removePantryIngredient(String name) {
    final cleanName = Formatters.capitalize(name);
    _pantry.removeWhere((i) => i.name.trim().toLowerCase() == cleanName.toLowerCase());
    _savePantry();
    notifyListeners();
  }

  Future<void> addOrUpdatePantryIngredient(
    String name,
    double amount,
    String unit, {
    DateTime? expiryDate,
  }) async {
    final capitalized = Formatters.capitalize(name);
    final existingIndex = _pantry.indexWhere(
      (p) => p.name.trim().toLowerCase() == capitalized.trim().toLowerCase(),
    );

    if (existingIndex >= 0) {
      _pantry[existingIndex].amount += amount;
      if (expiryDate != null) {
        _pantry[existingIndex].expiryDate = expiryDate;
      }
    } else {
      _pantry.add(Ingredient(
        name: capitalized,
        amount: amount,
        unit: unit,
        expiryDate: expiryDate,
      ));
    }
    await _savePantry();
    notifyListeners();
  }

  // --- MEAL PLANNING ---
  void planMeal(String day, String category, Recipe? recipe) {
    final dayPlan = _weeklyPlan.firstWhere((p) => p.day == day);
    if (category == 'Kahvaltı') {
      dayPlan.breakfastMeal = recipe;
      dayPlan.breakfastCooked = false;
    } else if (category == 'Öğle Yemeği') {
      dayPlan.lunchMeal = recipe;
      dayPlan.lunchCooked = false;
    } else if (category == 'Akşam Yemeği') {
      dayPlan.dinnerMeal = recipe;
      dayPlan.dinnerCooked = false;
    }
    _saveWeeklyPlan();
    notifyListeners();
  }

  bool cookMeal(Recipe recipe, int servings) {
    final scaledIngredients = recipe.getScaledIngredients(servings);
    for (var reqIng in scaledIngredients) {
      final pantryIndex = _pantry.indexWhere(
        (pi) => pi.name.trim().toLowerCase() == reqIng.name.trim().toLowerCase(),
      );

      if (pantryIndex >= 0) {
        double currentAmount = _pantry[pantryIndex].amount;
        double newAmount = currentAmount - reqIng.amount;
        _pantry[pantryIndex].amount = newAmount < 0 ? 0 : newAmount;
      }
    }

    _savePantry();
    notifyListeners();
    return true;
  }

  void markPlannedMealAsCooked(String day, String category) {
    final dayPlan = _weeklyPlan.firstWhere((p) => p.day == day);
    Recipe? recipe;
    bool isAlreadyCooked = false;

    if (category == 'Kahvaltı') {
      recipe = dayPlan.breakfastMeal;
      isAlreadyCooked = dayPlan.breakfastCooked;
      if (recipe != null && !isAlreadyCooked) {
        cookMeal(recipe, _personCount);
        dayPlan.breakfastCooked = true;
      }
    } else if (category == 'Öğle Yemeği') {
      recipe = dayPlan.lunchMeal;
      isAlreadyCooked = dayPlan.lunchCooked;
      if (recipe != null && !isAlreadyCooked) {
        cookMeal(recipe, _personCount);
        dayPlan.lunchCooked = true;
      }
    } else if (category == 'Akşam Yemeği') {
      recipe = dayPlan.dinnerMeal;
      isAlreadyCooked = dayPlan.dinnerCooked;
      if (recipe != null && !isAlreadyCooked) {
        cookMeal(recipe, _personCount);
        dayPlan.dinnerCooked = true;
      }
    }

    _saveWeeklyPlan();
    notifyListeners();
  }

  void clearWeeklyPlan() {
    _weeklyPlan = _mealPlanRepo.getInitialWeeklyPlan();
    _saveWeeklyPlan();
    notifyListeners();
  }

  void generateSmartWeeklyPlan() {
    final random = math.Random();

    for (var dayPlan in _weeklyPlan) {
      Recipe? pickRecipeForCategory(String category) {
        final categoryRecipes = _recipes.where((r) => r.category == category).toList();
        if (categoryRecipes.isEmpty) return null;

        final expiringHighMatch = categoryRecipes.where((r) {
          final score = getRecipeMatchScore(r, _personCount);
          final hasExpiring = getExpiringIngredientsInRecipe(r).isNotEmpty;
          return score >= 0.70 && hasExpiring;
        }).toList();

        if (expiringHighMatch.isNotEmpty) {
          return expiringHighMatch[random.nextInt(expiringHighMatch.length)];
        }

        final highMatch = categoryRecipes.where((r) {
          return getRecipeMatchScore(r, _personCount) >= 0.70;
        }).toList();

        if (highMatch.isNotEmpty) {
          return highMatch[random.nextInt(highMatch.length)];
        }

        return categoryRecipes[random.nextInt(categoryRecipes.length)];
      }

      dayPlan.breakfastMeal = pickRecipeForCategory('Kahvaltı');
      dayPlan.breakfastCooked = false;
      dayPlan.lunchMeal = pickRecipeForCategory('Öğle Yemeği');
      dayPlan.lunchCooked = false;
      dayPlan.dinnerMeal = pickRecipeForCategory('Akşam Yemeği');
      dayPlan.dinnerCooked = false;
    }

    _saveWeeklyPlan();
    notifyListeners();
  }

  // --- RECIPE MATCHING DELEGATION ---
  double getRecipeMatchScore(Recipe recipe, int servings) {
    return RecipeMatchingEngine.calculateMatchScore(recipe, _pantry, servings);
  }

  List<Ingredient> getMissingIngredients(Recipe recipe, int servings) {
    return RecipeMatchingEngine.calculateMissingIngredients(recipe, _pantry, servings);
  }

  List<Ingredient> getExpiringPantryIngredients() {
    return RecipeMatchingEngine.getExpiringPantryIngredients(_pantry);
  }

  List<Ingredient> getExpiringIngredientsInRecipe(Recipe recipe) {
    return RecipeMatchingEngine.getExpiringIngredientsInRecipe(recipe, _pantry);
  }

  // --- SHOPPING LIST ACTIONS ---
  Future<void> addShoppingItem(String name, double amount, String unit, String category) async {
    if (_currentUser == null) return;
    final capitalizedName = Formatters.capitalize(name);
    final newItem = ShoppingItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(100)}',
      name: capitalizedName,
      amount: amount,
      unit: unit,
      category: category,
    );
    _shoppingList.add(newItem);
    await _shoppingBudgetRepo.saveShoppingList(_currentUser!.username, _shoppingList);
    notifyListeners();
  }

  Future<void> toggleShoppingItem(String id) async {
    if (_currentUser == null) return;
    final idx = _shoppingList.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      _shoppingList[idx] = _shoppingList[idx].copyWith(isBought: !_shoppingList[idx].isBought);
      await _shoppingBudgetRepo.saveShoppingList(_currentUser!.username, _shoppingList);
      notifyListeners();
    }
  }

  Future<void> deleteShoppingItem(String id) async {
    if (_currentUser == null) return;
    _shoppingList.removeWhere((i) => i.id == id);
    await _shoppingBudgetRepo.saveShoppingList(_currentUser!.username, _shoppingList);
    notifyListeners();
  }

  Future<void> clearShoppingList() async {
    if (_currentUser == null) return;
    _shoppingList.clear();
    await _shoppingBudgetRepo.saveShoppingList(_currentUser!.username, _shoppingList);
    notifyListeners();
  }

  Future<void> completeShoppingItemAndPantryTransfer(
    String id,
    double finalAmount,
    double price,
    DateTime? expiryDate,
  ) async {
    if (_currentUser == null) return;
    final idx = _shoppingList.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      final item = _shoppingList[idx];
      _shoppingList[idx] = item.copyWith(
        isBought: true,
        amount: finalAmount,
        price: price,
      );

      await addOrUpdatePantryIngredient(item.name, finalAmount, item.unit, expiryDate: expiryDate);
      await _shoppingBudgetRepo.saveShoppingList(_currentUser!.username, _shoppingList);
      notifyListeners();
    }
  }

  // --- RECEIPTS & BUDGET ACTIONS ---
  Future<void> addReceipt(String storeName, DateTime date, List<ShoppingItem> items, double totalAmount) async {
    if (_currentUser == null) return;
    final newReceipt = Receipt(
      id: '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(100)}',
      storeName: storeName,
      date: date,
      items: items,
      totalAmount: totalAmount,
    );
    _receipts.insert(0, newReceipt);
    await _shoppingBudgetRepo.saveReceipts(_currentUser!.username, _receipts);
    notifyListeners();
  }

  Future<void> deleteReceipt(String id) async {
    if (_currentUser == null) return;
    _receipts.removeWhere((r) => r.id == id);
    await _shoppingBudgetRepo.saveReceipts(_currentUser!.username, _receipts);
    notifyListeners();
  }

  double getMonthlyTotalSpending(int year, int month) {
    double total = 0.0;
    for (var r in _receipts) {
      if (r.date.year == year && r.date.month == month) {
        total += r.totalAmount;
      }
    }
    return total;
  }

  double getWeeklyTotalSpending() {
    double total = 0.0;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    for (var r in _receipts) {
      if (r.date.isAfter(sevenDaysAgo)) {
        total += r.totalAmount;
      }
    }
    return total;
  }

  Map<String, double> getCategorySpendingBreakdown(int year, int month) {
    final Map<String, double> breakdown = {};
    for (var r in _receipts) {
      if (r.date.year == year && r.date.month == month) {
        for (var item in r.items) {
          final cat = item.category;
          breakdown[cat] = (breakdown[cat] ?? 0.0) + item.price;
        }
      }
    }
    return breakdown;
  }

  Map<String, double> getProductSpendingBreakdown(int year, int month) {
    final Map<String, double> breakdown = {};
    for (var r in _receipts) {
      if (r.date.year == year && r.date.month == month) {
        for (var item in r.items) {
          final name = item.name;
          breakdown[name] = (breakdown[name] ?? 0.0) + item.price;
        }
      }
    }
    return breakdown;
  }
}
