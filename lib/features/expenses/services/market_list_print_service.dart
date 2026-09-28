import '../../orders/services/order_receipt_service.dart';
import '../models/market_list.dart';
import 'market_list_receipt_builder.dart';

/// Prints a market list through the SAME printer stack orders use.
/// Throws whatever the underlying transport throws on failure.
class MarketListPrintService {
  MarketListPrintService({
    OrderReceiptService? orderReceiptService,
    MarketListReceiptBuilder? receiptBuilder,
  })  : _orderReceiptService = orderReceiptService ?? OrderReceiptService(),
        _receiptBuilder = receiptBuilder ?? MarketListReceiptBuilder();

  final OrderReceiptService _orderReceiptService;
  final MarketListReceiptBuilder _receiptBuilder;

  Future<void> printEstimate(MarketList list) async {
    final bytes = _receiptBuilder.buildEstimate(list);
    await _orderReceiptService.printBytes(bytes);
  }
}
