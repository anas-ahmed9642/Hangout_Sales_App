import '../models/customer.dart';
import '../models/customer_address.dart';

/// Data-layer contract for customers (collection `customers`).
///
/// The normalized phone is the identity and the Firestore document id;
/// it is immutable — no method here accepts a new phone. Changing a
/// number is a merge (Phase 12), never an edit.
abstract class CustomerRepository {
  /// Reads one customer by phone. Returns null when no customer exists.
  /// Accepts any valid phone format; the lookup normalizes defensively.
  Future<Customer?> getByPhone(String phone);

  /// Streams all customers; archived ones are excluded unless
  /// [includeArchived] is true. Filtering is client-side, mirroring
  /// DeliveryAreaRepository.streamAreas.
  Stream<List<Customer>> streamCustomers({bool includeArchived = false});

  /// Creates the customer document (id = normalized phone).
  /// Throws [StateError] when a customer with that phone already exists.
  Future<void> createCustomer(Customer customer);

  /// Updates name/notes/deliveryNotes and bumps updatedAt.
  /// A null argument leaves that field unchanged; pass '' to clear it.
  /// Throws [StateError] when the customer does not exist.
  Future<void> updateProfile(
    String phone, {
    String? name,
    String? notes,
    String? deliveryNotes,
  });

  /// Replaces the address list and default address, then bumps updatedAt.
  /// Integrity is enforced by the [Customer] constructor: [defaultAddressId]
  /// must reference an entry in [addresses] ([ArgumentError] otherwise).
  /// Throws [StateError] when the customer does not exist.
  Future<void> saveAddresses(
    String phone,
    List<CustomerAddress> addresses,
    String? defaultAddressId,
  );

  /// Archives/unarchives the customer and bumps updatedAt.
  /// Throws [StateError] when the customer does not exist.
  Future<void> setArchived(String phone, bool archived);
}