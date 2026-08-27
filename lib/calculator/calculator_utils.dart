import 'package:intl/intl.dart';

class CalculatorUtils {
  static String formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0).format(amount);
  }

  static String numberToWords(int n) {
    if (n < 0) return "Minus ${numberToWords(-n)}";
    if (n == 0) return "Zero";

    const units = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
    const tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];

    String convert(int num) {
      if (num < 20) return units[num];
      if (num < 100) return tens[num ~/ 10] + (num % 10 != 0 ? " ${units[num % 10]}" : "");
      if (num < 1000) return "${units[num ~/ 100]} Hundred${num % 100 != 0 ? " and ${convert(num % 100)}" : ""}";
      if (num < 100000) return "${convert(num ~/ 1000)} Thousand${num % 1000 != 0 ? " ${convert(num % 1000)}" : ""}";
      if (num < 10000000) return "${convert(num ~/ 100000)} Lakh${num % 100000 != 0 ? " ${convert(num % 100000)}" : ""}";
      return "${convert(num ~/ 10000000)} Crore${num % 10000000 != 0 ? " ${convert(num % 10000000)}" : ""}";
    }

    return convert(n);
  }
}
