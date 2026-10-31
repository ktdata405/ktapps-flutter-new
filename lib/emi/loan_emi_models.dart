import '../cc_emi/cc_emi_models.dart';
import '../core_constants.dart';
import '../core_utils.dart';

enum LoanDetailField {
  propertyAddress('propertyAddress', KtStrings.propertyAddressLabel),
  vehicle('vehicle', KtStrings.vehicleLabel),
  securities('securities', KtStrings.securitiesLabel),
  collateralValue(
    'collateralValue',
    KtStrings.collateralValueLabel,
    numeric: true,
  ),
  purpose('purpose', KtStrings.loanPurposeLabel),
  goldWeight('goldWeight', KtStrings.goldWeightLabel, numeric: true),
  goldPurity('goldPurity', KtStrings.goldPurityLabel, numeric: true);

  const LoanDetailField(this.key, this.label, {this.numeric = false});
  final String key;
  final String label;
  final bool numeric;
}

enum EmiLoanType {
  home('home', KtStrings.homeLoan, [LoanDetailField.propertyAddress]),
  car('car', KtStrings.carLoan, [LoanDetailField.vehicle]),
  securities('securities', KtStrings.securitiesLoan, [
    LoanDetailField.securities,
    LoanDetailField.collateralValue,
  ]),
  personal('personal', KtStrings.personalLoan, [LoanDetailField.purpose]),
  gold('gold', KtStrings.goldLoan, [
    LoanDetailField.goldWeight,
    LoanDetailField.goldPurity,
    LoanDetailField.collateralValue,
  ]),
  other('other', KtStrings.otherLoan, [LoanDetailField.purpose]);

  const EmiLoanType(this.key, this.label, this.fields);
  final String key;
  final String label;
  final List<LoanDetailField> fields;

  static EmiLoanType parse(String key) =>
      values.firstWhere((type) => type.key == key);
}

class LoanEmiPayment {
  const LoanEmiPayment({
    required this.id,
    required this.loanId,
    required this.paymentDate,
    required this.principalPaid,
    required this.interestPaid,
    required this.paymentMode,
    this.remarks = '',
  });

  final String id;
  final String loanId;
  final String paymentDate;
  final double principalPaid;
  final double interestPaid;
  final String paymentMode;
  final String remarks;
  double get amountPaid => principalPaid + interestPaid;

  factory LoanEmiPayment.fromJson(Map<String, dynamic> json) => LoanEmiPayment(
    id: json['id'] as String,
    loanId: json['loanId'] as String,
    paymentDate: json['paymentDate'] as String,
    principalPaid: _number(json['principalPaid']),
    interestPaid: _number(json['interestPaid']),
    paymentMode: json['paymentMode'] as String,
    remarks: json['remarks'] as String? ?? '',
  );

  Map<String, String> toParams() => {
    'id': id,
    'loanId': loanId,
    'paymentDate': paymentDate,
    'principalPaid': principalPaid.toString(),
    'interestPaid': interestPaid.toString(),
    'paymentMode': paymentMode,
    'remarks': remarks,
  };
}

double _number(Object? value) => double.parse(value.toString());

class LoanEmiRecord {
  const LoanEmiRecord({
    this.id,
    required this.type,
    required this.lender,
    required this.accountNumber,
    required this.startDate,
    required this.firstEmiDate,
    required this.principal,
    required this.annualRate,
    required this.tenureMonths,
    this.processingFee = 0,
    this.details = const {},
    this.remarks = '',
    this.payments = const [],
  });

  final String? id;
  final EmiLoanType type;
  final String lender;
  final String accountNumber;
  final String startDate;
  final String firstEmiDate;
  final double principal;
  final double annualRate;
  final int tenureMonths;
  final double processingFee;
  final Map<String, String> details;
  final String remarks;
  final List<LoanEmiPayment> payments;

  double get monthlyEmi =>
      CreditCardEmiRecord.calculateEmi(principal, annualRate, tenureMonths);
  double get totalInterest => CreditCardEmiRecord.calculateTotalInterest(
    monthlyEmi,
    tenureMonths,
    principal,
  );
  double get totalPayable => principal + totalInterest + processingFee;
  double get principalPaid =>
      payments.fold(0.0, (sum, payment) => sum + payment.principalPaid);
  double get interestPaid =>
      payments.fold(0.0, (sum, payment) => sum + payment.interestPaid);
  double get outstanding =>
      (principal - principalPaid).clamp(0, principal).toDouble();
  bool get isCompleted => outstanding <= 0.005;

  // Clamp dates such as the 31st to the last day of shorter months.
  DateTime dueDate(int installment) {
    final first = ktParseDate(firstEmiDate)!;
    final month = DateTime(first.year, first.month + installment - 1);
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    return DateTime(month.year, month.month, first.day.clamp(1, lastDay));
  }

  factory LoanEmiRecord.fromJson(Map<String, dynamic> json) {
    final details = <String, String>{};
    for (final field in LoanDetailField.values) {
      final value = json[field.key]?.toString() ?? '';
      if (value.isNotEmpty) details[field.key] = value;
    }
    return LoanEmiRecord(
      id: json['id'] as String,
      type: EmiLoanType.parse(json['loanType'] as String),
      lender: json['lender'] as String,
      accountNumber: json['accountNumber'] as String,
      startDate: json['startDate'] as String,
      firstEmiDate: json['firstEmiDate'] as String,
      principal: _number(json['principal']),
      annualRate: _number(json['annualRate']),
      tenureMonths: int.parse(json['tenureMonths'].toString()),
      processingFee: _number(json['processingFee']),
      details: details,
      remarks: json['remarks'] as String? ?? '',
      payments:
          (json['payments'] as List<dynamic>)
              .map(
                (payment) =>
                    LoanEmiPayment.fromJson(payment as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  Map<String, String> toParams() => {
    if (id != null) 'id': id!,
    'loanType': type.key,
    'lender': lender,
    'accountNumber': accountNumber,
    'startDate': startDate,
    'firstEmiDate': firstEmiDate,
    'principal': principal.toString(),
    'annualRate': annualRate.toString(),
    'tenureMonths': tenureMonths.toString(),
    'processingFee': processingFee.toString(),
    'remarks': remarks,
    for (final field in type.fields) field.key: details[field.key] ?? '',
  };
}
