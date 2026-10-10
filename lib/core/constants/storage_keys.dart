class StorageKeys {
  static const String themeMode = 'theme_mode';
  static const String usersData = 'users_data';
  static const String recipesData = 'recipes_data_v3';
  static const String loggedInUsername = 'logged_in_username';

  // User-specific key generators
  static String pantryData(String username) => 'pantry_data_$username';
  static String weeklyPlanData(String username) => 'weekly_plan_data_$username';
  static String shoppingListData(String username) => 'shopping_list_data_$username';
  static String receiptsData(String username) => 'receipts_data_$username';
  static String personCount(String username) => 'person_count_$username';
  static String favorites(String username) => 'favorites_$username';
  static String budgetLimit(String username) => 'budget_limit_$username';
}
