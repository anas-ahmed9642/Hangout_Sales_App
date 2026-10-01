import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/core/utils/natural_compare.dart';

void main() {
  group('naturalCompare', () {
    test('sorts the 15 seed areas in the required order', () {
      final areas = [
        'Sector 11C/3',
        'Sector 2',
        'Sector 11A',
        'Sector 5C/2',
        'Sector 10',
        'Sector 4',
        'Sector 11C/1',
        'Sector 3',
        'Sector 5C/4',
        'Sector 9',
        'Sector 8',
        'Sector 11B',
        'Sector 5C/1',
        'Sector 11C/2',
        'Sector 5C/3',
      ]..sort(naturalCompare);

      expect(areas, [
        'Sector 2',
        'Sector 3',
        'Sector 4',
        'Sector 5C/1',
        'Sector 5C/2',
        'Sector 5C/3',
        'Sector 5C/4',
        'Sector 8',
        'Sector 9',
        'Sector 10',
        'Sector 11A',
        'Sector 11B',
        'Sector 11C/1',
        'Sector 11C/2',
        'Sector 11C/3',
      ]);
    });

    test('compares digit runs numerically, not alphabetically', () {
      expect(naturalCompare('Sector 9', 'Sector 10'), lessThan(0));
      expect(naturalCompare('Sector 10', 'Sector 9'), greaterThan(0));
      expect(naturalCompare('Sector 2', 'Sector 2'), 0);
    });

    test('compares text runs case-insensitively', () {
      expect(naturalCompare('sector 2', 'Sector 3'), lessThan(0));
      expect(naturalCompare('Sector 11a', 'Sector 11B'), lessThan(0));
    });
  });

  group('normalizeForSearch', () {
    test('strips case and non-alphanumerics', () {
      expect(normalizeForSearch('Sector 5C/1'), 'sector5c1');
    });

    test('every documented query form matches "Sector 5C/1"', () {
      final haystack = normalizeForSearch('Sector 5C/1');
      for (final query in ['5c1', '5C/1', '5c 1', 'sector 5c/1']) {
        expect(
          haystack.contains(normalizeForSearch(query)),
          isTrue,
          reason: 'query: $query',
        );
      }
    });

    test('"11" matches the 11A/11B/11C areas but not Sector 10', () {
      const names = ['Sector 11A', 'Sector 11B', 'Sector 11C/1', 'Sector 10'];
      final hits =
          names.where((n) => normalizeForSearch(n).contains('11')).toList();
      expect(hits, ['Sector 11A', 'Sector 11B', 'Sector 11C/1']);
    });
  });
}