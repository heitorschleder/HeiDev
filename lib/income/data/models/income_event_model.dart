class IncomeEventModel {
  final String id;
  final String userId;
  final DateTime referenceMonth;
  final String description;
  final double amount;

  const IncomeEventModel({
    required this.id,
    required this.userId,
    required this.referenceMonth,
    required this.description,
    required this.amount,
  });

  factory IncomeEventModel.fromJson(Map<String, dynamic> json) => IncomeEventModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    referenceMonth: DateTime.parse(json['reference_month'] as String),
    description: json['description'] as String,
    amount: (json['amount'] as num).toDouble(),
  );
}
