import '../models/rent_record.dart';
import '../models/msi_record.dart';
import '../models/debt_record.dart';
import '../models/loan_record.dart';
import '../models/calculator_record.dart';
import '../models/cashew_record.dart';
import '../models/denomination_record.dart';

class ApiService {
  static const List<int> _denomValues = [500, 200, 100, 50, 20, 10, 5, 2, 1];

  // ════════════════════════════════════════════
  //  RENT – existing
  // ════════════════════════════════════════════
  static final List<RentRecord> _records = <RentRecord>[
    const RentRecord(
      date: '05/Aug/2026',
      side: 'Kalyan',
      rentAmount: 12000,
      paidAmount: 10000,
      balanceAmount: 2000,
      powerBill: 900,
      waterBill: 250,
      remarks: 'Pending balance to be settled next week',
    ),
    const RentRecord(
      date: '02/Aug/2026',
      side: 'Srikanth',
      rentAmount: 11000,
      paidAmount: 11000,
      balanceAmount: 0,
      powerBill: 760,
      waterBill: 220,
      remarks: '-',
    ),
  ];

  static Future<Map<String, dynamic>> fetchRentData() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return {
      'data': List<RentRecord>.from(_records),
    };
  }

  static Future<void> saveRentPayload(Map<String, dynamic> payload) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final action = (payload['action'] ?? 'create').toString();

    if (action == 'delete') {
      final originalDate = (payload['originalDate'] ?? '').toString();
      final originalSide = (payload['originalSide'] ?? '').toString();
      _records
          .removeWhere((r) => r.date == originalDate && r.side == originalSide);
      return;
    }

    final newRecord = RentRecord.fromJson(payload);

    if (action == 'update') {
      final originalDate = (payload['originalDate'] ?? '').toString();
      final originalSide = (payload['originalSide'] ?? '').toString();
      final index = _records.indexWhere(
        (r) => r.date == originalDate && r.side == originalSide,
      );
      if (index >= 0) {
        _records[index] = newRecord;
      } else {
        _records.add(newRecord);
      }
      return;
    }

    _records.add(newRecord);
  }

  // ════════════════════════════════════════════
  //  MSI – Monthly SIP Investments
  // ════════════════════════════════════════════
  static final Map<String, List<MsiRecord>> _msiRecords = {
    'Kalyan': [
      const MsiRecord(
        month: 'Jun',
        year: '2026',
        user: 'Kalyan',
        coinQuantumLiquid: 1331,
        coinNaviNifty: 1331,
        coinInvescoSmall: 1331,
        coinAxisNifty: 1331,
        coinBirlaNifty: 1331,
        coinDspNifty: 1331,
        coinEdelweissBond: 1331,
        coinCanaraSmall: 6050,
        npsTier1: 5500,
        ssaAccount: 2500,
        ppfAccount: 10000,
      ),
      const MsiRecord(
        month: 'Jul',
        year: '2026',
        user: 'Kalyan',
        coinQuantumLiquid: 1331,
        coinNaviNifty: 1331,
        coinInvescoSmall: 1331,
        coinAxisNifty: 1331,
        coinBirlaNifty: 1331,
        coinDspNifty: 1331,
        coinEdelweissBond: 1331,
        coinCanaraSmall: 6050,
        npsTier1: 5500,
        ssaAccount: 2500,
        ppfAccount: 10000,
        njAxisMidcap: 2000,
        njDspMidcap: 2000,
        njInvescoMidcap: 2000,
      ),
      const MsiRecord(
        month: 'Aug',
        year: '2026',
        user: 'Kalyan',
        coinQuantumLiquid: 1331,
        coinNaviNifty: 1331,
        coinInvescoSmall: 1331,
        coinAxisNifty: 1331,
        coinBirlaNifty: 1331,
        coinDspNifty: 1331,
        coinEdelweissBond: 1331,
        coinCanaraSmall: 6050,
        npsTier1: 5500,
        ssaAccount: 2500,
        ppfAccount: 10000,
        njAxisMidcap: 2000,
        njDspMidcap: 2000,
        njInvescoMidcap: 2000,
        njKotakEmerging: 1500,
        njNipponGrowth: 1500,
      ),
    ],
    'Layan': [
      const MsiRecord(
        month: 'Jul',
        year: '2026',
        user: 'Layan',
        indJioFlexi: 1000,
        indBandhanSmall: 500,
      ),
      const MsiRecord(
        month: 'Aug',
        year: '2026',
        user: 'Layan',
        indJioFlexi: 1000,
        indBandhanSmall: 500,
        indNtpcGreen: 250,
      ),
    ],
  };

  static Future<List<MsiRecord>> fetchMsiData(String user) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List<MsiRecord>.from(_msiRecords[user] ?? []);
  }

  static Future<void> saveMsiRecord(Map<String, dynamic> payload) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final user = (payload['user_select'] ?? 'Kalyan').toString();
    final month = (payload['month'] ?? '').toString();
    final year = (payload['year'] ?? '').toString();

    _msiRecords.putIfAbsent(user, () => []);
    final records = _msiRecords[user]!;
    final newRecord = MsiRecord.fromJson(payload);

    final idx = records.indexWhere((r) => r.month == month && r.year == year);
    if (idx >= 0) {
      records[idx] = newRecord;
    } else {
      records.add(newRecord);
    }

    // Sort chronologically
    const mo = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    records.sort((a, b) {
      final ya = int.tryParse(a.year) ?? 0;
      final yb = int.tryParse(b.year) ?? 0;
      if (ya != yb) return ya.compareTo(yb);
      return (mo[a.month] ?? 0).compareTo(mo[b.month] ?? 0);
    });
  }

  // ════════════════════════════════════════════
  //  DEBTS
  // ════════════════════════════════════════════
  static int _nextDebtId = 4;
  static final List<DebtRecord> _debts = <DebtRecord>[
    const DebtRecord(
      id: 1,
      date: '04/Aug/2026',
      type: 'given',
      person: 'Ravi',
      amount: 12000,
      remarks: 'House advance',
      status: 'pending',
      settleRemarks: '',
    ),
    const DebtRecord(
      id: 2,
      date: '28/Jul/2026',
      type: 'taken',
      person: 'Anil',
      amount: 4500,
      remarks: 'Emergency medical payment',
      status: 'pending',
      settleRemarks: '',
    ),
    const DebtRecord(
      id: 3,
      date: '21/Jul/2026',
      type: 'given',
      person: 'Ravi',
      amount: 2500,
      remarks: 'Fuel amount',
      status: 'settled',
      settleRemarks: 'Paid in cash',
    ),
  ];

  static Future<List<DebtRecord>> fetchDebts() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return List<DebtRecord>.from(_debts);
  }

  static Future<DebtRecord?> getDebtById(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    try {
      return _debts.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<DebtRecord> saveDebt(Map<String, dynamic> payload) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));

    final input = DebtRecord.fromJson(payload);
    final existingId = input.id;
    if (existingId != null) {
      final i = _debts.indexWhere((d) => d.id == existingId);
      if (i >= 0) {
        _debts[i] = input;
        return input;
      }
    }

    final created = input.copyWith(
      id: _nextDebtId++,
      status: 'pending',
      settleRemarks: input.settleRemarks,
    );
    _debts.add(created);
    return created;
  }

  static Future<void> updateDebtStatus(
    int id, {
    required String status,
    String? settleRemarks,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final i = _debts.indexWhere((d) => d.id == id);
    if (i < 0) return;

    final normalizedStatus =
        status.toLowerCase() == 'settled' ? 'settled' : 'pending';
    _debts[i] = _debts[i].copyWith(
      status: normalizedStatus,
      settleRemarks: settleRemarks ?? _debts[i].settleRemarks,
    );
  }

  static Future<void> deleteDebt(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _debts.removeWhere((d) => d.id == id);
  }

  // ════════════════════════════════════════════
  //  LOANS
  // ════════════════════════════════════════════
  static int _nextLoanSeq = 3;

  static final List<LoanRecord> _loans = <LoanRecord>[
    const LoanRecord(
      id: 'loan-001',
      date: '15/Jan/2026',
      name: 'Suresh Kumar',
      amount: 200000,
      interestRate: 12.0,
      tenureValue: 24,
      tenureType: 'Months',
      type: 'Given',
      status: 'Active',
      remarks: 'House renovation loan',
      paid: 60000,
    ),
    const LoanRecord(
      id: 'loan-002',
      date: '01/Mar/2026',
      name: 'HDFC Personal',
      amount: 500000,
      interestRate: 9.5,
      tenureValue: 60,
      tenureType: 'Months',
      type: 'Taken',
      status: 'Active',
      remarks: 'Personal loan – EMI auto-debit',
      paid: 45000,
    ),
  ];

  static final Map<String, List<RepaymentMonth>> _repayments = {
    'loan-001': [
      const RepaymentMonth(
          loanId: 'loan-001', year: 2026, month: 1, status: 'Done'),
      const RepaymentMonth(
          loanId: 'loan-001', year: 2026, month: 2, status: 'Done'),
      const RepaymentMonth(
          loanId: 'loan-001', year: 2026, month: 3, status: 'Done'),
    ],
    'loan-002': [
      const RepaymentMonth(
          loanId: 'loan-002', year: 2026, month: 3, status: 'Done'),
      const RepaymentMonth(
          loanId: 'loan-002', year: 2026, month: 4, status: 'Done'),
      const RepaymentMonth(
          loanId: 'loan-002', year: 2026, month: 5, status: 'Done'),
    ],
  };

  static Future<List<LoanRecord>> fetchLoans() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List<LoanRecord>.from(_loans);
  }

  static Future<LoanRecord> saveLoan(Map<String, dynamic> payload) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));

    final record = LoanRecord.fromJson(payload);
    final isUpdate = (payload['action'] ?? '').toString() == 'updateLoan';

    if (isUpdate && record.id != null) {
      final i = _loans.indexWhere((l) => l.id == record.id);
      if (i >= 0) {
        // Preserve paid amount when editing loan metadata
        _loans[i] = record.copyWith(paid: _loans[i].paid);
        return _loans[i];
      }
    }

    final newId = 'loan-${_nextLoanSeq.toString().padLeft(3, '0')}';
    _nextLoanSeq++;
    final created = record.copyWith(id: newId, paid: 0);
    _loans.add(created);
    return created;
  }

  static Future<void> deleteLoan(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _loans.removeWhere((l) => l.id == id);
    _repayments.remove(id);
  }

  static Future<List<RepaymentMonth>> fetchRepaymentStatus(
      String loanId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return List<RepaymentMonth>.from(_repayments[loanId] ?? []);
  }

  static Future<void> updateRepaymentStatus(
    String loanId,
    int year,
    int month,
    String status,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _repayments.putIfAbsent(loanId, () => []);
    final list = _repayments[loanId]!;
    final i = list.indexWhere((r) => r.year == year && r.month == month);
    if (i >= 0) {
      list[i] = list[i].copyWith(status: status);
    } else {
      list.add(RepaymentMonth(
          loanId: loanId, year: year, month: month, status: status));
    }
  }

  static Future<void> addLoanPayment(Map<String, dynamic> payload) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));

    final loanId = (payload['loanId'] ?? '').toString();
    final amount = double.tryParse('${payload['amount'] ?? 0}') ?? 0;
    final payType = (payload['type'] ?? 'EMI').toString();

    final i = _loans.indexWhere((l) => l.id == loanId);
    if (i >= 0) {
      final newPaid = _loans[i].paid + amount;
      final newStatus =
          payType == 'Full Settlement' ? 'Closed' : _loans[i].status;
      _loans[i] = _loans[i].copyWith(paid: newPaid, status: newStatus);
    }
  }

  // ════════════════════════════════════════════
  //  CALCULATOR HISTORY
  // ════════════════════════════════════════════
  static int _nextCalculatorId = 3;
  static final List<CalculatorRecord> _calculatorRecords = <CalculatorRecord>[
    CalculatorRecord(
      id: 1,
      module: 'Land',
      createdAt: DateTime(2026, 8, 13, 10, 40),
      inputSummary: 'Regular • L=60 ft, W=40 ft',
      resultSummary: '2400 sq.ft • 2.67 cents • 266.67 gajalu',
      note: 'East-facing plot',
    ),
    CalculatorRecord(
      id: 2,
      module: 'Flat/Reducing',
      createdAt: DateTime(2026, 8, 13, 12, 10),
      inputSummary: 'Reducing • P=₹3,00,000 • R=18% • T=24 months',
      resultSummary: 'EMI ₹14,969 • Interest ₹59,252 • Total ₹3,59,252',
      note: '',
    ),
  ];

  static Future<List<CalculatorRecord>> fetchCalculatorRecords() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final rows = List<CalculatorRecord>.from(_calculatorRecords);
    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rows;
  }

  static Future<CalculatorRecord> saveCalculatorRecord(
      Map<String, dynamic> payload) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final input = CalculatorRecord.fromJson(payload);
    final created = input.copyWith(
      id: _nextCalculatorId++,
      createdAt: input.createdAt.millisecondsSinceEpoch == 0
          ? DateTime.now()
          : input.createdAt,
    );
    _calculatorRecords.add(created);
    return created;
  }

  static Future<void> deleteCalculatorRecord(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _calculatorRecords.removeWhere((r) => r.id == id);
  }

  static Future<void> clearCalculatorRecords() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _calculatorRecords.clear();
  }

  // ════════════════════════════════════════════
  //  CASHEW
  // ════════════════════════════════════════════
  static final List<CashewRecord> _cashewRecords = <CashewRecord>[
    const CashewRecord(
      date: '13/Aug/2026',
      category: 'Home',
      description: 'Groceries and vegetables',
      amount: 1450,
      status: 'completed',
    ),
    const CashewRecord(
      date: '13/Aug/2026',
      category: 'My Family',
      description: 'School stationery',
      amount: 620,
      status: 'completed',
    ),
    const CashewRecord(
      date: '12/Aug/2026',
      category: 'My Personal',
      description: 'Fuel and snacks',
      amount: 780,
      status: 'draft',
    ),
  ];

  static Future<List<CashewRecord>> fetchCashewRecords() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return List<CashewRecord>.from(_cashewRecords)
      ..sort(
          (a, b) => _parseDdMmmYyyy(b.date).compareTo(_parseDdMmmYyyy(a.date)));
  }

  static Future<List<CashewRecord>> fetchCashewRecordsByDate(
      String date) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _cashewRecords.where((r) => r.date == date).toList();
  }

  static Future<void> saveCashewRecordsForDate({
    required String date,
    required List<CashewRecord> records,
    required String status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    _cashewRecords.removeWhere((r) => r.date == date);
    final normalized = status.toLowerCase() == 'draft' ? 'draft' : 'completed';
    for (final r in records) {
      _cashewRecords.add(r.copyWith(date: date, status: normalized));
    }
  }

  static Future<Map<String, double>> fetchCashewSummary() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final total = _cashewRecords.fold<double>(0, (sum, r) => sum + r.amount);
    final distinctDays =
        _cashewRecords.map((r) => r.date).toSet().length.toDouble();
    final completed = _cashewRecords
        .where((r) => r.status.toLowerCase() == 'completed')
        .fold<double>(0, (sum, r) => sum + r.amount);
    return {
      'total': total,
      'days': distinctDays,
      'completedTotal': completed,
    };
  }

  // ════════════════════════════════════════════
  //  DENOMINATIONS
  // ════════════════════════════════════════════
  static final List<DenominationRecord> _denominationRecords =
      <DenominationRecord>[
    DenominationRecord(
      date: '13/Aug/2026',
      counts: const {
        500: 10,
        200: 3,
        100: 5,
        50: 2,
        20: 1,
        10: 0,
        5: 4,
        2: 6,
        1: 3
      },
      weekExpenses: 3500,
      adjustAmount: 250,
      atmWithdrawal: 5000,
      acPaid: 2555,
      availableBalance: 122555,
      remarks: 'Temple offerings collected',
      total: 5805,
    ),
    DenominationRecord(
      date: '12/Aug/2026',
      counts: const {
        500: 7,
        200: 4,
        100: 2,
        50: 1,
        20: 2,
        10: 3,
        5: 6,
        2: 3,
        1: 1
      },
      weekExpenses: 2200,
      adjustAmount: 0,
      atmWithdrawal: 3000,
      acPaid: 1905,
      availableBalance: 120000,
      remarks: 'Weekend update',
      total: 4105,
    ),
  ];

  /// Returns a map with keys `reports` (List<DenominationRecord>) and
  /// `sheet2Data` (double available balance) optionally filtered by [month].
  static Future<Map<String, dynamic>> fetchReports(String month) async {
    final all = await fetchDenominationReports();
    final filtered = month.isEmpty
        ? all
        : all.where((r) {
            try {
              final dt = _parseDdMmmYyyy(r.date);
              final label =
                  '${_monthName(dt.month)} ${dt.year}';
              return label.toLowerCase() == month.toLowerCase();
            } catch (_) {
              return true;
            }
          }).toList();
    final sheet2Data = filtered.isEmpty ? 0.0 : filtered.first.availableBalance;
    return {'reports': filtered, 'sheet2Data': sheet2Data};
  }

  static String _monthName(int month) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return month >= 1 && month <= 12 ? names[month] : '';
  }

  static Future<List<DenominationRecord>> fetchDenominationReports() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return List<DenominationRecord>.from(_denominationRecords)
      ..sort(
          (a, b) => _parseDdMmmYyyy(b.date).compareTo(_parseDdMmmYyyy(a.date)));
  }

  static Future<DenominationRecord?> fetchDenominationByDate(
      String date) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    try {
      return _denominationRecords.firstWhere((r) => r.date == date);
    } catch (_) {
      return null;
    }
  }

  static Future<double> fetchDenominationPreviousBalance(String date) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final target = _parseDdMmmYyyy(date);
    DenominationRecord? best;
    for (final row in _denominationRecords) {
      final rowDate = _parseDdMmmYyyy(row.date);
      if (rowDate.isBefore(target)) {
        if (best == null || _parseDdMmmYyyy(best.date).isBefore(rowDate)) {
          best = row;
        }
      }
    }
    return best?.availableBalance ?? 0;
  }

  static Future<void> saveDenominationRecord(DenominationRecord record) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    final index = _denominationRecords.indexWhere((r) => r.date == record.date);
    if (index >= 0) {
      _denominationRecords[index] = record;
    } else {
      _denominationRecords.add(record);
    }
  }

  static double computeDenominationTotal(Map<int, int> counts) {
    var total = 0.0;
    for (final value in _denomValues) {
      total += (counts[value] ?? 0) * value;
    }
    return total;
  }

  static DateTime _parseDdMmmYyyy(String value) {
    final m = RegExp(r'^(\d{2})/(\w{3})/(\d{4})$').firstMatch(value.trim());
    if (m == null) return DateTime(1970);
    const mo = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final d = int.tryParse(m.group(1) ?? '') ?? 1;
    final month = mo[m.group(2)] ?? 1;
    final y = int.tryParse(m.group(3) ?? '') ?? 1970;
    return DateTime(y, month, d);
  }
}
