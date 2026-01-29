import 'dart:isolate';
import 'dart:ui';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// Clean data object passed to the user callback.
/// Wraps ML Kit's Barcode with only the fields consumers need.
class ScannedBarcode {
  final String? rawValue;
  final String? displayValue;
  final BarcodeFormat format;
  final BarcodeType type;

  const ScannedBarcode({
    this.rawValue,
    this.displayValue,
    required this.format,
    required this.type,
  });

  /// Factory to convert raw ML Kit Barcode to our clean wrapper.
  factory ScannedBarcode.fromMlKit(Barcode barcode) {
    return ScannedBarcode(
      rawValue: barcode.rawValue,
      displayValue: barcode.displayValue,
      format: barcode.format,
      type: barcode.type,
    );
  }
}

/// Internal configuration object passed to the isolate on spawn.
/// Prevents race conditions by ensuring formats are known at startup.
class IsolateInitConfig {
  final SendPort sendPort;
  final RootIsolateToken rootIsolateToken;
  final List<BarcodeFormat> formats;

  IsolateInitConfig({
    required this.sendPort,
    required this.rootIsolateToken,
    required this.formats,
  });
}
