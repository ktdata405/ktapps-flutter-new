
class DenominationRecord {
  String date;
  int d500;
  int d200;
  int d100;
  int d50;
  int d20;
  int d10;
  int d5;
  int d2;
  int d1;
  double total;
  double weekExpenses;
  double adjustAmount;
  double atmWithdrawal;
  double acPaid;
  double weekClosingBalance;
  String remarks;
  int? rowIndex;

  DenominationRecord({
    required this.date,
    Map<int, int>? counts,
    double? availableBalance,
    this.d500 = 0,
    this.d200 = 0,
    this.d100 = 0,
    this.d50 = 0,
    this.d20 = 0,
    this.d10 = 0,
    this.d5 = 0,
    this.d2 = 0,
    this.d1 = 0,
    this.total = 0.0,
    this.weekExpenses = 0.0,
    this.adjustAmount = 0.0,
    this.atmWithdrawal = 0.0,
    this.acPaid = 0.0,
    this.weekClosingBalance = 0.0,
    this.remarks = '',
    this.rowIndex,
  }) {
    if (counts != null) {
      d500 = counts[500] ?? d500;
      d200 = counts[200] ?? d200;
      d100 = counts[100] ?? d100;
      d50 = counts[50] ?? d50;
      d20 = counts[20] ?? d20;
      d10 = counts[10] ?? d10;
      d5 = counts[5] ?? d5;
      d2 = counts[2] ?? d2;
      d1 = counts[1] ?? d1;
    }
    if (availableBalance != null) {
      weekClosingBalance = availableBalance;
    }
  }

  /// Returns denomination counts as a map keyed by note/coin value.
  Map<int, int> get counts => {
        500: d500,
        200: d200,
        100: d100,
        50: d50,
        20: d20,
        10: d10,
        5: d5,
        2: d2,
        1: d1,
      };

  /// Alias for [weekClosingBalance].
  double get availableBalance => weekClosingBalance;

  factory DenominationRecord.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    return DenominationRecord(
      date: json['Date']?.toString() ?? json['date']?.toString() ?? '',
      d500: parseInt(json['500'] ?? json['d500']),
      d200: parseInt(json['200'] ?? json['d200']),
      d100: parseInt(json['100'] ?? json['d100']),
      d50: parseInt(json['50'] ?? json['d50']),
      d20: parseInt(json['20'] ?? json['d20']),
      d10: parseInt(json['10'] ?? json['d10']),
      d5: parseInt(json['5'] ?? json['d5']),
      d2: parseInt(json['2'] ?? json['d2']),
      d1: parseInt(json['1'] ?? json['d1']),
      total: parseDouble(json['Total'] ?? json['total']),
      weekExpenses: parseDouble(json['Week Expenses'] ?? json['weekExpenses']),
      adjustAmount: parseDouble(json['Adjust Amount'] ?? json['adjustAmount']),
      atmWithdrawal: parseDouble(json['ATM Withdrawal'] ?? json['atmWithdrawal']),
      acPaid: parseDouble(json['A/C Paid'] ?? json['acPaid']),
      weekClosingBalance: parseDouble(
        json['Week Closing Balance'] ??
            json['weekClosingBalance'] ??
            json['Available Balance'] ??
            json['availableBalance'],
      ),
      remarks: json['Remarks']?.toString() ?? json['remarks']?.toString() ?? '',
      rowIndex: json['rowIndex'] != null ? parseInt(json['rowIndex']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'date': date,
      'd500': d500,
      'd200': d200,
      'd100': d100,
      'd50': d50,
      'd20': d20,
      'd10': d10,
      'd5': d5,
      'd2': d2,
      'd1': d1,
      'total': total,
      'weekExpenses': weekExpenses,
      'adjustAmount': adjustAmount,
      'atmWithdrawal': atmWithdrawal,
      'acPaid': acPaid,
      'weekClosingBalance': weekClosingBalance,
      'remarks': remarks,
    };
    if (rowIndex != null) {
      map['action'] = 'update';
      map['rowIndex'] = rowIndex;
    }
    return map;
  }
}