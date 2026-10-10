class Ingredient {
  final String name;
  double amount;
  final String unit;
  DateTime? expiryDate;

  Ingredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.expiryDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate'] as String) : null,
    );
  }

  Ingredient copyWith({
    String? name,
    double? amount,
    String? unit,
    DateTime? expiryDate,
  }) {
    return Ingredient(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}
