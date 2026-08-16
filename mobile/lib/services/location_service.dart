import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Outcome of a location request, so the UI can show the right message.
enum LocationStatus { ok, serviceDisabled, denied, deniedForever, error }

/// The device's location plus a best-effort postal code (Flipp needs a postal
/// code for its banner lookup; the exact coordinates drive the map + proximity).
class DeviceLocation {
  final LatLng latLng;
  final String? postalCode;
  const DeviceLocation(this.latLng, this.postalCode);
}

class LocationResult {
  final DeviceLocation? location;
  final LocationStatus status;
  const LocationResult(this.status, [this.location]);
}

/// Wraps device GPS (geolocator) + on-device reverse geocoding (geocoding).
class LocationService {
  Future<LocationResult> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(LocationStatus.serviceDisabled);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult(LocationStatus.denied);
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(LocationStatus.deniedForever);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final latLng = LatLng(position.latitude, position.longitude);
      // Best-effort on-device postal code; the backend resolves it from the
      // coordinates when this is null (e.g. on web), so we still succeed.
      final postal = await _reversePostal(position.latitude, position.longitude);
      return LocationResult(LocationStatus.ok, DeviceLocation(latLng, postal));
    } catch (_) {
      return const LocationResult(LocationStatus.error);
    }
  }

  /// Returns the device's coordinates only if permission is ALREADY granted —
  /// never prompts. Used by the home feed to auto-locate silently; returns null
  /// (so the feed shows an "enable location" prompt) when not yet permitted.
  Future<LatLng?> currentIfPermitted() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Open the OS settings so the user can grant a permanently-denied permission.
  Future<void> openSettings() => Geolocator.openAppSettings();

  Future<String?> _reversePostal(double lat, double lng) async {
    try {
      final marks = await placemarkFromCoordinates(lat, lng);
      for (final mark in marks) {
        final code = mark.postalCode?.trim();
        if (code != null && code.isNotEmpty) return code;
      }
    } catch (_) {
      // Reverse geocoding unavailable (e.g. web) — treat as no postal.
    }
    return null;
  }
}
