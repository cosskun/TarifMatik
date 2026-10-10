import 'shopping_item.dart';

class Receipt {
  final String id;
  final String storeName;
  final DateTime date;
  final List<ShoppingItem> items;
  final double totalAmount;

  Receipt({
    required this.id,
    required this.storeName,
    required this.date,
    required this.items,
    required this.totalAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeName': storeName,
      'date': date.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'totalAmount': totalAmount,
    };
  }

  factory Receipt.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List? ?? [];
    List<ShoppingItem> parsedItems = list.map((i) => ShoppingItem.fromJson(i as Map<String, dynamic>)).toList();

    return Receipt(
      id: json['id'] as String,
      storeName: json['storeName'] as String,
      date: DateTime.parse(json['date'] as String),
      items: parsedItems,
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }
}
