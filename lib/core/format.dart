import 'package:intl/intl.dart';

final _money = NumberFormat('#,##0.00', 'en_US');
final _moneyShort = NumberFormat('#,##0', 'en_US');

String money(num value) => 'Rs. ${_money.format(value)}';
String moneyShort(num value) => 'Rs. ${_moneyShort.format(value)}';

DateTime? parseDate(String? iso) => iso == null ? null : DateTime.tryParse(iso)?.toLocal();

String formatDate(String? iso) {
  final d = parseDate(iso);
  return d == null ? '—' : DateFormat('d MMM yyyy').format(d);
}

String formatDateTime(String? iso) {
  final d = parseDate(iso);
  return d == null ? '—' : DateFormat('d MMM yyyy, h:mm a').format(d);
}

String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

String plural(int n, String word) => '$n ${n == 1 ? word : '${word}s'}';
