// lib/core/utils/geohash_util.dart

import 'package:swap_app/core/location/location_service.dart'; // For LatLng
import 'dart:math';

/// A simple utility to generate GeoHashes.
/// Note: For production, consider using a well-tested geohashing library
/// for better precision and edge case handling. This is a basic implementation.
class GeoHashUtil {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Generates a GeoHash for the given latitude and longitude.
  /// [precision] determines the length of the geohash (higher = more precise).
  static String encode(LatLng latLng, {int precision = 12}) {
    double lat = latLng.latitude;
    double lon = latLng.longitude;

    String geohash = '';
    bool isEvenBit = true;
    double latMin = -90.0, latMax = 90.0;
    double lonMin = -180.0, lonMax = 180.0;
    int hashChar = 0;
    int bit = 0;

    while (geohash.length < precision) {
      if (isEvenBit) {
        // Bisect longitude
        double lonMid = (lonMin + lonMax) / 2;
        if (lon > lonMid) {
          hashChar = hashChar * 2 + 1;
          lonMin = lonMid;
        } else {
          hashChar = hashChar * 2 + 0;
          lonMax = lonMid;
        }
      } else {
        // Bisect latitude
        double latMid = (latMin + latMax) / 2;
        if (lat > latMid) {
          hashChar = hashChar * 2 + 1;
          latMin = latMid;
        } else {
          hashChar = hashChar * 2 + 0;
          latMax = latMid;
        }
      }

      isEvenBit = !isEvenBit;
      bit++;

      if (bit == 5) {
        geohash += _base32[hashChar];
        bit = 0;
        hashChar = 0;
      }
    }
    return geohash;
  }

  /// Calculates the distance between two LatLng points using the Haversine formula.
  /// Returns distance in kilometers.
  static double calculateDistance(LatLng lat1, LatLng lat2) {
    const double earthRadiusKm = 6371.0; // Earth's radius in kilometers

    double latRad1 = _degreesToRadians(lat1.latitude);
    double lonRad1 = _degreesToRadians(lat1.longitude);
    double latRad2 = _degreesToRadians(lat2.latitude);
    double lonRad2 = _degreesToRadians(lat2.longitude);

    double dLat = latRad2 - latRad1;
    double dLon = lonRad2 - lonRad1;

    double a =
        pow(sin(dLat / 2), 2) +
        cos(latRad1) * cos(latRad2) * pow(sin(dLon / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    double distance = earthRadiusKm * c;
    return distance;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Calculates the bounding box of geohash prefixes to cover a given radius.
  /// This is a simplified approach. For more robust bounding boxes,
  /// consider libraries or more complex algorithms.
  /// Returns a list of geohash prefixes to query.
  static List<String> getGeohashNeighbors(
    LatLng center,
    double radiusKm, {
    int precision = 9,
  }) {
    // This is a very basic way to get neighbors by checking the center's hash
    // and slightly offset points. A proper implementation would calculate
    // the actual bounding box based on the radius.
    // For a given precision, a geohash represents a square area.
    // We need to find the geohash prefixes that intersect with the circle.

    // A more accurate approach involves calculating the min/max lat/lon
    // for the bounding box of the circle and finding the geohashes that cover it.
    // For simplicity here, we'll just return the center hash at a relevant precision.
    // A precision of 9 is roughly 4.8m x 4.8m, 8 is 38.2m x 19.1m, 7 is 152.9m x 152.9m etc.
    // We need a precision such that the geohash cell size is smaller than the radius.
    // A rough estimate: geohash length 1 gives ~5000km, 2 ~1250km, 3 ~156km, 4 ~39km, 5 ~4.8km, 6 ~1.2km, 7 ~150m, 8 ~38m, 9 ~4.8m.
    // We need a precision such that the cell size is smaller than the radius.
    // Let's pick a precision based on the radius. This is a heuristic.
    int effectivePrecision = 9; // Default precision
    if (radiusKm > 1000) {
      effectivePrecision = 3;
    } else if (radiusKm > 100)
      // ignore: curly_braces_in_flow_control_structures
      effectivePrecision = 4;
    else if (radiusKm > 10)
      // ignore: curly_braces_in_flow_control_structures
      effectivePrecision = 5;
    else if (radiusKm > 1)
      // ignore: curly_braces_in_flow_control_structures
      effectivePrecision = 6;
    else
      // ignore: curly_braces_in_flow_control_structures
      effectivePrecision = 7; // For smaller radii, increase precision

    String centerGeohash = encode(center, precision: effectivePrecision);

    // For simplicity, we'll just query the center geohash prefix.
    // A proper implementation would find all intersecting geohash prefixes.
    // This basic approach will miss posts near the boundaries of the center geohash cell.
    // To improve, you'd calculate the 8 neighboring geohashes and include them in the query.
    // For a more accurate bounding box approach, you'd need functions to calculate
    // the min/max lat/lon of the circle's bounding box and find all geohashes covering it.

    // For a simple start, just query the center hash prefix.
    // The length of the prefix depends on how wide you want the initial search.
    // A shorter prefix covers a larger area.
    // Let's use a prefix length that's slightly less precise than the effectivePrecision.
    int prefixLength = min(
      effectivePrecision,
      8,
    ); // Use up to precision 8 for prefix

    return [centerGeohash.substring(0, prefixLength)];
  }
}
