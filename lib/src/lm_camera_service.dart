import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';

import 'lm_camera_permissions.dart';
import 'lm_camera_result.dart';
import 'lm_camera_utils.dart';

/// Service-style API: no UI widgets, single responsibility to capture
/// and return `LMCameraResult`.
class LMCameraService {
  /// Captures a photo, retrieves GPS and timestamp, burns metadata onto the image,
  /// saves the image locally, and returns an `LMCameraResult`.
  ///
  /// Throws [LMCameraException] for permission/location issues and [Exception]
  /// for other failures (camera, processing, IO).
  Future<LMCameraResult> capture() async {
    // Ensure location permission and service availability up front.
    await ensureLocationPermission();

    // Get available cameras and pick a sensible default (prefer back camera).
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw LMCameraException('No cameras available on this device.');
    }
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    CameraController? controller;
    try {
      controller = CameraController(camera, ResolutionPreset.high, enableAudio: false);

      // Initializing the controller may fail if camera permission is denied.
      await controller.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw LMCameraException('Timed out while initializing camera.'),
      );
    } on CameraException catch (e) {
      throw LMCameraException('Camera initialization failed: ${e.description ?? e.code}');
    } catch (e) {
      // Wrap unexpected errors with a clear message.
      throw LMCameraException('Camera initialization error: $e');
    }

    try {
      // Get a recent location (small timeout so capture isn't delayed indefinitely).
      final position = await getCurrentPosition(timeout: const Duration(seconds: 8));

      // Capture timestamp as close to the capture moment as possible.
      final timestampUtc = DateTime.now().toUtc();

      // Capture photo
      XFile capturedFile;
      try {
        capturedFile = await controller.takePicture();
      } on CameraException catch (e) {
        throw LMCameraException('Failed to capture image: ${e.description ?? e.code}');
      } catch (e) {
        throw LMCameraException('Unexpected capture error: $e');
      }

      // Read bytes from the captured file.
      late final Uint8List rawBytes;
      try {
        rawBytes = await capturedFile.readAsBytes();
      } catch (e) {
        throw Exception('Failed to read captured image bytes: $e');
      }

      // Burn metadata onto image (this re-encodes the image as JPEG).
      Uint8List processedBytes;
      try {
        processedBytes = burnMetadataOntoImage(
          rawBytes,
          position.latitude,
          position.longitude,
          timestampUtc,
        );
      } catch (e) {
        throw Exception('Failed to process image (burn metadata): $e');
      }

      // Save processed image to local storage.
      String savedPath;
      try {
        savedPath = await saveImageLocally(processedBytes, timestampUtc);
      } catch (e) {
        throw Exception('Failed to save processed image: $e');
      }

      // Return the result
      return LMCameraResult(
        imagePath: savedPath,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: timestampUtc,
      );
    } finally {
      // Clean up camera resources reliably.
      try {
        await controller?.dispose();
      } catch (_) {
        // Ignore dispose errors, but do not swallow important exceptions earlier.
      }
    }
  }
}
