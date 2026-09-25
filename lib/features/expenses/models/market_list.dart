enum MarketListStatus {
  draft,
  confirmed,
}

class MarketListItem {
  final String itemName;
  final double price;

  const MarketListItem({
    required this.itemName,
    required this.price,
  });
}

class MarketList {
  final String id;
  final List<MarketListItem> items;
  final double total;
  final MarketListStatus status;
  final bool handedToWorker;
  final String? reconciledExpenseId;
  final DateTime businessDate;
  final DateTime createdAt;

  const MarketList({
    required this.id,
    required this.items,
    required this.total,
    this.status = MarketListStatus.draft,
    this.handedToWorker = false,
    this.reconciledExpenseId,
    required this.businessDate,
    required this.createdAt,
  });
}