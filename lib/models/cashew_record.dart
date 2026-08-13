class CashewRecord {
  const CashewRecord({
    required this.date,
    required this.category,
    required this.description,
    required this.amount,
    this.status = 'completed',
  });

  final String date; // dd/MMM/yyyy
  final String category;
  final String description;
  final double amount;
  final String status; // draft|completed

  bool get isDraft => status.toLowerCase() == 'draft';

  CashewRecord copyWith({
    String? date,
    String? category,
    String? description,
    double? amount,
    String? status,
  }) {
    return CashewRecord(
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      status: status ?? this.status,
    );
  }

  factory CashewRecord.fromJson(Map<String, dynamic> json) {
    return CashewRecord(
      date: '${json['date'] ?? ''}',
      category: '${json['category'] ?? ''}',
      description: '${json['description'] ?? ''}',
      amount: double.tryParse('${json['amount'] ?? 0}') ?? 0,
      status: '${json['status'] ?? 'completed'}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'category': category,
      'description': description,
      'amount': amount,
      'status': status,
    };
  }
}
