// ── Loan Record ──────────────────────────────────────────────
class LoanRecord {
  const LoanRecord({
    this.id,
    required this.date,
    required this.name,
    required this.amount,
    required this.interestRate,
    required this.tenureValue,
    required this.tenureType,
    required this.type,
    required this.status,
    required this.remarks,
    this.paid = 0,
  });

  final String? id;
  final String date; // dd/MMM/yyyy
  final String name;
  final double amount;
  final double interestRate; // %
  final int tenureValue;
  final String tenureType; // 'Months' | 'Years'
  final String type; // 'Given' | 'Taken'
  final String status; // 'Active' | 'Closed' | 'Defaulted'
  final String remarks;
  final double paid;

  // ── Computed ──
  int get tenureMonths =>
      tenureType == 'Years' ? tenureValue * 12 : tenureValue;
  double get balance => (amount - paid).clamp(0, double.infinity);
  double get totalInterest => (amount * interestRate * tenureMonths) / 1200;
  double get totalPayable => amount + totalInterest;
  double get emi => tenureMonths > 0 ? totalPayable / tenureMonths : 0;
  int get emisPaid => emi > 0 ? (paid / emi).floor() : 0;
  double get progressPct =>
      amount > 0 ? (paid / amount).clamp(0.0, 1.0) : 0.0;
  bool get isClosed => status == 'Closed';
  bool get isGiven => type == 'Given';
  String get tenureDisplay => '$tenureValue $tenureType';

  LoanRecord copyWith({
    String? id,
    String? date,
    String? name,
    double? amount,
    double? interestRate,
    int? tenureValue,
    String? tenureType,
    String? type,
    String? status,
    String? remarks,
    double? paid,
  }) =>
      LoanRecord(
        id: id ?? this.id,
        date: date ?? this.date,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        interestRate: interestRate ?? this.interestRate,
        tenureValue: tenureValue ?? this.tenureValue,
        tenureType: tenureType ?? this.tenureType,
        type: type ?? this.type,
        status: status ?? this.status,
        remarks: remarks ?? this.remarks,
        paid: paid ?? this.paid,
      );

  static double _n(Object? v) => double.tryParse('${v ?? 0}') ?? 0;
  static int _i(Object? v) => int.tryParse('${v ?? 0}') ?? 0;

  factory LoanRecord.fromJson(Map<String, dynamic> json) {
    // tenure can be "12 Months" or "2 Years"
    final raw = '${json['tenure'] ?? ''}';
    final parts = raw.split(' ');
    final tv = parts.isNotEmpty ? (_i(parts[0])) : 0;
    final tt = parts.length >= 2 ? parts[1] : 'Months';

    return LoanRecord(
      id: json['id']?.toString(),
      date: '${json['date'] ?? ''}',
      name: '${json['name'] ?? ''}',
      amount: _n(json['amount']),
      interestRate: _n(json['interestRate']),
      tenureValue: tv,
      tenureType: tt,
      type: '${json['type'] ?? 'Given'}',
      status: '${json['status'] ?? 'Active'}',
      remarks: '${json['remarks'] ?? ''}',
      paid: _n(json['paid']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'date': date,
        'name': name,
        'amount': amount,
        'interestRate': interestRate,
        'tenure': tenureDisplay,
        'type': type,
        'status': status,
        'remarks': remarks,
        'paid': paid,
      };
}

// ── Loan Payment (Transaction) ───────────────────────────────
class LoanPayment {
  const LoanPayment({
    this.id,
    required this.loanId,
    required this.date,
    required this.amount,
    required this.type,
    required this.remarks,
  });

  final String? id;
  final String loanId;
  final String date;
  final double amount;
  final String type; // Principal | Full Settlement | Interest | EMI
  final String remarks;

  factory LoanPayment.fromJson(Map<String, dynamic> json) => LoanPayment(
        id: json['id']?.toString(),
        loanId: '${json['loanId'] ?? ''}',
        date: '${json['date'] ?? ''}',
        amount: double.tryParse('${json['amount'] ?? 0}') ?? 0,
        type: '${json['type'] ?? 'EMI'}',
        remarks: '${json['remarks'] ?? ''}',
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'loanId': loanId,
        'date': date,
        'amount': amount,
        'type': type,
        'remarks': remarks,
      };
}

// ── Monthly Repayment Status ──────────────────────────────────
class RepaymentMonth {
  const RepaymentMonth({
    required this.loanId,
    required this.year,
    required this.month,
    required this.status,
  });

  final String loanId;
  final int year;
  final int month;
  final String status; // 'Done' | 'Pending'

  bool get isDone => status == 'Done';

  RepaymentMonth copyWith({String? status}) => RepaymentMonth(
        loanId: loanId,
        year: year,
        month: month,
        status: status ?? this.status,
      );
}

