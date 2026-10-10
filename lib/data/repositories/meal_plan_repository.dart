import '../../core/constants/app_constants.dart';
import '../../core/constants/storage_keys.dart';
import '../../models/meal_plan.dart';
import '../../models/recipe.dart';
import '../datasources/local_storage_datasource.dart';

class MealPlanRepository {
  final LocalStorageDatasource _storage;

  MealPlanRepository({LocalStorageDatasource? storage})
      : _storage = storage ?? LocalStorageDatasource();

  List<DailyMealPlan> getInitialWeeklyPlan() {
    return AppConstants.daysOfWeek.map((day) => DailyMealPlan(day: day)).toList();
  }

  Future<List<DailyMealPlan>> loadWeeklyPlan(String username, List<Recipe> recipes) async {
    final dynamic decoded = await _storage.getJson(StorageKeys.weeklyPlanData(username));
    if (decoded != null && decoded is List) {
      try {
        return decoded.map((item) => DailyMealPlan.fromJson(item as Map<String, dynamic>, recipes)).toList();
      } catch (_) {
        return getInitialWeeklyPlan();
      }
    }
    return getInitialWeeklyPlan();
  }

  Future<void> saveWeeklyPlan(String username, List<DailyMealPlan> plan) async {
    final list = plan.map((p) => p.toJson()).toList();
    await _storage.setJson(StorageKeys.weeklyPlanData(username), list);
  }
}
