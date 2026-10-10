class ShoppingItem {
  final String id;
  final String name;
  final double amount;
  final String unit;
  final bool isBought;
  final double price;
  final String category;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    this.isBought = false,
    this.price = 0.0,
    this.category = 'Diğer',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'unit': unit,
      'isBought': isBought,
      'price': price,
      'category': category,
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
      isBought: json['isBought'] as bool? ?? false,
      price: (json['price'] as num? ?? 0.0).toDouble(),
      category: json['category'] as String? ?? 'Diğer',
    );
  }

  ShoppingItem copyWith({
    String? id,
    String? name,
    double? amount,
    String? unit,
    bool? isBought,
    double? price,
    String? category,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      isBought: isBought ?? this.isBought,
      price: price ?? this.price,
      category: category ?? this.category,
    );
  }
}
