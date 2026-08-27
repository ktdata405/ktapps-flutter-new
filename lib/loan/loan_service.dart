import 'dart:convert';
import 'package:http/http.dart' as http;
import 'loan_models.dart';

class LoanService {
  static const String _endpoint =
      'https://script.google.com/macros/s/AKfycbwnRs1td_3N8I1LVjHfXRAgcKWCDW8mbrBHJ4hADlHmihWDOco_7kDiO_qxKbNK1pfx/exec';

  Future<List<LoanRecord>> fetchLoans() async {
    try {
      final response = await http.get(Uri.parse('$_endpoint?action=getLoans&t=${DateTime.now().millisecondsSinceEpoch}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final List<dynamic> list = data['data'];
          return list.map((item) => LoanRecord.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching loans: $e');
      return [];
    }
  }

  Future<bool> addLoan(LoanRecord loan) async {
    try {
      final payload = loan.toJson();
      payload['action'] = 'addLoan';
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: json.encode(payload),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error adding loan: $e');
      return false;
    }
  }

  Future<bool> updateLoan(LoanRecord loan) async {
    try {
      final payload = loan.toJson();
      payload['action'] = 'updateLoan';
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: json.encode(payload),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error updating loan: $e');
      return false;
    }
  }

  Future<List<RepaymentStatus>> getRepaymentStatus(String loanId) async {
    try {
      final response = await http.get(Uri.parse('$_endpoint?action=getRepaymentStatus&loanId=$loanId&t=${DateTime.now().millisecondsSinceEpoch}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final List<dynamic> list = data['data'];
          return list.map((item) => RepaymentStatus.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting repayment status: $e');
      return [];
    }
  }

  Future<bool> updateRepaymentStatus(String loanId, int year, int month, String status) async {
    try {
      final payload = {
        'action': 'updateRepaymentStatus',
        'loanId': loanId,
        'year': year,
        'month': month,
        'status': status,
      };
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: json.encode(payload),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error updating repayment status: $e');
      return false;
    }
  }

  Future<bool> addTransaction(String loanId, double amount, String date, String type, String remarks) async {
    try {
      final payload = {
        'action': 'addTransaction',
        'loanId': loanId,
        'amount': amount,
        'date': date,
        'type': type,
        'remarks': remarks,
      };
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: json.encode(payload),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error adding transaction: $e');
      return false;
    }
  }
}
