import '../../core/constants/storage_keys.dart';
import '../../models/ingredient.dart';
import '../datasources/local_storage_datasource.dart';

class PantryRepository {
  final LocalStorageDatasource _storage;

  PantryRepository({LocalStorageDatasource? storage})
      : _storage = storage ?? LocalStorageDatasource();

  List<Ingredient> getInitialPantry() {
    final now = DateTime.now();
    return [
      Ingredient(name: 'Kıyma', amount: 500, unit: 'g', expiryDate: now.add(const Duration(days: 2))),
      Ingredient(name: 'Yumurta', amount: 10, unit: 'adet', expiryDate: now.add(const Duration(days: 12))),
      Ingredient(name: 'Domates', amount: 5, unit: 'adet', expiryDate: now.add(const Duration(days: 4))),
      Ingredient(name: 'Yeşil Biber', amount: 8, unit: 'adet', expiryDate: now.add(const Duration(days: 6))),
      Ingredient(name: 'Soğan', amount: 4, unit: 'adet', expiryDate: now.add(const Duration(days: 15))),
      Ingredient(name: 'Sarımsak', amount: 10, unit: 'diş', expiryDate: now.add(const Duration(days: 30))),
      Ingredient(name: 'Patlıcan', amount: 4, unit: 'adet', expiryDate: now.add(const Duration(days: 3))),
      Ingredient(name: 'Tavuk Göğsü', amount: 600, unit: 'g', expiryDate: now.add(const Duration(days: 1))),
      Ingredient(name: 'Pirinç', amount: 1000, unit: 'g', expiryDate: now.add(const Duration(days: 180))),
      Ingredient(name: 'Makarna', amount: 500, unit: 'g', expiryDate: now.add(const Duration(days: 360))),
      Ingredient(name: 'Tereyağı', amount: 250, unit: 'g', expiryDate: now.add(const Duration(days: 20))),
      Ingredient(name: 'Zeytinyağı', amount: 500, unit: 'ml', expiryDate: now.add(const Duration(days: 360))),
      Ingredient(name: 'Domates Salçası', amount: 400, unit: 'g', expiryDate: now.add(const Duration(days: 90))),
      Ingredient(name: 'Un', amount: 1000, unit: 'g', expiryDate: now.add(const Duration(days: 180))),
      Ingredient(name: 'Süt', amount: 1000, unit: 'ml', expiryDate: now.add(const Duration(days: 2))),
      Ingredient(name: 'Kırmızı Mercimek', amount: 500, unit: 'g', expiryDate: now.add(const Duration(days: 270))),
      // Staples
      Ingredient(name: 'Tuz', amount: 500, unit: 'g', expiryDate: now.add(const Duration(days: 360))),
      Ingredient(name: 'Karabiber', amount: 100, unit: 'g', expiryDate: now.add(const Duration(days: 360))),
      Ingredient(name: 'Pul Biber', amount: 100, unit: 'g', expiryDate: now.add(const Duration(days: 360))),
      Ingredient(name: 'Kekik', amount: 100, unit: 'g', expiryDate: now.add(const Duration(days: 360))),
      Ingredient(name: 'Kuru Nane', amount: 100, unit: 'g', expiryDate: now.add(const Duration(days: 360))),
      Ingredient(name: 'Kimyon', amount: 100, unit: 'g', expiryDate: now.add(const Duration(days: 360))),
      Ingredient(name: 'Yenibahar', amount: 100, unit: 'g', expiryDate: now.add(const Duration(days: 360))),
      Ingredient(name: 'Şeker', amount: 1000, unit: 'g', expiryDate: now.add(const Duration(days: 360))),
      Ingredient(name: 'Su', amount: 10000, unit: 'ml', expiryDate: now.add(const Duration(days: 360))),
      Ingredient(name: 'Sıcak Su', amount: 10000, unit: 'ml', expiryDate: now.add(const Duration(days: 360))),
      Ingredient(name: 'Soğuk Su', amount: 10000, unit: 'ml', expiryDate: now.add(const Duration(days: 360))),
      Ingredient(name: 'Buz', amount: 100, unit: 'adet', expiryDate: now.add(const Duration(days: 30))),
      Ingredient(name: 'Vanilya', amount: 50, unit: 'g', expiryDate: now.add(const Duration(days: 360))),
      Ingredient(name: 'Kabartma Tozu', amount: 50, unit: 'g', expiryDate: now.add(const Duration(days: 360))),
      Ingredient(name: 'Kakao', amount: 200, unit: 'g', expiryDate: now.add(const Duration(days: 180))),
      Ingredient(name: 'Nişasta', amount: 300, unit: 'g', expiryDate: now.add(const Duration(days: 180))),
      Ingredient(name: 'Maya', amount: 10, unit: 'paket', expiryDate: now.add(const Duration(days: 90))),
      Ingredient(name: 'Limon', amount: 5, unit: 'adet', expiryDate: now.add(const Duration(days: 15))),
      Ingredient(name: 'Yoğurt', amount: 1000, unit: 'g', expiryDate: now.add(const Duration(days: 7))),
      Ingredient(name: 'Asma Yaprağı', amount: 500, unit: 'g', expiryDate: now.add(const Duration(days: 60))),
      Ingredient(name: 'Yufka', amount: 5, unit: 'adet', expiryDate: now.add(const Duration(days: 5))),
      Ingredient(name: 'Tost Ekmeği', amount: 1, unit: 'paket', expiryDate: now.add(const Duration(days: 5))),
      Ingredient(name: 'Muz', amount: 6, unit: 'adet', expiryDate: now.add(const Duration(days: 4))),
      Ingredient(name: 'Çilek', amount: 500, unit: 'g', expiryDate: now.add(const Duration(days: 3))),
      Ingredient(name: 'Mısır Unu', amount: 500, unit: 'g', expiryDate: now.add(const Duration(days: 180))),
      Ingredient(name: 'Kaşar', amount: 400, unit: 'g', expiryDate: now.add(const Duration(days: 15))),
      Ingredient(name: 'Maydanoz', amount: 1, unit: 'bağ', expiryDate: now.add(const Duration(days: 5))),
      Ingredient(name: 'İrmik', amount: 500, unit: 'g', expiryDate: now.add(const Duration(days: 180))),
      Ingredient(name: 'Çikolata', amount: 200, unit: 'g', expiryDate: now.add(const Duration(days: 120))),
      Ingredient(name: 'Hindistan Cevizi', amount: 100, unit: 'g', expiryDate: now.add(const Duration(days: 180))),
      Ingredient(name: 'Kemalpaşa Tatlısı', amount: 1, unit: 'adet', expiryDate: now.add(const Duration(days: 180))),
      Ingredient(name: 'Nohut', amount: 1000, unit: 'g', expiryDate: now.add(const Duration(days: 360))),
    ];
  }

  Future<List<Ingredient>> loadPantry(String username) async {
    final dynamic decoded = await _storage.getJson(StorageKeys.pantryData(username));
    List<Ingredient> pantry;

    if (decoded != null && decoded is List) {
      try {
        pantry = decoded.map((item) => Ingredient.fromJson(item as Map<String, dynamic>)).toList();
        final initial = getInitialPantry();
        for (var initialItem in initial) {
          bool exists = pantry.any((p) => p.name.trim().toLowerCase() == initialItem.name.trim().toLowerCase());
          if (!exists) {
            pantry.add(initialItem);
          }
        }
      } catch (_) {
        pantry = getInitialPantry();
      }
    } else {
      pantry = getInitialPantry();
    }
    return pantry;
  }

  Future<void> savePantry(String username, List<Ingredient> pantry) async {
    final list = pantry.map((i) => i.toJson()).toList();
    await _storage.setJson(StorageKeys.pantryData(username), list);
  }
}
