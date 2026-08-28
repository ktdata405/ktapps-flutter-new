import 'package:intl/intl.dart';

class CashewRecord {
  final String date;
  final String category;
  final String description;
  final double amount;
  final String status;

  CashewRecord({
    required this.date,
    required this.category,
    required this.description,
    required this.amount,
    required this.status,
  });

  factory CashewRecord.fromJson(Map<String, dynamic> j) {
    return CashewRecord(
      date: j['date']?.toString() ?? '',
      category: j['category']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      amount: double.tryParse('${j['amount'] ?? 0}') ?? 0,
      status: j['status']?.toString() ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'category': category,
    'description': description,
    'amount': amount,
    'status': status,
  };
}

class ExpenseRow {
  String category;
  String description;
  String amount;
  String status;

  ExpenseRow({
    this.category = 'Select Category',
    this.description = '',
    this.amount = '',
    this.status = 'completed',
  });
}

class ScheduledRecord {
  final String date;
  final String category;
  final String description;
  final String cleanDescription;
  final double amount;
  final String repeat;
  final String? completedOn;
  final DateTime? parsedDate;
  final String selectionKey;

  ScheduledRecord({
    required this.date,
    required this.category,
    required this.description,
    required this.cleanDescription,
    required this.amount,
    required this.repeat,
    this.completedOn,
    this.parsedDate,
    required this.selectionKey,
  });
}

class ImportEntry {
  final String date;
  final String category;
  final String tag;
  final String remarks;
  final String description;
  final double amount;

  ImportEntry({
    required this.date,
    required this.category,
    required this.tag,
    required this.remarks,
    required this.description,
    required this.amount,
  });
}
