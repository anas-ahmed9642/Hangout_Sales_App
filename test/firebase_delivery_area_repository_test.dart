import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/delivery_areas/repositories/firebase_delivery_area_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseDeliveryAreaRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirebaseDeliveryAreaRepository(firestore: firestore);
  });

  group('FirebaseDeliveryAreaRepository', () {
    test('creates an area', () async {
      final id = await repository.createArea(
        name: 'Sector 4',
        defaultCharge: 150,
      );

      final snapshot = await firestore
          .collection('deliveryAreas')
          .doc(id)
          .get();

      expect(snapshot.exists, isTrue);
      expect(snapshot.data()?['name'], 'Sector 4');
      expect(snapshot.data()?['defaultCharge'], 150);
      expect(snapshot.data()?['active'], isTrue);
    });

    test('trims the area name on create', () async {
      final id = await repository.createArea(
        name: '  Sector 4  ',
        defaultCharge: 150,
      );

      final areas = await repository.streamAreas().first;
      expect(areas.single.name, 'Sector 4');
      expect(id, isNotEmpty);
    });

    test('rejects an empty name', () async {
      expect(
        () => repository.createArea(
          name: '   ',
          defaultCharge: 150,
        ),
        throwsArgumentError,
      );
    });

    test('rejects a charge that is not in MenuData.deliveryCharges',
        () async {
      expect(
        () => repository.createArea(
          name: 'Sector 4',
          defaultCharge: 999,
        ),
        throwsArgumentError,
      );

      expect(
        () => repository.createArea(
          name: 'Sector 4',
          defaultCharge: 0,
        ),
        throwsArgumentError,
      );
    });

    test('rejects a duplicate name case-insensitively on create',
        () async {
      await repository.createArea(
        name: 'Sector 4',
        defaultCharge: 150,
      );

      expect(
        () => repository.createArea(
          name: 'sector 4',
          defaultCharge: 100,
        ),
        throwsStateError,
      );
    });

    test('streams all areas', () async {
      await repository.createArea(
        name: 'Sector 4',
        defaultCharge: 150,
      );
      await repository.createArea(
        name: 'Sector 9',
        defaultCharge: 70,
      );

      final areas = await repository.streamAreas().first;
      expect(areas, hasLength(2));
      expect(
        areas.map((area) => area.name),
        containsAll(['Sector 4', 'Sector 9']),
      );
    });

    test('streamAreas with activeOnly hides inactive areas', () async {
      final id = await repository.createArea(
        name: 'Sector 4',
        defaultCharge: 150,
      );
      await repository.createArea(
        name: 'Sector 9',
        defaultCharge: 70,
      );
      await repository.setAreaActive(id, false);

      final active = await repository
          .streamAreas(activeOnly: true)
          .first;
      expect(
        active.map((area) => area.name),
        ['Sector 9'],
      );

      final all = await repository.streamAreas().first;
      expect(all, hasLength(2));
    });

    test('updates the name and charge', () async {
      final id = await repository.createArea(
        name: 'Sector 4',
        defaultCharge: 150,
      );

      await repository.updateArea(
        id,
        name: 'Sector 4A',
        defaultCharge: 100,
      );

      final areas = await repository.streamAreas().first;
      expect(areas.single.name, 'Sector 4A');
      expect(areas.single.defaultCharge, 100);
      expect(areas.single.active, isTrue);
    });

    test('rejects updating to a duplicate name', () async {
      final id = await repository.createArea(
        name: 'Sector 4',
        defaultCharge: 150,
      );
      await repository.createArea(
        name: 'Sector 9',
        defaultCharge: 70,
      );

      expect(
        () => repository.updateArea(
          id,
          name: 'SECTOR 9',
          defaultCharge: 150,
        ),
        throwsStateError,
      );
    });

    test('rejects updating with an invalid charge', () async {
      final id = await repository.createArea(
        name: 'Sector 4',
        defaultCharge: 150,
      );

      expect(
        () => repository.updateArea(
          id,
          name: 'Sector 4',
          defaultCharge: 999,
        ),
        throwsArgumentError,
      );
    });

    test('throws StateError when updating a missing area', () async {
      expect(
        () => repository.updateArea(
          'no-such-id',
          name: 'Sector 4',
          defaultCharge: 150,
        ),
        throwsStateError,
      );
    });

    test('setAreaActive deactivates and reactivates', () async {
      final id = await repository.createArea(
        name: 'Sector 4',
        defaultCharge: 150,
      );

      await repository.setAreaActive(id, false);
      var areas = await repository.streamAreas().first;
      expect(areas.single.active, isFalse);

      await repository.setAreaActive(id, true);
      areas = await repository.streamAreas().first;
      expect(areas.single.active, isTrue);
    });

    test('throws StateError when toggling a missing area', () async {
      expect(
        () => repository.setAreaActive('no-such-id', false),
        throwsStateError,
      );
    });

    test('seedVerifiedAreas seeds 15 areas and is idempotent',
        () async {
      final firstRun = await repository.seedVerifiedAreas();
      expect(firstRun, 15);

      var areas = await repository.streamAreas().first;
      expect(areas, hasLength(15));

      final sector2 = areas.firstWhere(
        (area) => area.name == 'Sector 2',
      );
      expect(sector2.defaultCharge, 180);
      expect(sector2.active, isTrue);

      final secondRun = await repository.seedVerifiedAreas();
      expect(secondRun, 0);

      areas = await repository.streamAreas().first;
      expect(areas, hasLength(15));
    });

    test('seedVerifiedAreas skips names that already exist', () async {
      await repository.createArea(
        name: 'sector 2',
        defaultCharge: 150,
      );

      final seeded = await repository.seedVerifiedAreas();
      expect(seeded, 14);

      final areas = await repository.streamAreas().first;
      expect(areas, hasLength(15));

      final sector2 = areas.firstWhere(
        (area) => area.name.toLowerCase() == 'sector 2',
      );
      expect(sector2.defaultCharge, 150);
    });
  });
}