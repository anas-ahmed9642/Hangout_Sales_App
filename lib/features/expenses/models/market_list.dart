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

  MarketListItem copyWith({
    String? itemName,
    double? price,
  }) {
    return MarketListItem(
      itemName: itemName ?? this.itemName,
      price: price ?? this.price,
    );
  }
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

  MarketList copyWith({
    String? id,
    List<MarketListItem>? items,
    double? total,
    MarketListStatus? status,
    bool? handedToWorker,
    String? reconciledExpenseId,
    DateTime? businessDate,
    DateTime? createdAt,
  }) {
    return MarketList(
      id: id ?? this.id,
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
      handedToWorker: handedToWorker ?? this.handedToWorker,
      reconciledExpenseId: reconciledExpenseId ?? this.reconciledExpenseId,
      businessDate: businessDate ?? this.businessDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
