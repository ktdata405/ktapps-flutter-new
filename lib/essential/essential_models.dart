class EssentialRecord {
  final String sNo;
  final String date; // e.g. "22/Sep/2026 (Wed)"
  final String fullName;
  final double itemD; // Rice (KG)
  final double itemE; // Dal (KG)
  final double itemF; // Oil (KG)
  final double itemG; // Onions (KG)
  final double itemH; // Tamarind (KG)
  final double totalAmount; // Directly from Column K

  EssentialRecord({
    required this.sNo,
    required this.date,
    required this.fullName,
    required this.itemD,
    required this.itemE,
    required this.itemF,
    required this.itemG,
    required this.itemH,
    required this.totalAmount,
  });

  factory EssentialRecord.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val is num) return val.toDouble();
      if (val == null) return 0.0;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return EssentialRecord(
      sNo: json['sNo']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      itemD: parseNum(json['itemD']),
      itemE: parseNum(json['itemE']),
      itemF: parseNum(json['itemF']),
      itemG: parseNum(json['itemG']),
      itemH: parseNum(json['itemH']),
      totalAmount: parseNum(json['totalAmount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sNo': sNo,
      'date': date,
      'fullName': fullName,
      'itemD': itemD,
      'itemE': itemE,
      'itemF': itemF,
      'itemG': itemG,
      'itemH': itemH,
      'totalAmount': totalAmount,
    };
  }

  EssentialRecord copyWith({
    String? sNo,
    String? date,
    String? fullName,
    double? itemD,
    double? itemE,
    double? itemF,
    double? itemG,
    double? itemH,
    double? totalAmount,
  }) {
    return EssentialRecord(
      sNo: sNo ?? this.sNo,
      date: date ?? this.date,
      fullName: fullName ?? this.fullName,
      itemD: itemD ?? this.itemD,
      itemE: itemE ?? this.itemE,
      itemF: itemF ?? this.itemF,
      itemG: itemG ?? this.itemG,
      itemH: itemH ?? this.itemH,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  /// Total sum of items quantity
  double get totalQuantity => itemD + itemE + itemF + itemG + itemH;

  /// Helper to generate S.No as last 3 digits of current millisecond
  static String generateSNo() {
    final ms = DateTime.now().millisecondsSinceEpoch % 1000;
    return ms.toString().padLeft(3, '0');
  }
}

class CashGiftRecord {
  final String sNo;
  final String date;
  final String name;
  final double amount;
  final String modeOfPayment;
  final String status;
  final String remarks;
  final String timestamp;

  CashGiftRecord({
    required this.sNo,
    required this.date,
    required this.name,
    required this.amount,
    required this.modeOfPayment,
    required this.status,
    required this.remarks,
    required this.timestamp,
  });

  factory CashGiftRecord.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val is num) return val.toDouble();
      if (val == null) return 0.0;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return CashGiftRecord(
      sNo: json['sNo']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      amount: parseNum(json['amount']),
      modeOfPayment: json['modeOfPayment']?.toString() ?? 'Cash',
      status: json['status']?.toString() ?? 'Completed',
      remarks: json['remarks']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sNo': sNo,
      'date': date,
      'name': name,
      'amount': amount,
      'modeOfPayment': modeOfPayment,
      'status': status,
      'remarks': remarks,
      'timestamp': timestamp,
    };
  }

  CashGiftRecord copyWith({
    String? sNo,
    String? date,
    String? name,
    double? amount,
    String? modeOfPayment,
    String? status,
    String? remarks,
    String? timestamp,
  }) {
    return CashGiftRecord(
      sNo: sNo ?? this.sNo,
      date: date ?? this.date,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      modeOfPayment: modeOfPayment ?? this.modeOfPayment,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  static String generateSNo() {
    final ms = DateTime.now().millisecondsSinceEpoch % 1000;
    return ms.toString().padLeft(3, '0');
  }
}
