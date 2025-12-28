import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Generic exception used by lm_camera to convey clear failure reasons.
class LMCameraException implements Exception {
  final String message;
  LMCameraException(this.message);

  @override
  String toString() => 'LMCameraException: $message';
}

/// Ensures location services are enabled and location permission is granted.
/// Throws [LMCameraException] on any issues.
Future<void> ensureLocationPermission() async {
  // Location services must be enabled on device for accurate position.
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw LMCameraException('Location services are disabled.');
  }

  // Check and request permission if necessary.
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied) {
    throw LMCameraException('Location permission denied.');
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are permanently denied.
    throw LMCameraException(
        'Location permission permanently denied. Please enable it from device settings.');
  }

  // At this point permission is granted (either while-in-use or always).
}

/// Gets the current device position with a timeout to avoid long waits.
/// Throws [LMCameraException] on errors.
Future<Position> getCurrentPosition({Duration timeout = const Duration(seconds: 8)}) async {
  try {
    // Use the best available accuracy; keep a reasonable timeout for field apps.
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    ).timeout(timeout);
  } on TimeoutException {
    throw LMCameraException('Timed out while obtaining current location.');
  } on Exception catch (e) {
    throw LMCameraException('Failed to obtain location: $e');
  }
}
