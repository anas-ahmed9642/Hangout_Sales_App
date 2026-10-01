/// Natural string comparison: digit runs compare numerically, so
/// "Sector 10" sorts after "Sector 9" (plain alphabetical order would
/// put "Sector 10" before "Sector 2").
///
/// Required ordering (test fixture):
/// Sector 2 < Sector 3 < Sector 4 < Sector 5C/1 < Sector 5C/2 < Sector 5C/3
/// < Sector 5C/4 < Sector 8 < Sector 9 < Sector 10 < Sector 11A < Sector 11B
/// < Sector 11C/1 < Sector 11C/2 < Sector 11C/3
int naturalCompare(String a, String b) {
  final aTokens = _tokens(a);
  final bTokens = _tokens(b);
  final count =
      aTokens.length < bTokens.length ? aTokens.length : bTokens.length;
  for (var i = 0; i < count; i++) {
    final result = _compareTokens(aTokens[i], bTokens[i]);
    if (result != 0) return result;
  }
  return aTokens.length.compareTo(bTokens.length);
}

final RegExp _tokenPattern = RegExp(r'\d+|\D+');

List<String> _tokens(String s) =>
    _tokenPattern.allMatches(s).map((m) => m.group(0)!).toList();

int _compareTokens(String a, String b) {
  final aIsNum = _isDigits(a);
  final bIsNum = _isDigits(b);
  if (aIsNum && bIsNum) return _compareNumbers(a, b);
  return a.toLowerCase().compareTo(b.toLowerCase());
}

bool _isDigits(String s) {
  if (s.isEmpty) return false;
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (c < 0x30 || c > 0x39) return false;
  }
  return true;
}

/// Compares digit strings by numeric value without parsing them
/// (no overflow risk; leading zeros handled, so "007" == "7").
int _compareNumbers(String a, String b) {
  final aTrimmed = a.replaceFirst(RegExp(r'^0+'), '');
  final bTrimmed = b.replaceFirst(RegExp(r'^0+'), '');
  if (aTrimmed.length != bTrimmed.length) {
    return aTrimmed.length.compareTo(bTrimmed.length);
  }
  return aTrimmed.compareTo(bTrimmed);
}

/// Normalizes a string for "contains" search: lowercased, stripped of
/// everything that is not a letter or digit.
///
/// Typing `5c1`, `5C/1`, `5c 1` or `sector 5c/1` all match "Sector 5C/1";
/// typing `11` matches the 11A/11B/11C areas.
String normalizeForSearch(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');