/// One managed delivery sector (F12). Mirrors the expense catalog pattern:
/// areas are deactivated, never deleted, so historical orders keep a
/// valid area snapshot.
class DeliveryArea {
  /// Firestore auto id.
  final String id;

  /// Required, trimmed, unique case-insensitively ("Sector 5C/1").
  /// Uniqueness is enforced by the repository (Phase 2).
  final String name;

  /// Default delivery charge for the area. Must be greater than zero;
  /// the repository additionally requires it to be a value from
  /// `MenuData.deliveryCharges` (Phase 2).
  final double defaultCharge;

  /// Deactivate instead of delete.
  final bool active;

  final DateTime createdAt;

  DeliveryArea({
    required this.id,
    required String name,
    required this.defaultCharge,
    this.active = true,
    required this.createdAt,
  }) : name = name.trim() {
    if (this.name.isEmpty) {
      throw ArgumentError('Area name is required.');
    }
    if (defaultCharge <= 0) {
      throw ArgumentError('Default charge must be greater than zero.');
    }
  }

  DeliveryArea copyWith({
    String? id,
    String? name,
    double? defaultCharge,
    bool? active,
    DateTime? createdAt,
  }) {
    return DeliveryArea(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultCharge: defaultCharge ?? this.defaultCharge,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}