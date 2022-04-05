import 'package:intl/intl.dart';

class FormatDate {
  String format(DateTime date) {
    return DateFormat('dd MMMM', 'fr').format(date);
  }

  String formatMinute(DateTime date) {
    return DateFormat('HH:mm', 'fr').format(date);
  }

  String formatTicket(DateTime date) {
    return DateFormat('dd MMMM y HH:mm', 'fr').format(date);
  }
}
