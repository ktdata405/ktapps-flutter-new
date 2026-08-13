class RentRecord {
  const RentRecord({
    required this.date,
    required this.side,
    required this.rentAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.powerBill,
    required this.waterBill,
    required this.remarks,
    this.totalPaidOverride,
  });

  final String date;
  final String side;
  final double rentAmount;
  final double paidAmount;
  final double balanceAmount;
  final double powerBill;
  final double waterBill;
  final String remarks;
  final double? totalPaidOverride;

  double get totalPaid => totalPaidOverride ?? (paidAmount + powerBill + waterBill);

  RentRecord copyWith({
    String? date,
    String? side,
    double? rentAmount,
    double? paidAmount,
    double? balanceAmount,
    double? powerBill,
    double? waterBill,
    String? remarks,
    double? totalPaidOverride,
  }) {
    return RentRecord(
      date: date ?? this.date,
      side: side ?? this.side,
      rentAmount: rentAmount ?? this.rentAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      powerBill: powerBill ?? this.powerBill,
      waterBill: waterBill ?? this.waterBill,
      remarks: remarks ?? this.remarks,
      totalPaidOverride: totalPaidOverride ?? this.totalPaidOverride,
    );
  }

  factory RentRecord.fromJson(Map<String, dynamic> json) {
    double parseNum(Object? value) => double.tryParse('$value') ?? 0;

    final paid = parseNum(json['paidAmount']);
    final power = parseNum(json['powerBill']);
    final water = parseNum(json['waterBill']);
    final explicitTotal = json['totalPaid'];

    return RentRecord(
      date: (json['date'] ?? '').toString(),
      side: (json['side'] ?? 'Kalyan').toString(),
      rentAmount: parseNum(json['rentAmount']),
      paidAmount: paid,
      balanceAmount: parseNum(json['balanceAmount']),
      powerBill: power,
      waterBill: water,
      remarks: (json['remarks'] ?? '').toString(),
      totalPaidOverride: explicitTotal == null ? (paid + power + water) : parseNum(explicitTotal),
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
      'remarks': remarks,
      'totalPaid': totalPaid,
    };
  }
}

