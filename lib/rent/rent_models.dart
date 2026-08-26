class RentRecord {
  final String date;
  final String side;
  final double rentAmount;
  final double paidAmount;
  final double balanceAmount;
  final double powerBill;
  final double waterBill;
  final double adjustAmount;
  final double totalPaid;
  final String remarks;

  RentRecord({
    required this.date,
    required this.side,
    required this.rentAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.powerBill,
    required this.waterBill,
    required this.adjustAmount,
    required this.totalPaid,
    required this.remarks,
  });

  factory RentRecord.fromJson(Map<String, dynamic> json) {
    return RentRecord(
      date: json['date'] ?? '',
      side: json['side'] ?? '',
      rentAmount: _toDouble(json['rentAmount']),
      paidAmount: _toDouble(json['paidAmount']),
      balanceAmount: _toDouble(json['balanceAmount']),
      powerBill: _toDouble(json['powerBill']),
      waterBill: _toDouble(json['waterBill']),
      adjustAmount: _toDouble(json['adjustAmount']),
      totalPaid: _toDouble(json['totalPaid']),
      remarks: json['remarks'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'side': side,
      'rentAmount': rentAmount,
      'paidAmount': paidAmount,
      'balanceAmount': balanceAmount,
      'powerBill': powerBill,
      'waterBill': waterBill,
      'adjustAmount': adjustAmount,
      'totalPaid': totalPaid,
      'remarks': remarks,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
