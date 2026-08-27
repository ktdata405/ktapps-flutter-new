class LoanRecord {
  final String? id;
  final String date;
  final String name;
  final double amount;
  final double interestRate;
  final String tenure;
  final String type; // 'Given' or 'Taken'
  final String status; // 'Active', 'Closed', 'Defaulted'
  final String remarks;
  final double paid;

  LoanRecord({
    this.id,
    required this.date,
    required this.name,
    required this.amount,
    required this.interestRate,
    required this.tenure,
    required this.type,
    required this.status,
    this.remarks = '',
    this.paid = 0,
  });

  factory LoanRecord.fromJson(Map<String, dynamic> json) {
    return LoanRecord(
      id: json['id']?.toString(),
      date: json['date'] ?? '',
      name: json['name'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      interestRate: double.tryParse(json['interestRate']?.toString() ?? '0') ?? 0.0,
      tenure: json['tenure'] ?? '',
      type: json['type'] ?? 'Given',
      status: json['status'] ?? 'Active',
      remarks: json['remarks'] ?? '',
      paid: double.tryParse(json['paid']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'name': name,
      'amount': amount,
      'interestRate': interestRate,
      'tenure': tenure,
      'type': type,
      'status': status,
      'remarks': remarks,
    };
  }
}

class RepaymentStatus {
  final int year;
  final int month;
  final String status; // 'Done' or 'Pending'

  RepaymentStatus({required this.year, required this.month, required this.status});

  factory RepaymentStatus.fromJson(Map<String, dynamic> json) {
    return RepaymentStatus(
      year: int.tryParse(json['year']?.toString() ?? '0') ?? 0,
      month: int.tryParse(json['month']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'Pending',
    );
  }
}
