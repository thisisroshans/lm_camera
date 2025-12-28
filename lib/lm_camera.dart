/// Public entrypoint for the lm_camera package.
///
/// Provides a single top-level method `capture()` that performs
/// a camera capture, gathers location & timestamp metadata,
/// burns them onto the photo, saves the processed image locally,
/// and returns an `LMCameraResult`.
library lm_camera;

export 'src/lm_camera_service.dart';
export 'src/lm_camera_result.dart';
export 'src/lm_camera_permissions.dart';
export 'src/lm_camera_utils.dart';

import 'src/lm_camera_service.dart';
import 'src/lm_camera_result.dart';

/// Convenience top-level method that mirrors the service API.
Future<LMCameraResult> capture() => LMCameraService().capture();
