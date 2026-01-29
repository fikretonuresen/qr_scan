# qr_scan

A Flutter plugin that combines Google's ML Kit Barcode Scanning with CamerAwesome for fast, reliable QR code and barcode scanning with built-in audio feedback.

## Features

- Real-time QR code and barcode scanning using Google ML Kit
- Camera preview powered by CamerAwesome
- Built-in audio feedback (success, fail, read sounds)
- Duplicate scan prevention with automatic cooldown
- Flash toggle, camera switch, and aspect ratio controls included
- Multiple barcode detection with selection dialog
- Android and iOS support

## Getting Started

### Prerequisites

- Dart SDK `^3.5.3`
- Flutter `>=3.3.0`

### Installation

Add `qr_scan` to your `pubspec.yaml`:

```yaml
dependencies:
  qr_scan: ^0.0.7
```

Then run:

```bash
flutter pub get
```

### Permissions Setup

#### Android

Add the camera permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

#### iOS

Add the camera usage description to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is needed for QR/barcode scanning</string>
```

## Usage

### Basic Usage

Drop the `QrScan` widget into your widget tree and provide a `useBarcode` callback:

```dart
import 'package:qr_scan/qr_scan.dart';

QrScan(
  useBarcode: (String barcode) async {
    // Process the scanned barcode
    print('Scanned: $barcode');

    // Return a sound indicator
    return "0"; // plays success sound
  },
)
```

### Continuous Scanning

The scanner stays active after each scan. Duplicate barcodes are ignored for 2 seconds to prevent repeated triggers. To keep scanning without sound, return `null`:

```dart
QrScan(
  useBarcode: (String barcode) async {
    final result = await submitToServer(barcode);
    if (result.success) {
      return "0";  // success sound
    } else {
      return "-1"; // fail sound
    }
  },
)
```

### Audio Feedback

The `useBarcode` callback return value controls which sound plays after processing:

| Return Value | Sound         |
|--------------|---------------|
| `"0"`        | Success sound |
| `"-1"`       | Fail sound    |
| `"1"`        | Read sound    |
| `null` / other | No sound    |

A read sound also plays automatically when a barcode is first detected, before `useBarcode` is called.

### Camera Aspect Ratio

Control the camera preview aspect ratio with `selectedCameraAspectRatio`:

```dart
QrScan(
  selectedCameraAspectRatio: 0, // 16:9 (default)
  useBarcode: (barcode) async => "0",
)

QrScan(
  selectedCameraAspectRatio: 1, // 4:3
  useBarcode: (barcode) async => "0",
)
```

## API Reference

### QrScan Widget

| Parameter                    | Type                                        | Default | Description                          |
|------------------------------|---------------------------------------------|---------|--------------------------------------|
| `useBarcode`                 | `FutureOr<String?> Function(String barcode)` | required | Callback invoked with the scanned barcode value |
| `selectedCameraAspectRatio`  | `int`                                       | `0`     | `0` for 16:9, `1` for 4:3           |

### useBarcode Callback

Called when a barcode is detected. Receives the raw barcode string and should return a string that determines which audio feedback to play.

| Return Value | Effect        |
|--------------|---------------|
| `"0"`        | Plays success sound |
| `"-1"`       | Plays fail sound    |
| `"1"`        | Plays read sound    |
| `null` / other | No sound played  |

## Example

See the [example app](example/) for a full working implementation.

## Additional Information

- **Homepage:** [sezinsoft.com](https://www.sezinsoft.com/)
- **License:** See [LICENSE](LICENSE)
- **Issues:** File issues on the GitHub repository
