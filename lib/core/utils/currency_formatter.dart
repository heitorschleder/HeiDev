import 'package:intl/intl.dart';

final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

String formatBRL(double value) => _fmt.format(value);
