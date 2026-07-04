import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Reason a location lookup failed. Surfaced to the UI so we can show a
/// targeted snackbar instead of a generic error.
enum LocationFailure {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

class LocationResult {
  final double? lat;
  final double? lng;
  final LocationFailure? failure;

  const LocationResult._({this.lat, this.lng, this.failure});

  factory LocationResult.success(double lat, double lng) =>
      LocationResult._(lat: lat, lng: lng);

  factory LocationResult.failed(LocationFailure failure) =>
      LocationResult._(failure: failure);

  bool get ok => failure == null && lat != null && lng != null;
}

class LocationService {
  /// Get the current device position. Handles the permission ladder
  /// (service-enabled → permission → request) and returns a typed result
  /// the UI can branch on.
  Future<LocationResult> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationResult.failed(LocationFailure.servicesDisabled);
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      return LocationResult.failed(LocationFailure.permissionDeniedForever);
    }
    if (perm == LocationPermission.denied) {
      return LocationResult.failed(LocationFailure.permissionDenied);
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LocationResult.success(pos.latitude, pos.longitude);
    } on TimeoutException {
      return LocationResult.failed(LocationFailure.timeout);
    } catch (_) {
      return LocationResult.failed(LocationFailure.unknown);
    }
  }
}

