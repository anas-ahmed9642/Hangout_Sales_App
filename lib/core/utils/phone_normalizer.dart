/// Normalizes Pakistani mobile numbers to one canonical stored form.
///
/// The stored form is always the plain 11-digit national format, e.g.
/// `03001234567`. Every accepted input below normalizes to `03001234567`:
/// `03001234567`, `0300-1234567`, `0300 1234567`, `(0300) 1234567`,
/// `+92 300 1234567`, `+923001234567`, `0092 300 1234567`,
/// `923001234567`, `3001234567`.
///
/// Anything else (empty input, letters, landlines, foreign numbers,
/// wrong digit counts) returns null from [normalize] — it never throws.
class PhoneNormalizer {
  static final RegExp _letters = RegExp(r'[A-Za-z]');
  static final RegExp _nonDigits = RegExp(r'\D');
  static final RegExp _valid = RegExp(r'^03\d{9}$');

  /// Returns the normalized 11-digit form, or null when [raw] is not a
  /// valid Pakistani mobile number. Never throws.
  static String? normalize(String raw) {
    if (raw.isEmpty) return null;
    // Letters are rejected outright — never silently stripped.
    if (_letters.hasMatch(raw)) return null;

    String digits = raw.replaceAll(_nonDigits, '');
    if (digits.isEmpty) return null;

    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('92') && digits.length == 12) {
      digits = '0${digits.substring(2)}';
    }
    if (digits.length == 10 && digits.startsWith('3')) {
      digits = '0$digits';
    }

    return _valid.hasMatch(digits) ? digits : null;
  }

  /// True when [raw] is a valid Pakistani mobile number.
  static bool isValid(String raw) => normalize(raw) != null;

  /// `03001234567` -> `923001234567` (for wa.me links).
  /// Throws [ArgumentError] when [normalized] is not a normalized number.
  static String toInternational(String normalized) {
    if (!_valid.hasMatch(normalized)) {
      throw ArgumentError('Not a normalized phone number: $normalized');
    }
    return '92${normalized.substring(1)}';
  }

  /// Customers always display the plain 11-digit form (`03001234567`).
  /// Throws [ArgumentError] when [normalized] is not a normalized number.
  static String display(String normalized) {
    if (!_valid.hasMatch(normalized)) {
      throw ArgumentError('Not a normalized phone number: $normalized');
    }
    return normalized;
  }

  /// Normalized form when [raw] is a valid mobile, otherwise [raw]
  /// unchanged. Empty input is preserved as-is so callers never
  /// manufacture a spurious change from '' to null. Never throws.
  static String? normalizeOrTyped(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) {
      return raw;
    }
    return normalize(text) ?? raw;
  }
}
