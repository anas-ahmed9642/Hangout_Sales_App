import 'package:uuid/uuid.dart';

import '../models/customer.dart';
import '../models/customer_address.dart';
import 'customer_address_ops.dart';

const int _notesLimit = 300;
const int _deliveryNotesLimit = 200;

String _collapse(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ');

String _foldCase(String value) => _collapse(value).toLowerCase();

String _label(Customer customer) => customer.name ?? customer.phone;

/// What a merge will change on the TARGET customer. Pure data, computed
/// by [planCustomerMerge]. The merge screen previews it and the merge
/// repository applies it, so the logic exists exactly once.
class CustomerMergePlan {
  /// The TARGET's full address list after the merge.
  final List<CustomerAddress> addresses;

  /// The addresses taken over from SOURCE (a subset of [addresses]).
  final List<CustomerAddress> addressesToAdd;

  /// The TARGET's default address id after the merge (null = first).
  final String? defaultAddressId;

  /// The TARGET's internal notes after the merge.
  final String? notes;

  /// The TARGET's delivery notes after the merge.
  final String? deliveryNotes;

  /// True when SOURCE notes were appended to [notes].
  final bool notesChanged;

  /// True when SOURCE delivery notes were appended to [deliveryNotes].
  final bool deliveryNotesChanged;

  /// True when SOURCE notes did not fully fit the 300 character limit.
  /// The full text always stays on the archived SOURCE customer.
  final bool notesTruncated;

  /// True when SOURCE delivery notes did not fully fit the 200 limit.
  final bool deliveryNotesTruncated;

  /// The newer of the two customers' lastOrderAt.
  final DateTime? lastOrderAt;

  const CustomerMergePlan({
    required this.addresses,
    required this.addressesToAdd,
    required this.defaultAddressId,
    required this.notes,
    required this.deliveryNotes,
    required this.notesChanged,
    required this.deliveryNotesChanged,
    required this.notesTruncated,
    required this.deliveryNotesTruncated,
    required this.lastOrderAt,
  });
}

class _NoteMerge {
  final String? value;
  final bool changed;
  final bool truncated;

  const _NoteMerge(this.value, this.changed, this.truncated);
}

/// Appends [incoming] to [existing] without ever cutting into [existing].
/// Text that does not fit is shortened with an ellipsis (or left out when
/// there is no room); the full text stays on the archived SOURCE.
_NoteMerge _mergeNote({
  required String? existing,
  required String? incoming,
  required String separator,
  required int limit,
}) {
  final add = incoming?.trim();
  if (add == null || add.isEmpty) {
    return _NoteMerge(existing, false, false);
  }

  final base = existing?.trim();
  if (base == null || base.isEmpty) {
    if (add.length <= limit) return _NoteMerge(add, true, false);
    return _NoteMerge(
      '${add.substring(0, limit - 1).trimRight()}\u2026',
      true,
      true,
    );
  }

  if (base.toLowerCase().contains(add.toLowerCase())) {
    return _NoteMerge(base, false, false);
  }

  final room = limit - base.length - separator.length;
  if (room <= 0) return _NoteMerge(base, false, true);
  if (add.length <= room) {
    return _NoteMerge('$base$separator$add', true, false);
  }
  if (room < 2) return _NoteMerge(base, false, true);

  final cut = add.substring(0, room - 1).trimRight();
  return _NoteMerge('$base$separator$cut\u2026', true, true);
}

/// Why [source] cannot be merged into [target], or null when it can.
String? customerMergeBlocker({
  required Customer source,
  required Customer target,
}) {
  if (source.phone == target.phone) {
    return 'Choose two different customers.';
  }
  if (source.mergedInto != null) {
    return '${_label(source)} was already merged into ${source.mergedInto}.';
  }
  if (target.mergedInto != null) {
    return '${_label(target)} was merged into ${target.mergedInto} and '
        'cannot receive a merge.';
  }
  if (target.archived) {
    return '${_label(target)} is archived. Restore the customer first.';
  }
  return null;
}

/// Computes what merging [source] into [target] changes on the target:
/// addresses (union, de-duplicated by text), notes (appended), delivery
/// notes (appended) and lastOrderAt (the newer of the two).
CustomerMergePlan planCustomerMerge({
  required Customer source,
  required Customer target,
}) {
  final mergedAddresses = <CustomerAddress>[...target.addresses];
  final addressesToAdd = <CustomerAddress>[];
  final idMap = <String, String>{};

  for (final address in source.addresses) {
    final key = _foldCase(address.text);

    CustomerAddress? match;
    for (final existing in mergedAddresses) {
      if (_foldCase(existing.text) == key) {
        match = existing;
        break;
      }
    }
    if (match != null) {
      idMap[address.id] = match.id;
      continue;
    }

    final idTaken = mergedAddresses.any((existing) => existing.id == address.id);
    final added = idTaken ? address.copyWith(id: const Uuid().v4()) : address;
    mergedAddresses.add(added);
    addressesToAdd.add(added);
    idMap[address.id] = added.id;
  }

  String? defaultAddressId = target.defaultAddressId;
  if (target.addresses.isEmpty && mergedAddresses.isNotEmpty) {
    final sourceDefault = effectiveDefaultAddressId(source);
    defaultAddressId =
        (sourceDefault == null ? null : idMap[sourceDefault]) ??
            mergedAddresses.first.id;
  }

  final notes = _mergeNote(
    existing: target.notes,
    incoming: source.notes,
    separator: '\n',
    limit: _notesLimit,
  );
  final deliveryNotes = _mergeNote(
    existing: target.deliveryNotes,
    incoming: source.deliveryNotes,
    separator: '; ',
    limit: _deliveryNotesLimit,
  );

  DateTime? lastOrderAt = target.lastOrderAt;
  final sourceLast = source.lastOrderAt;
  if (sourceLast != null &&
      (lastOrderAt == null || sourceLast.isAfter(lastOrderAt))) {
    lastOrderAt = sourceLast;
  }

  return CustomerMergePlan(
    addresses: mergedAddresses,
    addressesToAdd: addressesToAdd,
    defaultAddressId: defaultAddressId,
    notes: notes.value,
    deliveryNotes: deliveryNotes.value,
    notesChanged: notes.changed,
    deliveryNotesChanged: deliveryNotes.changed,
    notesTruncated: notes.truncated,
    deliveryNotesTruncated: deliveryNotes.truncated,
    lastOrderAt: lastOrderAt,
  );
}
