import 'package:flutter/foundation.dart';

/// Controller for programmatically pausing and resuming barcode scanning.
///
/// The camera preview remains active while scanning is paused —
/// only the ML Kit image processing is stopped.
///
/// Usage:
/// ```dart
/// final controller = QrScanController();
/// QrScan(useBarcode: ..., controller: controller);
/// // Later:
/// controller.pause();
/// controller.resume();
/// controller.toggle();
/// ```
class QrScanController extends ChangeNotifier {
  bool _isScanning = true;

  /// Whether barcode scanning is currently active.
  bool get isScanning => _isScanning;

  /// Pauses barcode scanning. Camera preview stays active.
  void pause() {
    if (_isScanning) {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Resumes barcode scanning.
  void resume() {
    if (!_isScanning) {
      _isScanning = true;
      notifyListeners();
    }
  }

  /// Toggles between scanning and paused states.
  void toggle() {
    _isScanning = !_isScanning;
    notifyListeners();
  }
}
