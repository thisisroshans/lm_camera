/// Result returned by `lm_camera` after a successful capture.
class LMCameraResult {
  /// Absolute path to the processed and saved image file (JPEG).
  final String imagePath;

  /// Latitude recorded for the image (decimal degrees).
  final double latitude;

  /// Longitude recorded for the image (decimal degrees).
  final double longitude;

  /// Timestamp recorded at the moment of capture (UTC).
  final DateTime timestamp;

  const LMCameraResult({
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  @override
  String toString() =>
      'LMCameraResult(imagePath: $imagePath, lat: $latitude, lon: $longitude, timestamp: $timestamp)';
}
