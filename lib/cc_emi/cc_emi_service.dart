import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'cc_emi_models.dart';

class CcEmiService {
  // Paste your deployed Google Apps Script Web App URL here:
  static const String _endpoint = 'https://script.google.com/macros/s/AKfycbwKhsAioFfpz_biws3Xkox3VYHZqFyhMX90ct_GWMPD-M5UAWaNF6lUzEqPL3Isn5I7/exec';

  /// Fetches all Credit Card EMI records directly from Google Sheets
  Future<List<CreditCardEmiRecord>> fetchRecords() async {
    if (_endpoint.isEmpty) {
      debugPrint('Google Apps Script _endpoint URL is empty.');
      return [];
    }
    try {
      final uri = Uri.parse('$_endpoint?action=list&t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(uri);
      if (response.statusCode < 400) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          final records = list
              .map((item) => CreditCardEmiRecord.fromJson(item as Map<String, dynamic>))
              .toList();
          records.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
          return records;
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching Credit Card EMI records from Google Sheets: $e');
      return [];
    }
  }

  /// Saves or updates a Credit Card EMI record directly on Google Sheets
  Future<bool> saveRecord(CreditCardEmiRecord record) async {
    if (_endpoint.isEmpty) {
      debugPrint('Google Apps Script _endpoint URL is empty.');
      return false;
    }
    try {
      final isNew = record.id == null || record.id!.isEmpty;
      final id = record.id ?? DateTime.now().millisecondsSinceEpoch.toString();

      final Map<String, String> params = {
        'action': isNew ? 'addCcEmi' : 'updateCcEmi',
        'id': id,
        'cardName': record.cardName,
        'merchantName': record.merchantName,
        'purchaseDate': record.purchaseDate,
        'totalAmount': record.totalAmount.toString(),
        'interestRate': record.interestRate.toString(),
        'tenureMonths': record.tenureMonths.toString(),
        'monthlyEmi': record.monthlyEmi.toString(),
        'processingFee': record.processingFee.toString(),
        'totalInterest': record.totalInterest.toString(),
        'totalPayable': record.totalPayable.toString(),
        'emisPaid': record.emisPaid.toString(),
        'dueDay': record.dueDay.toString(),
        'firstEmiDate': record.firstEmiDate,
        'status': record.status,
        'category': record.category,
        'remarks': record.remarks,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final uri = Uri.parse(_endpoint).replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode < 400) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error saving Credit Card EMI record to Google Sheets: $e');
      return false;
    }
  }

  /// Deletes a Credit Card EMI record directly on Google Sheets
  Future<bool> deleteRecord(String id) async {
    if (_endpoint.isEmpty) {
      debugPrint('Google Apps Script _endpoint URL is empty.');
      return false;
    }
    try {
      final Map<String, String> params = {
        'action': 'deleteCcEmi',
        'id': id,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      final uri = Uri.parse(_endpoint).replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode < 400) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting Credit Card EMI record from Google Sheets: $e');
      return false;
    }
  }

  /// Records an EMI payment transaction directly on Google Sheets
  Future<bool> recordPayment(String emiId, EmiPaymentRecord payment) async {
    if (_endpoint.isEmpty) {
      debugPrint('Google Apps Script _endpoint URL is empty.');
      return false;
    }
    try {
      final Map<String, String> params = {
        'action': 'recordPayment',
        'id': payment.id,
        'emiRecordId': emiId,
        'emiNumber': payment.emiNumber.toString(),
        'paymentDate': payment.paymentDate,
        'amountPaid': payment.amountPaid.toString(),
        'paymentMode': payment.paymentMode,
        'remarks': payment.remarks,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      final uri = Uri.parse(_endpoint).replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode < 400) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error recording payment on Google Sheets: $e');
      return false;
    }
  }
}
