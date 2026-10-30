import 'dart:math' as math;

class EmiPaymentRecord {
  final String id;
  final String emiRecordId;
  final int emiNumber;
  final String paymentDate;
  final double amountPaid;
  final String paymentMode;
  final String remarks;

  EmiPaymentRecord({
    required this.id,
    required this.emiRecordId,
    required this.emiNumber,
    required this.paymentDate,
    required this.amountPaid,
    this.paymentMode = 'Auto Debit',
    this.remarks = '',
  });

  factory EmiPaymentRecord.fromJson(Map<String, dynamic> json) {
    return EmiPaymentRecord(
      id: json['id']?.toString() ?? '',
      emiRecordId: json['emiRecordId']?.toString() ?? '',
      emiNumber: int.tryParse(json['emiNumber']?.toString() ?? '1') ?? 1,
      paymentDate: json['paymentDate']?.toString() ?? '',
      amountPaid: double.tryParse(json['amountPaid']?.toString() ?? '0') ?? 0.0,
      paymentMode: json['paymentMode']?.toString() ?? 'Auto Debit',
      remarks: json['remarks']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emiRecordId': emiRecordId,
      'emiNumber': emiNumber,
      'paymentDate': paymentDate,
      'amountPaid': amountPaid,
      'paymentMode': paymentMode,
      'remarks': remarks,
    };
  }
}

class CreditCardEmiRecord {
  final String? id;
  final String cardName; // e.g. "HDFC Regalia", "ICICI Amazon Pay"
  final String merchantName; // e.g. "Amazon - iPhone 15 Pro"
  final String purchaseDate; // Formatted date string
  final double totalAmount; // Principal purchase amount
  final double interestRate; // % p.a. (0 if No Cost EMI)
  final int tenureMonths; // 3, 6, 9, 12, 18, 24, etc.
  final double monthlyEmi;
  final double processingFee;
  final double totalInterest;
  final double totalPayable;
  final int emisPaid;
  final int dueDay; // Day of month e.g. 5, 10, 15
  final String firstEmiDate;
  final String status; // 'Active', 'Completed', 'Closed'
  final String category; // 'Electronics', 'Appliances', 'Travel', 'Shopping', etc.
  final String remarks;
  final List<EmiPaymentRecord> repayments;

  CreditCardEmiRecord({
    this.id,
    required this.cardName,
    required this.merchantName,
    required this.purchaseDate,
    required this.totalAmount,
    required this.interestRate,
    required this.tenureMonths,
    required this.monthlyEmi,
    this.processingFee = 0.0,
    required this.totalInterest,
    required this.totalPayable,
    this.emisPaid = 0,
    this.dueDay = 5,
    this.firstEmiDate = '',
    this.status = 'Active',
    this.category = 'Electronics',
    this.remarks = '',
    this.repayments = const [],
  });

  factory CreditCardEmiRecord.fromJson(Map<String, dynamic> json) {
    final repList = (json['repayments'] as List<dynamic>?)
            ?.map((e) => EmiPaymentRecord.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final totalAmt = double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0;
    final intRate = double.tryParse(json['interestRate']?.toString() ?? '0') ?? 0.0;
    final tenure = int.tryParse(json['tenureMonths']?.toString() ?? '1') ?? 1;
    final pFee = double.tryParse(json['processingFee']?.toString() ?? '0') ?? 0.0;

    double calcEmi = double.tryParse(json['monthlyEmi']?.toString() ?? '0') ?? 0.0;
    if (calcEmi <= 0) {
      calcEmi = calculateEmi(totalAmt, intRate, tenure);
    }

    double calcInterest = double.tryParse(json['totalInterest']?.toString() ?? '0') ?? 0.0;
    if (calcInterest <= 0) {
      calcInterest = calculateTotalInterest(calcEmi, tenure, totalAmt);
    }

    double calcPayable = double.tryParse(json['totalPayable']?.toString() ?? '0') ?? 0.0;
    if (calcPayable <= 0) {
      calcPayable = totalAmt + calcInterest + pFee;
    }

    final paidCount = int.tryParse(json['emisPaid']?.toString() ?? '0') ?? repList.length;

    return CreditCardEmiRecord(
      id: json['id']?.toString(),
      cardName: json['cardName']?.toString() ?? '',
      merchantName: json['merchantName']?.toString() ?? '',
      purchaseDate: json['purchaseDate']?.toString() ?? '',
      totalAmount: totalAmt,
      interestRate: intRate,
      tenureMonths: tenure,
      monthlyEmi: calcEmi,
      processingFee: pFee,
      totalInterest: calcInterest,
      totalPayable: calcPayable,
      emisPaid: paidCount,
      dueDay: int.tryParse(json['dueDay']?.toString() ?? '5') ?? 5,
      firstEmiDate: json['firstEmiDate']?.toString() ?? '',
      status: json['status']?.toString() ?? (paidCount >= tenure ? 'Completed' : 'Active'),
      category: json['category']?.toString() ?? 'Electronics',
      remarks: json['remarks']?.toString() ?? '',
      repayments: repList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'cardName': cardName,
      'merchantName': merchantName,
      'purchaseDate': purchaseDate,
      'totalAmount': totalAmount,
      'interestRate': interestRate,
      'tenureMonths': tenureMonths,
      'monthlyEmi': monthlyEmi,
      'processingFee': processingFee,
      'totalInterest': totalInterest,
      'totalPayable': totalPayable,
      'emisPaid': emisPaid,
      'dueDay': dueDay,
      'firstEmiDate': firstEmiDate,
      'status': status,
      'category': category,
      'remarks': remarks,
      'repayments': repayments.map((e) => e.toJson()).toList(),
    };
  }

  /// Calculates monthly EMI given principal P, interest rate R (% p.a.), and N months
  static double calculateEmi(double principal, double annualRate, int tenureMonths) {
    if (principal <= 0 || tenureMonths <= 0) return 0.0;
    if (annualRate <= 0) return principal / tenureMonths;
    final monthlyRate = annualRate / (12 * 100);
    final powVal = math.pow(1 + monthlyRate, tenureMonths);
    if (powVal == 1) return principal / tenureMonths;
    final emi = (principal * monthlyRate * powVal) / (powVal - 1);
    return emi.isNaN || emi.isInfinite ? 0.0 : emi;
  }

  /// Calculates total interest
  static double calculateTotalInterest(double monthlyEmi, int tenureMonths, double principal) {
    final totalPay = monthlyEmi * tenureMonths;
    final interest = totalPay - principal;
    return interest > 0 ? interest : 0.0;
  }

  double get paidAmount {
    if (repayments.isNotEmpty) {
      return repayments.fold(0.0, (sum, item) => sum + item.amountPaid);
    }
    return emisPaid * monthlyEmi;
  }

  double get remainingPayable {
    final rem = totalPayable - paidAmount;
    return rem > 0 ? rem : 0.0;
  }

  int get remainingEmis {
    final rem = tenureMonths - emisPaid;
    return rem > 0 ? rem : 0;
  }

  bool get isCompleted => status == 'Completed' || emisPaid >= tenureMonths;
}
