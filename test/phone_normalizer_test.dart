import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/core/utils/phone_normalizer.dart';

void main() {
  group('PhoneNormalizer.normalize', () {
    test('accepts every documented input format', () {
      const inputs = [
        '03001234567',
        '0300-1234567',
        '0300 1234567',
        '(0300) 1234567',
        '+92 300 1234567',
        '+923001234567',
        '0092 300 1234567',
        '923001234567',
        '3001234567',
      ];
      for (final input in inputs) {
        expect(
          PhoneNormalizer.normalize(input),
          '03001234567',
          reason: 'input: $input',
        );
      }
    });

    test('rejects invalid inputs with null, never throws', () {
      const invalid = [
        '',
        '   ',
        '030012345', // too few digits
        '0300123456', // 10 digits starting with 0
        '030012345678', // too many digits
        '02134567890', // landline
        '+1 555 1234567', // foreign number
        '0300abc4567', // letters are rejected, not stripped
        'not a number',
      ];
      for (final input in invalid) {
        expect(
          PhoneNormalizer.normalize(input),
          isNull,
          reason: 'input: $input',
        );
      }
    });

    test('isValid mirrors normalize', () {
      expect(PhoneNormalizer.isValid('0300-1234567'), isTrue);
      expect(PhoneNormalizer.isValid('02134567890'), isFalse);
      expect(PhoneNormalizer.isValid(''), isFalse);
    });
  });

  group('PhoneNormalizer.toInternational', () {
    test('converts to the wa.me form', () {
      expect(
        PhoneNormalizer.toInternational('03001234567'),
        '923001234567',
      );
    });

    test('throws on non-normalized input', () {
      expect(
        () => PhoneNormalizer.toInternational('0300-1234567'),
        throwsArgumentError,
      );
    });
  });

  group('PhoneNormalizer.display', () {
    test('returns the plain 11-digit form', () {
      expect(PhoneNormalizer.display('03001234567'), '03001234567');
    });

    test('throws on non-normalized input', () {
      expect(() => PhoneNormalizer.display('abc'), throwsArgumentError);
    });
  });
}