class MilkRecord {
  final String date;
  final double morning;
  final double evening;
  final double unitPrice;
  final double dailyCost;
  final String remarks;
  final String status;
  final String stage;

  MilkRecord({
    required this.date,
    required this.morning,
    required this.evening,
    required this.unitPrice,
    required this.dailyCost,
    required this.remarks,
    required this.status,
    required this.stage,
  });

  double get total => morning + evening;

  factory MilkRecord.fromJson(Map<String, dynamic> j) {
    final morning = double.tryParse('${j['morning'] ?? 0}') ?? 0;
    final evening = double.tryParse('${j['evening'] ?? 0}') ?? 0;
    final unitPrice =
        double.tryParse('${j['unitprice'] ?? j['unitPrice'] ?? 80}') ?? 80;
    return MilkRecord(
      date: j['date']?.toString() ?? '',
      morning: morning,
      evening: evening,
      unitPrice: unitPrice,
      dailyCost: (morning + evening) * unitPrice,
      remarks: j['remarks']?.toString() ?? '',
      status: j['status']?.toString() ?? 'Unpaid',
      stage: j['stage']?.toString() ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'morning': morning,
    'evening': evening,
    'unitprice': unitPrice,
    'dailyCost': dailyCost,
    'remarks': remarks,
    'status': status,
    'stage': stage,
  };
}
