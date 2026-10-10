import '../../core/constants/app_constants.dart';
import '../../core/constants/storage_keys.dart';
import '../../models/receipt.dart';
import '../../models/shopping_item.dart';
import '../datasources/local_storage_datasource.dart';

class ShoppingBudgetRepository {
  final LocalStorageDatasource _storage;

  ShoppingBudgetRepository({LocalStorageDatasource? storage})
      : _storage = storage ?? LocalStorageDatasource();

  List<ShoppingItem> getSampleShoppingList() {
    return [
      ShoppingItem(id: 's1', name: 'Süt', amount: 1.0, unit: 'paket', category: 'Süt Ürünleri'),
      ShoppingItem(id: 's2', name: 'Domates', amount: 1.5, unit: 'kg', category: 'Sebze/Meyve'),
      ShoppingItem(id: 's3', name: 'Yumurta', amount: 10.0, unit: 'adet', category: 'Süt Ürünleri'),
      ShoppingItem(id: 's4', name: 'Tavuk Göğsü', amount: 1.0, unit: 'kg', category: 'Et & Şarküteri'),
    ];
  }

  List<Receipt> getSampleReceipts() {
    final now = DateTime.now();
    return [
      Receipt(
        id: 'r1',
        storeName: 'Migros',
        date: now.subtract(const Duration(days: 3)),
        items: [
          ShoppingItem(id: 'r1_i1', name: 'Domates', amount: 1.0, unit: 'kg', price: 35.0, category: 'Sebze/Meyve', isBought: true),
          ShoppingItem(id: 'r1_i2', name: 'Salatalık', amount: 1.0, unit: 'kg', price: 25.0, category: 'Sebze/Meyve', isBought: true),
          ShoppingItem(id: 'r1_i3', name: 'Süt', amount: 2.0, unit: 'paket', price: 60.0, category: 'Süt Ürünleri', isBought: true),
          ShoppingItem(id: 'r1_i4', name: 'Yumurta', amount: 30.0, unit: 'adet', price: 120.0, category: 'Süt Ürünleri', isBought: true),
        ],
        totalAmount: 240.0,
      ),
      Receipt(
        id: 'r2',
        storeName: 'A101',
        date: now.subtract(const Duration(days: 10)),
        items: [
          ShoppingItem(id: 'r2_i1', name: 'Kıyma', amount: 0.5, unit: 'kg', price: 250.0, category: 'Et & Şarküteri', isBought: true),
          ShoppingItem(id: 'r2_i2', name: 'Makarna', amount: 2.0, unit: 'paket', price: 30.0, category: 'Kuru Gıda', isBought: true),
          ShoppingItem(id: 'r2_i3', name: 'Yoğurt', amount: 1.0, unit: 'kova', price: 55.0, category: 'Süt Ürünleri', isBought: true),
        ],
        totalAmount: 335.0,
      ),
      Receipt(
        id: 'r3',
        storeName: 'Carrefour',
        date: now.subtract(const Duration(days: 25)),
        items: [
          ShoppingItem(id: 'r3_i1', name: 'Muz', amount: 1.0, unit: 'kg', price: 65.0, category: 'Sebze/Meyve', isBought: true),
          ShoppingItem(id: 'r3_i2', name: 'Elma', amount: 1.5, unit: 'kg', price: 45.0, category: 'Sebze/Meyve', isBought: true),
          ShoppingItem(id: 'r3_i3', name: 'Portakal Suyu', amount: 2.0, unit: 'adet', price: 80.0, category: 'İçecek', isBought: true),
        ],
        totalAmount: 190.0,
      ),
      Receipt(
        id: 'r4',
        storeName: 'Şok',
        date: now.subtract(const Duration(days: 40)),
        items: [
          ShoppingItem(id: 'r4_i1', name: 'Zeytinyağı', amount: 1.0, unit: 'litre', price: 280.0, category: 'Diğer', isBought: true),
          ShoppingItem(id: 'r4_i2', name: 'Peynir', amount: 1.0, unit: 'adet', price: 110.0, category: 'Süt Ürünleri', isBought: true),
          ShoppingItem(id: 'r4_i3', name: 'Ekmek', amount: 4.0, unit: 'adet', price: 40.0, category: 'Diğer', isBought: true),
        ],
        totalAmount: 430.0,
      ),
    ];
  }

  Future<List<ShoppingItem>> loadShoppingList(String username) async {
    final dynamic decoded = await _storage.getJson(StorageKeys.shoppingListData(username));
    if (decoded != null && decoded is List) {
      try {
        return decoded.map((item) => ShoppingItem.fromJson(item as Map<String, dynamic>)).toList();
      } catch (_) {
        return getSampleShoppingList();
      }
    }
    final sample = getSampleShoppingList();
    await saveShoppingList(username, sample);
    return sample;
  }

  Future<void> saveShoppingList(String username, List<ShoppingItem> items) async {
    final list = items.map((i) => i.toJson()).toList();
    await _storage.setJson(StorageKeys.shoppingListData(username), list);
  }

  Future<List<Receipt>> loadReceipts(String username) async {
    final dynamic decoded = await _storage.getJson(StorageKeys.receiptsData(username));
    if (decoded != null && decoded is List) {
      try {
        return decoded.map((item) => Receipt.fromJson(item as Map<String, dynamic>)).toList();
      } catch (_) {
        return getSampleReceipts();
      }
    }
    final sample = getSampleReceipts();
    await saveReceipts(username, sample);
    return sample;
  }

  Future<void> saveReceipts(String username, List<Receipt> receipts) async {
    final list = receipts.map((r) => r.toJson()).toList();
    await _storage.setJson(StorageKeys.receiptsData(username), list);
  }

  Future<double> loadBudgetLimit(String username) async {
    return await _storage.getDouble(StorageKeys.budgetLimit(username)) ?? AppConstants.defaultMonthlyBudgetLimit;
  }

  Future<void> saveBudgetLimit(String username, double limit) async {
    await _storage.setDouble(StorageKeys.budgetLimit(username), limit);
  }
}
