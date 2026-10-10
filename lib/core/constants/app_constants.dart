class AppConstants {
  static const String appName = 'TarifMatik';
  static const int defaultPersonCount = 2;
  static const double defaultMonthlyBudgetLimit = 5000.0;
  static const int expiryWarningDaysThreshold = 3;

  // Measurement Units
  static const List<String> units = [
    'adet',
    'kg',
    'g',
    'litre',
    'ml',
    'paket',
    'kaşık',
    'diş',
    'bağ',
    'dilim',
    'su bardağı',
    'çay bardağı',
    'tatlı kaşığı',
    'çay kaşığı',
    'çorba kaşığı',
  ];

  // Shopping Categories
  static const List<String> shoppingCategories = [
    'Sebze/Meyve',
    'Süt Ürünleri',
    'Et & Şarküteri',
    'Kuru Gıda',
    'Tatlı',
    'İçecek',
    'Fırın & Unlu Mamül',
    'Temizlik',
    'Diğer',
  ];

  // Meal Categories
  static const List<String> mealCategories = [
    'Kahvaltı',
    'Öğle Yemeği',
    'Akşam Yemeği',
    'Tatlı',
    'İçecek',
    'Salata',
    'Çorba',
  ];

  // Dietary Filters
  static const List<String> dietaryFilters = [
    'Hepsi',
    'Favorilerim ❤️',
    '⚡ 15 Dk Altı',
    '🌱 Vejetaryen',
    '🌾 Glutensiz',
    '🥛 Laktozsuz',
    '🥗 Diyet/Hafif',
    'Kahvaltı',
    'Öğle Yemeği',
    'Akşam Yemeği',
    'Tatlı',
    'İçecek',
  ];

  // Days of the week in Turkish
  static const List<String> daysOfWeek = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  static const Map<int, String> weekdaysTurkish = {
    1: 'Pazartesi',
    2: 'Salı',
    3: 'Çarşamba',
    4: 'Perşembe',
    5: 'Cuma',
    6: 'Cumartesi',
    7: 'Pazar',
  };
}
