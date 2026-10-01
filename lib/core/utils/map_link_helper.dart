/// The kind of map target a pasted string resolved to.
enum MapTargetKind { link, coordinates }

/// A validated map target: either a Google Maps link to open as-is,
/// or coordinates to open via a Maps search URL.
class MapTarget {
  final MapTargetKind kind;
  final String? link;
  final double? latitude;
  final double? longitude;

  const MapTarget.link(this.link)
      : kind = MapTargetKind.link,
        latitude = null,
        longitude = null;

  const MapTarget.coordinates(this.latitude, this.longitude)
      : kind = MapTargetKind.coordinates,
        link = null;
}

/// Parses and builds Google Maps targets.
///
/// Accepted:
/// - `https://` links on `google.com` / `www.google.com` (path starts
///   with `/maps`), `maps.google.com`, `maps.app.goo.gl`, or `goo.gl`
///   (path starts with `/maps`) — opened exactly as pasted.
/// - Coordinates `lat, lng` (comma or whitespace separated,
///   lat -90..90, lng -180..180).
///
/// Short links are opened as links only — never resolved to coordinates
/// (no network call, no geocoding). Anything else returns null.
class MapLinkHelper {
  static final RegExp _coords = RegExp(
    r'^\s*([+-]?(?:\d+(?:\.\d+)?))\s*[,\s]\s*([+-]?(?:\d+(?:\.\d+)?))\s*$',
  );

  /// Returns the validated link, or null when [raw] is not a recognized
  /// Google Maps link.
  static String? _linkTarget(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !uri.isAbsolute) return null;
    if (uri.scheme != 'https') return null;
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    if (host == 'maps.google.com' || host == 'maps.app.goo.gl') {
      return raw.trim();
    }
    if ((host == 'google.com' ||
            host == 'www.google.com' ||
            host == 'goo.gl') &&
        path.startsWith('/maps')) {
      return raw.trim();
    }
    return null;
  }

  /// Parses [raw] into a [MapTarget], or null when it is neither a
  /// recognized Maps link nor valid coordinates. Never throws.
  static MapTarget? parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final link = _linkTarget(trimmed);
    if (link != null) return MapTarget.link(link);

    final match = _coords.firstMatch(trimmed);
    if (match != null) {
      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(2)!);
      if (lat != null &&
          lng != null &&
          lat >= -90 &&
          lat <= 90 &&
          lng >= -180 &&
          lng <= 180) {
        return MapTarget.coordinates(lat, lng);
      }
    }
    return null;
  }

  /// Builds the launch [Uri] for a parsed target.
  static Uri toLaunchUri(MapTarget target) {
    switch (target.kind) {
      case MapTargetKind.link:
        return Uri.parse(target.link!);
      case MapTargetKind.coordinates:
        return Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${target.latitude},${target.longitude}',
        );
    }
  }
}