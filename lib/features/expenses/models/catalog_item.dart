import 'expense_category.dart';

class CatalogItem {
  final String id;
  final ExpenseCategory category;
  final String name;
  final String? brand;
  final String? size;
  final bool active;
  final DateTime createdAt;

  const CatalogItem({
    required this.id,
    required this.category,
    required this.name,
    this.brand,
    this.size,
    required this.active,
    required this.createdAt,
  });

  CatalogItem copyWith({
    String? id,
    ExpenseCategory? category,
    String? name,
    String? brand,
    String? size,
    bool? active,
    DateTime? createdAt,
  }) {
    return CatalogItem(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      size: size ?? this.size,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}