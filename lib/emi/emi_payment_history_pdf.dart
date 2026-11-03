import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../cc_emi/cc_emi_models.dart';
import 'loan_emi_models.dart';

Future<void> exportCcPaymentHistoryPdf(CreditCardEmiRecord record) async {
  final rows =
      record.repayments
          .map(
            (payment) => [
              payment.emiNumber.toString(),
              payment.paymentDate,
              _amount(payment.amountPaid),
              payment.paymentMode,
              payment.remarks,
            ],
          )
          .toList();
  await _shareHistoryPdf(
    fileName: 'cc_emi_${_filePart(record.cardName)}_payment_history.pdf',
    title: 'Credit Card EMI Payment History',
    subtitle: '${record.cardName} - ${record.merchantName}',
    headers: const ['EMI', 'Date', 'Amount (INR)', 'Mode', 'Notes'],
    rows: rows,
    total: record.repayments.fold(
      0.0,
      (sum, payment) => sum + payment.amountPaid,
    ),
  );
}

Future<void> exportLoanPaymentHistoryPdf(LoanEmiRecord record) async {
  final rows =
      record.payments
          .map(
            (payment) => [
              payment.paymentDate,
              _amount(payment.principalPaid),
              _amount(payment.interestPaid),
              _amount(payment.amountPaid),
              payment.paymentMode,
              payment.remarks,
            ],
          )
          .toList();
  await _shareHistoryPdf(
    fileName: 'loan_emi_${_filePart(record.lender)}_payment_history.pdf',
    title: 'Loan EMI Payment History',
    subtitle:
        '${record.lender} - ${record.type.label} - ${record.accountNumber}',
    headers: const [
      'Date',
      'Principal (INR)',
      'Interest (INR)',
      'Paid (INR)',
      'Mode',
      'Notes',
    ],
    rows: rows,
    total: record.payments.fold(
      0.0,
      (sum, payment) => sum + payment.amountPaid,
    ),
  );
}

Future<void> _shareHistoryPdf({
  required String fileName,
  required String title,
  required String subtitle,
  required List<String> headers,
  required List<List<String>> rows,
  required double total,
}) async {
  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      footer:
          (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 12),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
      build:
          (context) => [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              _pdfText(subtitle),
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Generated: ${DateTime.now().toLocal().toString().split(' ').first}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 18),
            pw.TableHelper.fromTextArray(
              headers: headers.map(_pdfText).toList(),
              data:
                  rows.isEmpty
                      ? [
                        [
                          'No payment records',
                          ...List.filled(headers.length - 1, ''),
                        ],
                      ]
                      : rows.map((row) => row.map(_pdfText).toList()).toList(),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF4F46E5),
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellHeight: 26,
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF3F4F6),
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total payments: ${rows.length}    Total paid: INR ${_amount(total)}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
    ),
  );
  await Printing.sharePdf(bytes: await document.save(), filename: fileName);
}

String _amount(double value) => value.toStringAsFixed(2);

String _filePart(String input) {
  final safe = input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return safe.replaceAll(RegExp(r'^_+|_+$'), '').isEmpty
      ? 'record'
      : safe.replaceAll(RegExp(r'^_+|_+$'), '');
}

String _pdfText(String input) => input.replaceAll(RegExp(r'[^\x20-\x7E]'), '?');
