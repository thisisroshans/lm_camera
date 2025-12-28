# lm_camera

Lightweight camera service for field workforce apps.

- Captures a photo with the device camera
- Records GPS latitude & longitude at capture
- Records an ISO-8601 timestamp
- Burns the three metadata items onto the image (visible text)
- Saves processed image locally (app documents directory)

Usage example:

```dart
import 'package:lm_camera/lm_camera.dart';

final result = await capture();
print('Saved image: ${result.imagePath}');
```
