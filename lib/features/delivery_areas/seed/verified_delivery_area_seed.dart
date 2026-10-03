/// The 15 owner-supplied sectors (plan Section 2, addendum A1 confirmed).
/// Seeding is idempotent: names that already exist (case-insensitive)
/// are skipped by seedVerifiedAreas().
class VerifiedDeliveryAreaSeedItem {
  final String name;
  final double defaultCharge;

  const VerifiedDeliveryAreaSeedItem({
    required this.name,
    required this.defaultCharge,
  });
}

const verifiedDeliveryAreaSeed = <VerifiedDeliveryAreaSeedItem>[
  VerifiedDeliveryAreaSeedItem(
    name: 'Sector 2',
    defaultCharge: 180,
  ),
  VerifiedDeliveryAreaSeedItem(
    name: 'Sector 3',
    defaultCharge: 150,
  ),
  VerifiedDeliveryAreaSeedItem(
    name: 'Sector 4',
    defaultCharge: 150,
  ),
  VerifiedDeliveryAreaSeedItem(
    name: 'Sector 5C/1',
    defaultCharge: 150,
  ),
  VerifiedDeliveryAreaSeedItem(
    name: 'Sector 5C/2',
    defaultCharge: 150,
  ),
  VerifiedDeliveryAreaSeedItem(
    name: 'Sector 5C/3',
    defaultCharge: 100,
  ),
  VerifiedDeliveryAreaSeedItem(
    name: 'Sector 5C/4',
    defaultCharge: 150,
  ),
  VerifiedDeliveryAreaSeedItem(
    name: 'Sector 8',
    defaultCharge: 100,
  ),
  VerifiedDeliveryAreaSeedItem(
    name: 'Sector 9',
    defaultCharge: 70,
  ),
  VerifiedDeliveryAreaSeedItem(
    name: 'Sector 10',
    defaultCharge: 100,
  ),
  VerifiedDeliveryAreaSeedItem(
    name: 'Sector 11A',
    defaultCharge: 100,
  ),
  VerifiedDeliveryAreaSeedItem(
    name: 'Sector 11B',
    defaultCharge: 100,
  ),
  VerifiedDeliveryAreaSeedItem(
    name: 'Sector 11C/1',
    defaultCharge: 100,
  ),
  VerifiedDeliveryAreaSeedItem(
    name: 'Sector 11C/2',
    defaultCharge: 100,
  ),
  VerifiedDeliveryAreaSeedItem(
    name: 'Sector 11C/3',
    defaultCharge: 100,
  ),
];