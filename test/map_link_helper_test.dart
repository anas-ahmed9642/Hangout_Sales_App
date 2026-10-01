import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/core/utils/map_link_helper.dart';

void main() {
  group('MapLinkHelper.parse', () {
    test('accepts Google Maps links', () {
      const links = [
        'https://www.google.com/maps/place/Hangout/@24.8607,67.0011,17z',
        'https://google.com/maps/search/?api=1&query=24.8607,67.0011',
        'https://maps.google.com/?q=24.8607,67.0011',
        'https://maps.app.goo.gl/AbCdEfGh',
        'https://goo.gl/maps/AbCdEfGh',
      ];
      for (final link in links) {
        final target = MapLinkHelper.parse(link);
        expect(target, isNotNull, reason: link);
        expect(target!.kind, MapTargetKind.link);
        expect(target.link, link);
      }
    });

    test('accepts coordinates, comma or whitespace separated', () {
      final comma = MapLinkHelper.parse('24.8607, 67.0011');
      expect(comma, isNotNull);
      expect(comma!.kind, MapTargetKind.coordinates);
      expect(comma.latitude, 24.8607);
      expect(comma.longitude, 67.0011);

      final space = MapLinkHelper.parse('24.8607 67.0011');
      expect(space, isNotNull);
      expect(space!.kind, MapTargetKind.coordinates);
      expect(space.latitude, 24.8607);
      expect(space.longitude, 67.0011);
    });

    test('rejects garbage with null, never throws', () {
      const invalid = [
        '',
        '   ',
        'hello world',
        'https://example.com/some-page',
        'https://www.google.com/search?q=pizza',
        'https://goo.gl/other-path',
        '24.8607', // single number is not coordinates
        '91, 67.0011', // latitude out of range
        '24.8607, 181', // longitude out of range
      ];
      for (final input in invalid) {
        expect(MapLinkHelper.parse(input), isNull, reason: 'input: $input');
      }
    });
  });

  group('MapLinkHelper.toLaunchUri', () {
    test('opens links exactly as pasted', () {
      const link = 'https://maps.app.goo.gl/AbCdEfGh';
      final target = MapLinkHelper.parse(link)!;
      expect(MapLinkHelper.toLaunchUri(target).toString(), link);
    });

    test('builds the Maps search URL for coordinates', () {
      final target = MapLinkHelper.parse('24.8607, 67.0011')!;
      expect(
        MapLinkHelper.toLaunchUri(target).toString(),
        'https://www.google.com/maps/search/?api=1&query=24.8607,67.0011',
      );
    });
  });
}