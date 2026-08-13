class DebtRecord {
  const DebtRecord({
    this.id,
    required this.date,
    required this.type,
    required this.person,
    required this.amount,
    required this.remarks,
    required this.status,
    required this.settleRemarks,
  });

  final int? id;
  final String date; // dd/MMM/yyyy
  final String type; // given|taken
  final String person;
  final double amount;
  final String remarks;
  final String status; // pending|settled
  final String settleRemarks;

  bool get isGiven => type == 'given';
  bool get isSettled => status == 'settled';

  DebtRecord copyWith({
    int? id,
    String? date,
    String? type,
    String? person,
    double? amount,
    String? remarks,
    String? status,
    String? settleRemarks,
  }) {
    return DebtRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      person: person ?? this.person,
      amount: amount ?? this.amount,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
      settleRemarks: settleRemarks ?? this.settleRemarks,
    );
  }

  static String _normType(Object? raw) {
    final v = '${raw ?? ''}'.toLowerCase();
    if (v == 'taken' || v == 'borrowed') return 'taken';
    return 'given';
  }

  static String _normStatus(Object? raw) {
    final v = '${raw ?? ''}'.toLowerCase();
    if (v == 'paid' || v == 'settled') return 'settled';
    return 'pending';
  }

  static double _num(Object? raw) => double.tryParse('${raw ?? 0}') ?? 0;

  factory DebtRecord.fromJson(Map<String, dynamic> json) {
    return DebtRecord(
      id: int.tryParse('${json['id'] ?? ''}'),
      date: '${json['date'] ?? ''}',
      type: _normType(json['type']),
      person: '${json['person'] ?? ''}',
      amount: _num(json['amount']),
      remarks: '${json['remarks'] ?? json['notes'] ?? ''}',
      status: _normStatus(json['status']),
      settleRemarks: '${json['settleRemarks'] ?? ''}',
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

