# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-01-29

### BREAKING CHANGES
- **Default language changed from Turkish to English** for multi-barcode dialog
- Added `multiBarcodeTitle` and `multiBarcodeMessage` parameters to customize dialog text
- Turkish users must now explicitly pass Turkish strings via parameters

### Fixed
- Added proper error handling with try/catch/finally to prevent scanner freeze on errors
- Fixed force-unwrap crash on `planeData` with null-safe access and descriptive error
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
- `selectedCameraAspectRatio` parameter for 16:9 or 4:3 camera preview (2024-03-19)
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

[0.1.0]: https://github.com/sezinsoft/qr_scan/compare/v0.0.7...v0.1.0
[0.0.7]: https://github.com/sezinsoft/qr_scan/compare/v0.0.6...v0.0.7
[0.0.6]: https://github.com/sezinsoft/qr_scan/compare/v0.0.5...v0.0.6
[0.0.5]: https://github.com/sezinsoft/qr_scan/compare/v0.0.4...v0.0.5
[0.0.4]: https://github.com/sezinsoft/qr_scan/compare/v0.0.3...v0.0.4
[0.0.3]: https://github.com/sezinsoft/qr_scan/compare/v0.0.1...v0.0.3
[0.0.1]: https://github.com/sezinsoft/qr_scan/releases/tag/v0.0.1
