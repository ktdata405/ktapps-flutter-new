class DebtRecord {
  final int? id;
  final String date;
  final String type; // 'given' or 'taken'
  final String person;
  final double amount;
  final String remarks;
  final String status; // 'pending' or 'settled'
  final String settleRemarks;

  DebtRecord({
    this.id,
    required this.date,
    required this.type,
    required this.person,
    required this.amount,
    required this.remarks,
    required this.status,
    this.settleRemarks = '',
  });

  factory DebtRecord.fromJson(Map<String, dynamic> json) {
    String typeRaw = (json['type'] ?? '').toString().toLowerCase();
    String statusRaw = (json['status'] ?? '').toString().toLowerCase();

    return DebtRecord(
      id: int.tryParse(json['id']?.toString() ?? ''),
      date: json['date'] ?? '',
      type: (typeRaw == 'taken' || typeRaw == 'borrowed') ? 'taken' : 'given',
      person: json['person'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      remarks: json['remarks'] ?? json['notes'] ?? '',
      status: (statusRaw == 'paid' || statusRaw == 'settled') ? 'settled' : 'pending',
      settleRemarks: json['settleRemarks'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'type': type,
      'person': person,
      'amount': amount,
      'remarks': remarks,
      'status': status,
      'settleRemarks': settleRemarks,
    };
  }
}
