import 'package:uuid/uuid.dart';

import '../../../core/utils/map_link_helper.dart';

/// One saved address of a customer (F22). A customer can hold several
/// addresses; the first UI phase shows a single address, but the list
/// exists from day one so later phases never migrate data.
class CustomerAddress {
  /// Generated id (uuid). Stable once created.
  final String id;

  /// Short label ("Home", "Office", free text), max 20 chars.
  /// Missing or blank defaults to "Home".
  final String label;

  /// The address text. Required, max 200 chars.
  final String text;

  /// Google Maps link or coordinates, validated by [MapLinkHelper].
  /// Stored raw; null when the address has no link.
  final String? mapLink;

  /// References `deliveryAreas/{id}`; null = unlisted area.
  final String? areaId;

  static const _sentinel = Object();

  CustomerAddress({
    required this.id,
    String? label,
    required String text,
    this.mapLink,
    this.areaId,
  })  : label = _normalizeLabel(label),
        text = text.trim() {
    if (this.text.isEmpty) {
      throw ArgumentError('Address text is required.');
    }
    if (this.text.length > 200) {
      throw ArgumentError('Address text must be at most 200 characters.');
    }
    final link = mapLink;
    if (link != null && MapLinkHelper.parse(link) == null) {
      throw ArgumentError('Not a recognized Google Maps link or coordinates.');
    }
  }

  /// Creates an address with a generated [id] (uuid) and the "Home"
  /// label default applied.
  factory CustomerAddress.create({
    String? label,
    required String text,
    String? mapLink,
    String? areaId,
  }) {
    return CustomerAddress(
      id: const Uuid().v4(),
      label: label,
      text: text,
      mapLink: mapLink,
      areaId: areaId,
    );
  }

  static String _normalizeLabel(String? label) {
    final trimmed = (label ?? '').trim();
    if (trimmed.isEmpty) return 'Home';
    if (trimmed.length > 20) {
      throw ArgumentError('Address label must be at most 20 characters.');
    }
    return trimmed;
  }

  CustomerAddress copyWith({
    String? id,
    Object? label = _sentinel,
    String? text,
    Object? mapLink = _sentinel,
    Object? areaId = _sentinel,
  }) {
    return CustomerAddress(
      id: id ?? this.id,
      label: label == _sentinel ? this.label : label as String?,
      text: text ?? this.text,
      mapLink: mapLink == _sentinel ? this.mapLink : mapLink as String?,
      areaId: areaId == _sentinel ? this.areaId : areaId as String?,
    );
  }
}