# qr_scan

A Flutter plugin that combines Google's ML Kit Barcode Scanning with CamerAwesome for fast, reliable QR code and barcode scanning with built-in audio feedback.

## Features

- Real-time QR code and barcode scanning using Google ML Kit
- Camera preview powered by CamerAwesome
- Built-in audio feedback (success, fail, read sounds) with `enableAudio` toggle
- Duplicate scan prevention with configurable `debounceDuration`
- Flash toggle, camera switch, and aspect ratio controls included
- Multiple barcode detection with selection dialog
- Programmatic pause/resume via `QrScanController`
- Custom overlay support via `overlayBuilder`
- Pinch-to-zoom with `enableZoom` toggle
- Gallery/still-image scanning via `scanImageForBarcodes()`
- Configurable barcode format filtering
- Android and iOS support

## Getting Started

### Prerequisites

- Dart SDK `^3.5.3`
- Flutter `>=3.3.0`

### Installation

Add `qr_scan` to your `pubspec.yaml`:

```yaml
dependencies:
  qr_scan: ^0.4.0
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
  useBarcode: (ScannedBarcode barcode) async {
    print('Scanned: ${barcode.rawValue}');
    return ScanSoundResult.success;
  },
)
```

### Audio Feedback

The `useBarcode` callback return value controls which sound plays:

| Return Value              | Sound         |
| ------------------------- | ------------- |
| `ScanSoundResult.success` | Success beep  |
| `ScanSoundResult.read`    | Read beep     |
| `ScanSoundResult.fail`    | Fail buzzer   |
| `ScanSoundResult.none`    | No sound      |
| `null`                     | No sound      |

A read sound also plays automatically when a barcode is first detected.

Disable all audio with `enableAudio: false`.

### Debounce Duration

Duplicate barcodes are ignored for a configurable cooldown period:

```dart
QrScan(
  debounceDuration: const Duration(seconds: 5),
  useBarcode: (barcode) async => ScanSoundResult.success,
)
```

### Barcode Format Filtering

Restrict which barcode formats are detected:

```dart
QrScan(
  barcodeFormats: [BarcodeFormat.qrCode, BarcodeFormat.ean13],
  useBarcode: (barcode) async => ScanSoundResult.success,
)
```

### Controller (Pause / Resume)

Use `QrScanController` to programmatically control scanning:

```dart
final controller = QrScanController();

// In your widget tree:
QrScan(
  controller: controller,
  useBarcode: (barcode) async => ScanSoundResult.success,
)

// Pause/resume:
controller.pause();
controller.resume();
controller.toggle();
```

The camera preview stays active while scanning is paused — only barcode detection stops.

### Overlay

Add a custom visual overlay on top of the camera preview:

```dart
QrScan(
  overlayBuilder: (context) => Center(
    child: Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green, width: 3),
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),
  useBarcode: (barcode) async => ScanSoundResult.success,
)
```

The overlay is wrapped in `IgnorePointer` so it does not block camera touch events.

### Zoom

Pinch-to-zoom is enabled by default. Disable it with:

```dart
QrScan(
  enableZoom: false,
  useBarcode: (barcode) async => ScanSoundResult.success,
)
```

### Gallery Scanning

Scan barcodes from still images (e.g. gallery photos) without the camera:

```dart
import 'package:qr_scan/qr_scan.dart';

final inputImage = InputImage.fromFilePath('/path/to/image.jpg');
final barcodes = await scanImageForBarcodes(inputImage);
for (final barcode in barcodes) {
  print('Found: ${barcode.rawValue}');
}
```

A `timeout` parameter (default 10 seconds) prevents hangs on very large or corrupted images. A `TimeoutException` is thrown if exceeded, so you can distinguish it from "no barcodes found." For best results, downscale images before scanning (e.g. cap at 1920px when using `image_picker`).

## API Reference

### QrScan Widget

| Parameter                   | Type                                                     | Default                          | Description                                       |
| --------------------------- | -------------------------------------------------------- | -------------------------------- | ------------------------------------------------- |
| `useBarcode`                | `FutureOr<ScanSoundResult?> Function(ScannedBarcode)`    | required                         | Callback invoked with the scanned barcode         |
| `selectedCameraAspectRatio` | `int`                                                    | `0`                              | `0` for 16:9, `1` for 4:3                         |
| `multiBarcodeTitle`         | `String`                                                 | `"Multiple Barcodes Found"`      | Title for multi-barcode dialog                    |
| `multiBarcodeMessage`       | `String`                                                 | `"Select the barcode you want…"` | Message for multi-barcode dialog                  |
| `enableAudio`               | `bool`                                                   | `true`                           | Enable/disable audio feedback                     |
| `debounceDuration`          | `Duration`                                               | `2000ms`                         | Cooldown before re-scanning the same barcode      |
| `barcodeFormats`            | `List<BarcodeFormat>`                                    | `[BarcodeFormat.all]`            | Barcode formats to detect                         |
| `controller`                | `QrScanController?`                                      | `null`                           | Controller for pause/resume                       |
| `overlayBuilder`            | `Widget Function(BuildContext)?`                         | `null`                           | Custom overlay on camera preview                  |
| `enableZoom`                | `bool`                                                   | `true`                           | Enable pinch-to-zoom                              |

### ScannedBarcode

| Field          | Type            | Description                                   |
| -------------- | --------------- | --------------------------------------------- |
| `rawValue`     | `String?`       | Raw string encoded in the barcode             |
| `displayValue` | `String?`       | Human-readable barcode value                  |
| `format`       | `BarcodeFormat`  | Barcode symbology (QR, EAN-13, Code 128, etc) |
| `type`         | `BarcodeType`    | Semantic type (URL, email, phone, etc)        |

### scanImageForBarcodes()

| Parameter  | Type                | Default                  | Description                                          |
| ---------- | ------------------- | ------------------------ | ---------------------------------------------------- |
| `image`    | `InputImage`        | required                 | The image to scan                                    |
| `formats`  | `List<BarcodeFormat>` | `[BarcodeFormat.all]`  | Barcode formats to detect                            |
| `timeout`  | `Duration`          | `10 seconds`             | Max processing time before `TimeoutException`        |

## Example

See the [example app](example/) for working demos of one-time scanning, continuous scanning, controlled scanning with overlay, and gallery scanning.

## Additional Information

- **Homepage:** [sezinsoft.com](https://www.sezinsoft.com/)
- **License:** See [LICENSE](LICENSE)
- **Issues:** File issues on the GitHub repository
