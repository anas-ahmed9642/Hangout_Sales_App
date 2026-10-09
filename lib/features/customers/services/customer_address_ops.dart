import '../models/customer.dart';
import '../models/customer_address.dart';

/// The result of an address-list change: the new list and the new
/// default address id.
class AddressListUpdate {
  final List<CustomerAddress> addresses;
  final String? defaultAddressId;

  const AddressListUpdate(this.addresses, this.defaultAddressId);
}

/// The address treated as default: the explicit
/// [Customer.defaultAddressId] when it names an entry, otherwise
/// the first address, or null when there are none. (Same rule the
/// Customers list card uses.)
String? effectiveDefaultAddressId(Customer customer) {
  final addresses = customer.addresses;
  if (addresses.isEmpty) {
    return null;
  }
  final id = customer.defaultAddressId;
  if (id != null && addresses.any((address) => address.id == id)) {
    return id;
  }
  return addresses.first.id;
}

/// Appends [address]. It becomes the default when the customer had
/// no addresses or when [makeDefault] is true; otherwise the
/// existing default is kept.
AddressListUpdate addAddress(
  Customer customer,
  CustomerAddress address, {
  required bool makeDefault,
}) {
  final addresses = [...customer.addresses, address];
  final defaultId = (customer.addresses.isEmpty || makeDefault)
      ? address.id
      : customer.defaultAddressId;
  return AddressListUpdate(addresses, defaultId);
}

/// Replaces the address with the same id. Becomes the default when
/// [makeDefault] is true; otherwise the default is kept.
AddressListUpdate replaceAddress(
  Customer customer,
  CustomerAddress address, {
  required bool makeDefault,
}) {
  final addresses = [
    for (final existing in customer.addresses)
      existing.id == address.id ? address : existing,
  ];
  return AddressListUpdate(
    addresses,
    makeDefault ? address.id : customer.defaultAddressId,
  );
}

/// Marks [addressId] as the default; the list is unchanged.
AddressListUpdate setDefaultAddress(Customer customer, String addressId) {
  return AddressListUpdate(customer.addresses, addressId);
}

/// Removes [addressId]. Removing the (effective) default promotes
/// the first remaining address; removing the last address leaves an
/// empty list and a null default — a valid customer (plan 8.12).
AddressListUpdate removeAddress(Customer customer, String addressId) {
  final wasDefault = effectiveDefaultAddressId(customer) == addressId;
  final addresses = customer.addresses
      .where((address) => address.id != addressId)
      .toList();

  String? defaultId = customer.defaultAddressId;
  if (wasDefault) {
    defaultId = addresses.isEmpty ? null : addresses.first.id;
  }
  return AddressListUpdate(addresses, defaultId);
}
