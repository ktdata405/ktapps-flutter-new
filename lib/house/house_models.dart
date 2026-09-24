class HouseBillRecord {
  final String sNo;
  final String date; // e.g. "25/Sep/2026 (Fri)"
  final String groupName; // Column A
  final double amount; // Column B
  final double contractAmount; // Column C
  final double balanceAmount; // Column D
  final String timestamp;

  HouseBillRecord({
    required this.sNo,
    required this.date,
    required this.groupName,
    required this.amount,
    required this.contractAmount,
    required this.balanceAmount,
    required this.timestamp,
  });

  factory HouseBillRecord.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val is num) return val.toDouble();
      if (val == null) return 0.0;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return HouseBillRecord(
      sNo: json['sNo']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      groupName: json['groupName']?.toString() ?? '',
      amount: parseNum(json['amount']),
      contractAmount: parseNum(json['contractAmount']),
      balanceAmount: parseNum(json['balanceAmount']),
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sNo': sNo,
      'date': date,
      'groupName': groupName,
      'amount': amount,
      'contractAmount': contractAmount,
      'balanceAmount': balanceAmount,
      'timestamp': timestamp,
    };
  }

  HouseBillRecord copyWith({
    String? sNo,
    String? date,
    String? groupName,
    double? amount,
    double? contractAmount,
    double? balanceAmount,
    String? timestamp,
  }) {
    return HouseBillRecord(
      sNo: sNo ?? this.sNo,
      date: date ?? this.date,
      groupName: groupName ?? this.groupName,
      amount: amount ?? this.amount,
      contractAmount: contractAmount ?? this.contractAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  static String generateSNo() {
    final ms = DateTime.now().millisecondsSinceEpoch % 1000;
    return ms.toString().padLeft(3, '0');
  }
}

class HlDisbursementRecord {
  final String sNo;
  final String date;
  final double amount;
  final String timestamp;

  HlDisbursementRecord({
    required this.sNo,
    required this.date,
    required this.amount,
    required this.timestamp,
  });

  factory HlDisbursementRecord.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val is num) return val.toDouble();
      if (val == null) return 0.0;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return HlDisbursementRecord(
      sNo: json['sNo']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      amount: parseNum(json['amount']),
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sNo': sNo,
      'date': date,
      'amount': amount,
      'timestamp': timestamp,
    };
  }

  HlDisbursementRecord copyWith({
    String? sNo,
    String? date,
    double? amount,
    String? timestamp,
  }) {
    return HlDisbursementRecord(
      sNo: sNo ?? this.sNo,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  static String generateSNo() {
    final ms = DateTime.now().millisecondsSinceEpoch % 1000;
    return ms.toString().padLeft(3, '0');
  }
}
