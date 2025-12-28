import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Save bytes to a device-local application documents directory under
/// `lm_camera/` with a timestamped filename. Returns absolute file path.
///
/// Uses a sanitized timestamp in the filename to be Windows-safe.
Future<String> saveImageLocally(Uint8List jpegBytes, DateTime timestampUtc) async {
  // Prepare directory: <app-docs>/lm_camera/
  final dir = await getApplicationDocumentsDirectory();
  final folder = Directory('${dir.path}${Platform.pathSeparator}lm_camera');
  if (!await folder.exists()) {
    await folder.create(recursive: true);
  }

  // Sanitize timestamp for filename (remove ':' and '.' that are unsafe on some OSes).
  final ts = timestampUtc.toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
  final filename = 'lm_camera_$ts.jpg';
  final filePath = '${folder.path}${Platform.pathSeparator}$filename';

  final file = File(filePath);
  await file.writeAsBytes(jpegBytes, flush: true);
  return file.absolute.path;
}

/// Burn visible metadata (latitude, longitude, ISO-8601 timestamp) onto the image bytes,
/// returning JPEG bytes. This function attempts to place a semi-opaque
/// strip at the bottom and render readable text above it.
///
/// Notes:
/// - We use the pure-Dart `image` package for reliable offline processing.
Uint8List burnMetadataOntoImage(
  Uint8List imageBytes,
  double latitude,
  double longitude,
  DateTime timestampUtc,
) {
  // Decode image (works with JPEG/PNG).
  final decoded = img.decodeImage(imageBytes);
  if (decoded == null) {
    throw Exception('Unable to decode captured image for processing.');
  }

  // Prepare lines to render.
  final isoTs = timestampUtc.toIso8601String();
  final lines = [
    'Latitude: ${latitude.toStringAsFixed(6)}',
    'Longitude: ${longitude.toStringAsFixed(6)}',
    'Timestamp: $isoTs',
  ];

  // Choose a bitmap font that exists in `image` package.
  final font = img.arial_24;

  // Measure and compute rect height.
  final int lineHeight = font.height + 6; // small padding
  final int padding = 10;
  final int rectHeight = (lineHeight * lines.length) + (padding * 2);

  // Draw a semi-opaque black rectangle across the bottom.
  final int rectTop = decoded.height - rectHeight;
  img.fillRect(
    decoded,
    0,
    rectTop,
    decoded.width - 1,
    decoded.height - 1,
    0x88000000, // semi-transparent black (AARRGGBB).
  );

  // Render lines with a subtle drop shadow for legibility.
  for (var i = 0; i < lines.length; i++) {
    final y = rectTop + padding + (i * lineHeight);
    final x = padding;

    // Draw shadow (black, offset).
    img.drawString(decoded, font, x + 1, y + 1, lines[i], color: 0xFF000000);
    // Draw main text (white).
    img.drawString(decoded, font, x, y, lines[i], color: 0xFFFFFFFF);
  }

  // Encode as JPEG with quality suitable for field usage.
  final jpg = img.encodeJpg(decoded, quality: 92);
  return Uint8List.fromList(jpg);
}
