import '../models/market_list.dart';
import '../widgets/expense_formatters.dart';

/// Builds ESC/POS bytes for a market list printout.
///
/// Layout: centered shop header, list date, one line per item
/// (name left, price right), dashed separators, bold total, footer note.
/// Item prices here are the ESTIMATES — the worker reconciles actuals after
/// shopping. Pure Dart: no printer dependency, fully unit-testable.
class MarketListReceiptBuilder {
  static const int lineWidth = 32;

  List<int> buildEstimate(MarketList list) {
    final bytes = <int>[];
    bytes.addAll(_init());
    bytes.addAll(_centered('HANGOUT'));
    bytes.addAll(_centered('MARKET LIST'));
    bytes.addAll(
      _centered('Date: ${formatExpenseDay(list.businessDate)}'),
    );
    bytes.addAll(_feed(1));
    bytes.addAll(_dashed());
    for (final item in list.items) {
      bytes.addAll(_row(item.itemName, formatExpenseRs(item.price)));
    }
    bytes.addAll(_dashed());
    bytes.addAll(_boldRow(
      'ESTIMATE TOTAL',
      formatExpenseRs(_total(list)),
    ));
    bytes.addAll(_feed(1));
    bytes.addAll(_centered('Hand this list + cash to the worker.'));
    bytes.addAll(_centered('Reconcile actual prices on return.'));
    bytes.addAll(_feed(2));
    bytes.addAll(_cut());
    return bytes;
  }

  double _total(MarketList list) {
    return list.items.fold<double>(0, (sum, item) => sum + item.price);
  }

  List<int> _init() => const [0x1B, 0x40];

  List<int> _cut() => const [0x1D, 0x56, 0x41, 0x03];

  List<int> _feed(int lines) => [0x1B, 0x64, lines.clamp(1, 255)];

  List<int> _alignCenter() => const [0x1B, 0x61, 0x01];

  List<int> _alignLeft() => const [0x1B, 0x61, 0x00];

  List<int> _boldOn() => const [0x1B, 0x45, 0x01];

  List<int> _boldOff() => const [0x1B, 0x45, 0x00];

  List<int> _text(String value) => value.codeUnits;

  List<int> _centered(String value) {
    return [..._alignCenter(), ..._text('$value\n'), ..._alignLeft()];
  }

  List<int> _dashed() {
    return [..._text('${'-' * lineWidth}\n')];
  }

  /// "Name ............ Rs. 450" padded/truncated to [lineWidth].
  List<int> _row(String name, String price) {
    final cleanName = name.length > lineWidth
        ? name.substring(0, lineWidth)
        : name;
    final gap = lineWidth - cleanName.length - price.length;
    final line = gap > 0 ? '$cleanName${' ' * gap}$price' : '$cleanName $price';
    return _text('$line\n');
  }

  List<int> _boldRow(String label, String value) {
    return [..._boldOn(), ..._row(label, value), ..._boldOff()];
  }
}
