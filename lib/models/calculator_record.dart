class CalculatorRecord {
  const CalculatorRecord({
    this.id,
    required this.module,
    required this.createdAt,
    required this.inputSummary,
    required this.resultSummary,
    this.note = '',
  });

  final int? id;
  final String module;
  final DateTime createdAt;
  final String inputSummary;
  final String resultSummary;
  final String note;

  CalculatorRecord copyWith({
    int? id,
    String? module,
    DateTime? createdAt,
    String? inputSummary,
    String? resultSummary,
    String? note,
  }) {
    return CalculatorRecord(
      id: id ?? this.id,
      module: module ?? this.module,
      createdAt: createdAt ?? this.createdAt,
      inputSummary: inputSummary ?? this.inputSummary,
      resultSummary: resultSummary ?? this.resultSummary,
      note: note ?? this.note,
    );
  }

  factory CalculatorRecord.fromJson(Map<String, dynamic> json) {
    return CalculatorRecord(
      id: int.tryParse('${json['id'] ?? ''}'),
      module: '${json['module'] ?? ''}',
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      inputSummary: '${json['inputSummary'] ?? ''}',
      resultSummary: '${json['resultSummary'] ?? ''}',
      note: '${json['note'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'module': module,
        'createdAt': createdAt.toIso8601String(),
        'inputSummary': inputSummary,
        'resultSummary': resultSummary,
        'note': note,
      };
}

