# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog,
and this project adheres to Semantic Versioning.

## [0.3.0] - 2026-01-30

### Added

- QrScanController class for programmatic pause/resume/toggle of scanning
- overlayBuilder parameter to stack custom widgets on the camera preview (uses IgnorePointer)
- enableZoom parameter to control pinch-to-zoom (default: true, via CamerAwesome native)
- scanImageForBarcodes() utility function for scanning still images (gallery support)
- InputImage re-exported for convenience with scanImageForBarcodes

### Changed

- Example app expanded with Controlled Scan page demonstrating controller, overlay, and hold-to-scan

## [0.2.0] - 2026-01-29

### BREAKING CHANGES

- Callback signature changed: useBarcode now receives ScannedBarcode instead of String and returns ScanSoundResult? instead of String?
- Access raw value via barcode.rawValue, format via barcode.format, type via barcode.type

### Added

- ScanSoundResult enum replacing magic strings ("0" → .success, "1" → .read, "-1" → .fail)
- ScannedBarcode class with rawValue, displayValue, format, and type fields
- enableAudio parameter to disable sound feedback (default: true)
- debounceDuration parameter to configure duplicate scan prevention (default: 2 seconds)
- barcodeFormats parameter to filter which barcode formats are scanned (default: all)
- BarcodeFormat and BarcodeType re-exported for convenience

### Changed

- Isolate rewritten with spawn-time configuration (eliminates race conditions)
- Isolate now properly disposes BarcodeScanner on cleanup (no more Isolate.current.kill())
- Barcode wrapping happens in background isolate (better main thread performance)
- Audio players are nullable and only initialized when enableAudio is true

## [0.1.0] - 2026-01-29

### BREAKING CHANGES

- Default language changed from Turkish to English for multi-barcode dialog
- Added multiBarcodeTitle and multiBarcodeMessage parameters to customize dialog text
- Turkish users must now explicitly pass Turkish strings via parameters

### Fixed

- Added proper error handling with try/catch/finally to prevent scanner freeze on errors
- Fixed force-unwrap crash on planeData with null-safe access and descriptive error
- Removed hardcoded Turkish strings, replaced with configurable English defaults

## [0.0.7] - 2025-06-17

### Fixed

- Version compatibility fixes for backwards compatibility
- Updated dependencies for Flutter compatibility
- Pod::Spec summary fixed

## [0.0.6] - 2024-10-09

### Changed

- Recreated package files with updated Flutter version
- Updated dependencies for Flutter 3.x compatibility

## [0.0.5] - 2024-06-02

### Fixed

- Multi-barcode popup action order fixed (multiple iterations for stability)

### Added

- selectedCameraAspectRatio parameter for 16:9 or 4:3 camera preview (2024-03-19)
- LayoutBuilder for responsive camera sizing (2024-03-19)

## [0.0.4] - 2024-03-18

### Fixed

- Audio feedback sound issues resolved

## [0.0.3] - 2023-10-11

### Added

- Audio feedback with just_audio package (read, success, fail sounds)

### Changed

- Updated SDK requirements
- Upgraded dependencies

## [0.0.1] - 2023-04-24

### Added

- Initial release
- QR and barcode scanning with CamerAwesome + Google ML Kit
- Real-time barcode detection with background isolate processing
- Flash toggle, aspect ratio toggle, camera switch
- Multi-barcode detection with picker dialog
- Duplicate scan prevention with 2-second cooldown
- Android and iOS support
