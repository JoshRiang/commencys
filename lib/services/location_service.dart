import 'package:geolocator/geolocator.dart';

/// Wrapper around geolocator for permission handling + position stream.
///
/// The fix [accuracy] (metres) is forwarded as the report's accuracy radius
/// (spec: GPS + accuracy radius; criterion 1 manual-pin fallback in UI).
class LocationService {
  Future<bool> ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Position?> currentPosition() async {
    final ok = await ensurePermission();
    if (!ok) return null;
    try {
      // Fail fast on a phone with no fix (indoors, GPS off) instead of
      // hanging the SOS flow indefinitely.
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      ).timeout(const Duration(seconds: 20));
    } catch (_) {
      return null;
    }
  }

  /// GPS fix accuracy in metres (null when unavailable).
  Future<double?> accuracy() async {
    final pos = await currentPosition();
    return pos?.accuracy;
  }

  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }
}
